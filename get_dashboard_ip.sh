#!/bin/bash
export IPADDR=`juju status | grep openstack-dashboard/0 | tr -s " " | cut -f 5 -d " "`
echo "openstack dashboard can be access here https://${IPADDR}/horizon"
