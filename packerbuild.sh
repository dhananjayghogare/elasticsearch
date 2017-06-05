#!/bin/bash

LATEST_UBUNTU_IMAGE=$(curl http://cloud-images.ubuntu.com/locator/ec2/releasesTable | grep eu-west-1 | grep trusty | grep amd64 | grep "\"hvm:ebs\"" | awk -F "[<>]" '{print $3}')

packer build \
  -var ami_id=$LATEST_UBUNTU_IMAGE \
  -var security_group_id=MYSGID\
  -var private_subnet_id=MYSUBNETID \
  -var packer_build_number=PACKERBUILDNUMBER \
  elasticsearch.json

