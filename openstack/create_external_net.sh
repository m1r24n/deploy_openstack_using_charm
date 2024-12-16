#!/bin/bash
openstack network create --external --share --provider-network-type vlan --provider-segment 112 --provider-physical-network physnet1 ext_net112
openstack subnet create --network ext_net112 --no-dhcp --gateway 192.168.112.254 --subnet-range 192.168.112.0/24 --allocation-pool start=192.168.112.1,end=192.168.112.200 ext_subnet112
openstack subnet create --network ext_net112 --no-dhcp --gateway  fc00:dead:beef:a112::ffff --subnet-range  fc00:dead:beef:a112::/64 --allocation-pool start=fc00:dead:beef:a112::ffff:1,end=fc00:dead:beef:a112::ffff:ffff --ip-version 6 ext_subnet112_v6 
