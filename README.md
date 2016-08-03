# compiling nomad for ARM 

WIP detailed instructions on why this is the way it is

Following [GH-1430](https://github.com/hashicorp/nomad/issues/1430) I wanted to have an 
automatic and reproducible way to compile nomad for ARM.

Instead of using one of my own ARM device I decided to use [Scaleway](https://scaleway.com) C1
ARM processors, with terraform to orchestrate the build.

The basic setup is quite simple:

- install gcc, git, golang
- setup env for golang
- download nomad and follow the [development guide](https://github.com/hashicorp/nomad#developing-nomad) to run tests and build a binary
- upload the binary

Let's write a tiny terraform module that does just this using the Scaleway ARM provider!

We start simple with just one ARM server:

``` terraform
# main.tf
provider "scaleway" {}

resource "scaleway_server" "server" {
  name                = "dev"
  image               = "${var.image}"
  type                = "${var.type}"
  dynamic_ip_required = true
  tags                = ["go", "dev"]
}

variable "image" {
  default     = "eeb73cbf-78a9-4481-9e38-9aaadaf8e0c9"
  description = "Ubuntu 16.04 ARM; if you change the instance type be sure to adjust this."
}

variable "type" {
  default     = "C1"
  description = "Scaleway Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types "
}
```

Now we need to provision the server:

```
provisioner "remote-exec" {
  inline = [
    "curl -LO https://storage.googleapis.com/golang/go1.6.2.linux-armv6l.tar.gz",
    "tar -C /usr/local -xzf go1.6.2.linux-armv6l.tar.gz",
    "apt-get update",
    "apt-get -y install gcc git"
  ]
}
```

this will take care of installing golang and git/ gcc, so we can actually download 
go packages via `go get`.

Next wee need to configure our golang environment:

``` bash
# files/go.profile.sh
export GOPATH=/opt/go
export PATH=$PATH:/usr/local/go/bin:/opt/go/bin
```

We need to set the `$GOPATH` environment variable, and change the path.
For convenience we place the above file in `/etc/profile.d/go.sh`:

``` terraform
provisioner "file" {
  source = "./files/go.profile.sh"
  destination = "/etc/profile.d/go.sh"
}
```

Now to the real work: fetch nomad, running the tests and compiling the binary:

``` bash
# files/build.sh
#!/bin/bash -x

set -eu

go get github.com/hashicorp/nomad

pushd $GOPATH/src/github.com/hashicorp/nomad
make bootstrap

go get github.com/pmezard/go-difflib/difflib

make test

sed -i 's/\!linux\/arm //g' ./scripts/build.sh

make bin
popd
```
