#!/bin/bash

apt-get update
apt-get upgrade -y
apt-get install -y software-properties-common git
apt-add-repository -y ppa:ansible/ansible apt-get update

# workaround for ubuntu pip bug - https://bugs.launchpad.net/ubuntu/+source/python-pip/+bug/1306991
rm -rf /usr/local/lib/python2.7/dist-packages/requests
apt-get install -y python-dev

ssh-keyscan -H github.com > /etc/ssh/ssh_known_hosts

wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py
python get-pip.py

pip install ansible paramiko PyYAML jinja2 httplib2 netifaces boto awscli six
