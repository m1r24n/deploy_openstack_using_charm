#!/bin/bash
openstack domain create domain1
openstack project create --domain domain1 project1
openstack role add --user admin --project project1 member
openstack role add --user admin --project project1 Admin
openstack user create --domain domain1 --project project1 --password-prompt user1
