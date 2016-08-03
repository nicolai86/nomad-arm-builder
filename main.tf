provider "scaleway" {}

resource "scaleway_server" "server" {
  name                = "dev"
  image               = "${var.image}"
  type                = "${var.type}"
  dynamic_ip_required = true
  tags                = ["go", "dev"]

  provisioner "file" {
    source = "./files/go.profile.sh"
    destination = "/etc/profile.d/go.sh"
  }

  provisioner "file" {
    source = "./files/install.sh"
    destination = "/tmp/install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install.sh",
      "/tmp/install.sh"
    ]
  }

  provisioner "file" {
    source = "./files/build.sh"
    destination = "/tmp/build.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/build.sh",
      "/tmp/build.sh"
    ]
  }

  provisioner "local-exec" {
    command = "scp root@${self.public_up}:/tmp/nomad_arm ."
  }
}

variable "image" {
  default     = "eeb73cbf-78a9-4481-9e38-9aaadaf8e0c9"
  description = "Ubuntu 16.04 ARM; if you change the instance type be sure to adjust this."
}

variable "type" {
  default     = "C1"
  description = "Scaleway Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types "
}
