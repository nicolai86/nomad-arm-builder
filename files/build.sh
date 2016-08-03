#!/bin/bash -x

set -eu

source /etc/profile.d/go.sh

go get github.com/hashicorp/nomad

pushd $GOPATH/src/github.com/hashicorp/nomad

git checkout v0.4.0

make bootstrap

go get github.com/pmezard/go-difflib/difflib

make test

# remove arm from disabled arch list
sed -i 's/\!linux\/arm //g' ./scripts/build.sh

export XC_OS=linux
export XC_ARCH=arm
make bin
popd
