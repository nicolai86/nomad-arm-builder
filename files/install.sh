#!/bin/bash

set -eu

# Install go
curl -LO https://storage.googleapis.com/golang/go1.6.2.linux-armv6l.tar.gz
tar -C /usr/local -xzf go1.6.2.linux-armv6l.tar.gz

# Install Prereq packages
apt-get update
apt-get -y install gcc apt-transport-https build-essential curl git-core mercurial bzr libpcre3-dev pkg-config zip default-jre qemu silversearcher-ag jq htop vim unzip

# Install consul
echo "Fetching Consul..."
CONSUL=0.6.4
cd /tmp
curl -L -o consul.zip https://releases.hashicorp.com/consul/${CONSUL}/consul_${CONSUL}_linux_arm.zip

echo "Installing Consul..."
unzip consul.zip >/dev/null
chmod +x consul
mv consul /usr/bin/consul
CONSUL_FLAGS="-server -bootstrap-expect=1 -data-dir=/opt/consul/data"
mkdir -p /opt/consul/data
sudo mkdir -p /etc/systemd/system/consul.d
cat <<EOF> /etc/systemd/system/consul.service
[Unit]
Description=consul agent
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
ExecStart=/usr/bin/consul agent $CONSUL_FLAGS -config-dir=/etc/systemd/system/consul.d
ExecReload=/bin/kill -HUP \$MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 0644 /etc/systemd/system/consul.service

# Install Docker
# http://blog.hypriot.com/downloads/
cd /tmp
curl -LO https://downloads.hypriot.com/docker-hypriot_1.10.3-1_armhf.deb
dpkg -i docker-hypriot_1.10.3-1_armhf.deb

sudo service docker restart
