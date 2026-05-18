#!/usr/bin/env python3
import json
import os
import sys
import time
from datetime import datetime, timezone, timedelta

import requests
from prometheus_client import start_http_server
from prometheus_client.core import CounterMetricFamily, REGISTRY

STATE_FILE = "/data/state.json"
GITHUB_REPOSITORY = os.environ.get("GITHUB_REPOSITORY")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
MAX_PAGES = int(os.environ.get("GITHUB_PAGES", "10"))
PER_PAGE = int(os.environ.get("GITHUB_PER_PAGE", "100"))
CACHE_WINDOW_DAYS = int(os.environ.get("GITHUB_CACHE_WINDOW_DAYS", "90"))
PORT = int(os.environ.get("EXPORTER_PORT", "9117"))

BUCKETS = [30, 60, 120, 300, 600, 1200, 1800, 3600, 7200, 14400, 28800, 86400, float("inf")]


class GitHubActionsCollector:
    def __init__(self, repository, token=None, state_file=STATE_FILE):
        if not repository:
            raise ValueError("GITHUB_REPOSITORY environment variable must be set")
        self.repository = repository
        self.token = token
        self.state_file = state_file
        self.state = self._load_state()
        self._ensure_state()

    def _load_state(self):
        if not os.path.exists(self.state_file):
            return {}
        try:
            with open(self.state_file, "r", encoding="utf-8") as f:
                return json.load(f)
        except (ValueError, OSError):
            return {}

    def _ensure_state(self):
        self.state.setdefault("seen_runs", {})
        self.state.setdefault("conclusion_counts", {})
        self.state.setdefault("duration_sum", 0.0)
        self.state.setdefault("duration_count", 0)
        self.state.setdefault("duration_buckets", {str(b): 0 for b in BUCKETS[:-1]})
        self.state["duration_buckets"]["+Inf"] = self.state["duration_buckets"].get("+Inf", 0)

    def _save_state(self):
        try:
            os.makedirs(os.path.dirname(self.state_file), exist_ok=True)
            with open(self.state_file, "w", encoding="utf-8") as f:
                json.dump(self.state, f, indent=2)
        except OSError as exc:
            print(f"Failed to save state: {exc}", file=sys.stderr)

    def _api_headers(self):
        headers = {"Accept": "application/vnd.github+json"}
        if self.token:
            headers["Authorization"] = f"token {self.token}"
        return headers

    def _parse_time(self, ts):
        if not ts:
            return None
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))

    def _fetch_runs(self):
        runs = []
        cutoff = datetime.now(timezone.utc) - timedelta(days=CACHE_WINDOW_DAYS)
        base_url = f"https://api.github.com/repos/{self.repository}/actions/runs"
        for page in range(1, MAX_PAGES + 1):
            params = {"per_page": PER_PAGE, "page": page}
            response = requests.get(base_url, headers=self._api_headers(), params=params, timeout=30)
            if response.status_code != 200:
                # Don't crash the exporter on GitHub API errors; log and return what we have.
                print(f"GitHub API returned {response.status_code}: {response.text.strip()}")
                return runs
            payload = response.json()
            page_runs = payload.get("workflow_runs", [])
            if not page_runs:
                break
            runs.extend(page_runs)
            oldest = min((self._parse_time(r.get("created_at")) for r in page_runs if r.get("created_at")), default=None)
            if oldest is None or oldest < cutoff:
                break
        return runs

    def _duration_seconds(self, run):
        started = self._parse_time(run.get("run_started_at"))
        finished = self._parse_time(run.get("updated_at"))
        if not started or not finished or finished < started:
            return None
        return (finished - started).total_seconds()

    def _update_state(self):
        runs = self._fetch_runs()
        new_runs = 0
        for run in runs:
            run_id = str(run.get("id"))
            if not run_id or run_id in self.state["seen_runs"]:
                continue
            self.state["seen_runs"][run_id] = True
            conclusion = run.get("conclusion") or "unknown"
            self.state["conclusion_counts"][conclusion] = self.state["conclusion_counts"].get(conclusion, 0) + 1
            if conclusion == "success":
                duration = self._duration_seconds(run)
                if duration is not None:
                    self.state["duration_count"] += 1
                    self.state["duration_sum"] += duration
                    for bucket in BUCKETS:
                        label = "+Inf" if bucket == float("inf") else str(int(bucket))
                        if bucket == float("inf") or duration <= bucket:
                            self.state["duration_buckets"][label] = self.state["duration_buckets"].get(label, 0) + 1
            new_runs += 1

        if new_runs > 0:
            self._save_state()

    def collect(self):
        self._update_state()

        conclusion_total = CounterMetricFamily(
            "github_actions_workflow_run_conclusion_total",
            "Total GitHub Actions workflow runs by conclusion",
            labels=["conclusion"],
        )
        for conclusion, count in sorted(self.state["conclusion_counts"].items()):
            conclusion_total.add_metric([conclusion], float(count))
        yield conclusion_total

        duration_count = CounterMetricFamily(
            "github_actions_workflow_run_duration_seconds_count",
            "Total number of successful GitHub Actions workflow runs used for duration calculations",
            labels=["conclusion"],
        )
        duration_count.add_metric(["success"], float(self.state["duration_count"]))
        yield duration_count

        duration_sum = CounterMetricFamily(
            "github_actions_workflow_run_duration_seconds_sum",
            "Sum of successful GitHub Actions workflow run durations in seconds",
            labels=["conclusion"],
        )
        duration_sum.add_metric(["success"], float(self.state["duration_sum"]))
        yield duration_sum

        duration_bucket = CounterMetricFamily(
            "github_actions_workflow_run_duration_seconds_bucket",
            "GitHub Actions workflow run duration histogram buckets",
            labels=["conclusion", "le"],
        )
        for bucket in BUCKETS:
            label = "+Inf" if bucket == float("inf") else str(int(bucket))
            duration_bucket.add_metric(["success", label], float(self.state["duration_buckets"].get(label, 0)))
        yield duration_bucket


def main():
    collector = GitHubActionsCollector(GITHUB_REPOSITORY, token=GITHUB_TOKEN)
    REGISTRY.register(collector)

    print(f"Starting GitHub Actions exporter for {GITHUB_REPOSITORY} on port {PORT}")
    start_http_server(PORT)
    try:
        while True:
            time.sleep(60)
    except KeyboardInterrupt:
        print("Shutting down exporter")


if __name__ == "__main__":
    main()
