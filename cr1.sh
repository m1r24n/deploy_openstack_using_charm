openstack domain create domain1
openstack project create --domain domain1 project1
openstack role add --user admin --project project1 member
openstack role add --user admin --project project1 Admin
