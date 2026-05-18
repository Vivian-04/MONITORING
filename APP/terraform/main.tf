# This null_resource is used to invoke the SSH-based deployment script.
# The remote monitoring host is bootstrapped using native systemd units.
# Docker is not required for the monitoring runtime.
resource "null_resource" "deploy_monitoring" {
  provisioner "local-exec" {
    command     = "bash ../deploy-monitoring-ssh.sh"
    working_dir = path.module
    interpreter = ["bash", "-c"]
  }

  triggers = {
    always_run = timestamp()
  }
}
