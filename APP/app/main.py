import logging
import os
import time
from datetime import datetime
from flask import Flask, jsonify, request

from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

try:
    from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
    OTLP_EXPORTER_TYPE = "http"
except ImportError:
    from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
    OTLP_EXPORTER_TYPE = "grpc"


app = Flask(__name__)

MODE = os.environ.get("MODE", "stable")
VERSION = os.environ.get("APP_VERSION", "1.0.0")
PORT = int(os.environ.get("APP_PORT", 3000))
START_TIME = time.time()


def configure_logging():
    log_dir = "/var/log/app"
    os.makedirs(log_dir, exist_ok=True)

    handler = logging.FileHandler(os.path.join(log_dir, "app.log"))
    handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
    handler.setLevel(logging.INFO)

    app.logger.setLevel(logging.INFO)
    app.logger.addHandler(handler)

    otlp_endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT")
    if otlp_endpoint:
        try:
            from opentelemetry.sdk._logs import BatchLogRecordProcessor, LoggerProvider, LoggingHandler, set_logger_provider
            from opentelemetry.exporter.otlp.proto.http._log_exporter import OTLPLogExporter as OTLPLogExporterHttp
            from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter as OTLPLogExporterGrpc
        except ImportError:
            app.logger.warning("OpenTelemetry logging exporter is unavailable. OTLP logs will not be forwarded.")
        else:
            protocol = os.environ.get("OTEL_EXPORTER_OTLP_PROTOCOL", "http/protobuf").lower()
            exporter_cls = OTLPLogExporterHttp if protocol.startswith("http") else OTLPLogExporterGrpc
            exporter = exporter_cls(endpoint=otlp_endpoint, insecure=True)
            resource = Resource.create({"service.name": os.environ.get("OTEL_SERVICE_NAME", "swiftdeploy-api"), "environment": MODE})
            logger_provider = LoggerProvider(resource=resource)
            logger_provider.add_log_record_processor(BatchLogRecordProcessor(exporter))
            set_logger_provider(logger_provider)
            app.logger.addHandler(LoggingHandler(level=logging.INFO, logger_provider=logger_provider))
            app.logger.info("OpenTelemetry log forwarding configured to %s using %s exporter.", otlp_endpoint, protocol)
    else:
        app.logger.info("OTLP log exporter not configured. App logs will be written locally only.")

    app.logger.info("Application logging initialized.")


def configure_tracing():
    endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT")
    if not endpoint:
        app.logger.info("OpenTelemetry exporter not configured. Tracing is disabled.")
        return

    service_name = os.environ.get("OTEL_SERVICE_NAME", "swiftdeploy-api")
    protocol = os.environ.get("OTEL_EXPORTER_OTLP_PROTOCOL", "http/protobuf").lower()

    if protocol.startswith("http"):
        from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter as HttpOTLPExporter
        exporter = HttpOTLPExporter(endpoint=endpoint, insecure=True)
    else:
        from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter as GrpcOTLPExporter
        exporter = GrpcOTLPExporter(endpoint=endpoint, insecure=True)

    resource = Resource.create({"service.name": service_name, "environment": MODE})
    provider = TracerProvider(resource=resource)
    provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)

    FlaskInstrumentor().instrument_app(app)
    app.logger.info("OpenTelemetry tracing configured to %s using %s exporter.", endpoint, protocol)


configure_logging()
configure_tracing()


@app.before_request
def log_request():
    app.logger.info("request=%s method=%s path=%s remote=%s", request.path, request.method, request.remote_addr)


@app.route("/")
def home():
    return jsonify({
        "message": "Welcome to SwiftDeploy",
        "mode": MODE,
        "version": VERSION,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    })


@app.route("/healthz")
def healthz():
    uptime = time.time() - START_TIME
    return jsonify({
        "status": "ok",
        "uptime": int(uptime)
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)

