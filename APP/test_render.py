import yaml

# Load the manifest
with open("manifest.yaml", "r") as f:
    manifest = yaml.safe_load(f)

# Render nginx.conf.template
with open("templates/nginx.conf.template", "r") as f:
    nginx_template = f.read()

nginx_rendered = nginx_template.format(
    nginx_port=manifest["nginx"]["port"],
    service_port=manifest["services"]["port"],
    proxy_timeout=manifest["nginx"]["proxy_timeout"],
)

# Render docker-compose.yml.template
with open("templates/docker-compose.yml.template", "r") as f:
    compose_template = f.read()

compose_rendered = compose_template.format(
    service_image=manifest["services"]["image"],
    service_mode=manifest["services"]["mode"],
    service_version=manifest["services"]["version"],
    service_port=manifest["services"]["port"],
    nginx_image=manifest["nginx"]["image"],
    nginx_port=manifest["nginx"]["port"],
    network_name=manifest["network"]["name"],
    network_driver=manifest["network"]["driver_type"],
    otel_service_name=manifest["otel"]["service_name"],
    otel_exporter_endpoint=manifest["otel"]["exporter_endpoint"],
    otel_exporter_protocol=manifest["otel"]["protocol"],
)

print("=== NGINX RENDERED ===")
print(nginx_rendered[:800])
print("\n=== COMPOSE RENDERED ===")
print(compose_rendered)
