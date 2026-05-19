variable "monitoring_host" {
  description = "IP or hostname of the separate monitoring server to bootstrap over SSH."
  type        = string
}

variable "ssh_user" {
  description = "SSH user for the monitoring server."
  type        = string
  default     = "root"
}

variable "ssh_password" {
  description = "SSH password for the monitoring server user."
  type        = string
  sensitive   = true
}

variable "sudo_password" {
  description = "Sudo password for the monitoring server user. Leave empty to reuse ssh_password."
  type        = string
  sensitive   = true
  default     = ""
}

variable "app_host" {
  description = "IP or hostname of the application server to monitor from the monitoring server."
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for Alertmanager notifications."
  type        = string
  sensitive   = true
}

variable "github_repository" {
  description = "GitHub repository to collect Actions/DORA metrics from, in owner/repo format."
  type        = string
}

variable "github_token" {
  description = "GitHub token used by the GitHub Actions metrics exporter."
  type        = string
  sensitive   = true
}

variable "grafana_admin_user" {
  description = "Grafana admin username."
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password."
  type        = string
  default     = "admin"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key used to connect to the monitoring server."
  type        = string
  default     = ""
}
