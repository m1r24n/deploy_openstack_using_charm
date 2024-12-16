#!/bin/bash
openstack image create --public --disk-format qcow2 --container-format bare --file /home/irzan/Downloads/cirros-0.6.3-x86_64-disk.img cirros
openstack image create --public --disk-format qcow2 --container-format bare --file /home/irzan/Downloads/debian-12-generic-amd64.qcow2 debian
openstack image create --public --disk-format qcow2 --container-format bare --file /home/irzan/Downloads/jammy-server-cloudimg-amd64.img ubuntu22.04
openstack image create --public --disk-format qcow2 --container-format bare --file /home/irzan/Downloads/noble-server-cloudimg-amd64.img ubuntu24.04
