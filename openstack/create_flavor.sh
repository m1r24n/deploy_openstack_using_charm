#!/bin/bash
openstack flavor create --public --ram 2048 --disk 10 --vcpus 1 m1.small1
openstack flavor create --public --ram 512 --disk 10 --vcpus 1 m1.small0
openstack flavor create --public --ram 4096 --disk 40 --vcpus 2 m1.medium
openstack flavor create --public --ram 256 --disk 1 --vcpus 1 m1.tiny
