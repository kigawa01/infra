terraform {
  required_version = ">= 1.0.0" # Ensure that the Terraform version is 1.0.0 or higher
}
module "shared" {
  source = "../"
}
locals {
  connection = {
    type        = "ssh"
    user        = var.user
    private_key = module.shared.ssh_key
    host        = var.host
  }
}
resource "null_resource" "knot_manifest" {
  connection = local.connection
  for_each   = ["knot-pod", "knot-svc", "knot-resolver-conf"]

  provisioner "file" {
    source      = "./manifests/${each.value}.yaml"
    destination = "/etc/kubernetes/manifests/¥${each.value}.yaml"
  }
}
resource "null_resource" "knot_zones" {
  connection = local.connection
  for_each   = ["kigawa.net", "onemc.world"]

  provisioner "file" {

    source      = "./conf/${each.value}.zone"
    destination = "/etc/knot/zones/${each.value}.zone"
  }
}

resource "null_resource" "knot_conf" {
  connection = local.connection

  provisioner "file" {

    source      = "./conf/knot.conf"
    destination = "/etc/knot/knot.conf"
  }
}
