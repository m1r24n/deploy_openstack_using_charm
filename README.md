# Deploying openstack using charm

Deploying Openstack using charm based on [this](https://docs.openstack.org/project-deploy-guide/charm-deployment-guide/latest/)
## add MAAS to juju
1. create mass-cloud.yaml

       cat << EOF | tee maas-cloud.yaml
       clouds:
       maas-one:
           type: maas
           auth-types: [oauth1]
           endpoint: http://192.168.110.2:5240/MAAS
       EOF

       juju add-cloud --client -f maas-cloud.yaml maas-one
       juju clouds --client

2. add MAAS credentials

       cat << EOF | tee maas-creds.yaml 
       credentials:
       maas-one:
         anyuser:
            auth-type: oauth1
            maas-oauth: cZfcm4qZru8Jc4hLnB:TMY3yew6B834ADuGmt:6PNDBU2CfQzav49rdptUvCSGkHFsvvRD
       EOF

       juju add-credential --client -f maas-creds.yaml maas-one

       juju credentials --client --show-secrets --format yaml

3. Bootstrap juju controller

       juju bootstrap --bootstrap-series=jammy --constraints tags=juju maas-one maas-controller
       
       juju controllers

4. Create openstack model

       juju add-model --config default-series=jammy openstack

       juju status

## Deploy openstack

1. switch controller
       
       juju switch maas-controller:openstack

2. deploy CEPH OSD

       cat << EOF | tee ceph-osd.yalm
       ceph-osd:
         osd-devices: /dev/vdb /dev/vdc
       EOF

       juju deploy -n 4 --channel reef/stable --config ceph-osd.yaml --constraints tags=compute ceph-osd

3. Deploy nova compute

       cat << EOF | tee nova-compute.yaml
       nova-compute:
       config-flags: default_ephemeral_format=ext4
       enable-live-migration: true
       enable-resize: true
       migration-auth-type: ssh
       virt-type: kvm
       EOF

       juju deploy -n 4 --to 0,1,2,3 --channel 2023.2/stable --config nova-compute.yaml nova-compute

4. Deploy MySQL InnoDB

       juju deploy -n 3 --to lxd:0,lxd:1,lxd:2 --channel 8.0/stable mysql-innodb-cluster

5. Deploy Vault

       juju deploy --to lxd:3 --channel 1.8/stable vault
       juju deploy --channel 8.0/stable mysql-router vault-mysql-router
       juju integrate vault-mysql-router:db-router mysql-innodb-cluster:db-router
       juju integrate vault-mysql-router:shared-db vault:shared-db

6. Initialize and unseal vault

       export VAULT_ADDR="http://192.168.110.9:8200"
       vault operator init -key-shares=5 -key-threshold=3

       vault operator unseal <key1>
       vault operator unseal <key2>
       vault operator unseal <key3>

       export VAULT_TOKEN=<initial_root_token>
       vault token create -ttl=10m
       juju run  vault/leader authorize-charm token=<token>
       juju run vault/leader generate-root-ca

       juju integrate mysql-innodb-cluster:certificates vault:certificates



7. Deploy neutron

       cat << EOF | tee neutron.yaml
       ovn-chassis:
         bridge-interface-mappings: br0:enp1s0
         ovn-bridge-mappings: physnet1:br0
       neutron-api:
         neutron-security-groups: true
         flat-network-providers: physnet1
       EOF

       juju deploy -n 3 --to lxd:0,lxd:1,lxd:2 --channel 23.09/stable ovn-central
       juju deploy --to lxd:1 --channel 2023.2/stable --config neutron.yaml neutron-api


       juju deploy --channel 2023.2/stable neutron-api-plugin-ovn
       juju deploy --channel 23.09/stable --config neutron.yaml ovn-chassis

       juju deploy --channel 2023.2/stable neutron-dynamic-routing

       juju integrate neutron-api-plugin-ovn:neutron-plugin neutron-api:neutron-plugin-api-subordinate
       juju integrate neutron-api-plugin-ovn:ovsdb-cms ovn-central:ovsdb-cms
       juju integrate ovn-chassis:ovsdb ovn-central:ovsdb
       juju integrate ovn-chassis:nova-compute nova-compute:neutron-plugin
       juju integrate neutron-api:certificates vault:certificates
       juju integrate neutron-api-plugin-ovn:certificates vault:certificates
       juju integrate ovn-central:certificates vault:certificates
       juju integrate ovn-chassis:certificates vault:certificates



       juju deploy --channel 8.0/stable mysql-router neutron-api-mysql-router
       juju integrate neutron-api-mysql-router:db-router mysql-innodb-cluster:db-router
       juju integrate neutron-api-mysql-router:shared-db neutron-api:shared-db

8. Deploying keystone

       juju deploy --to lxd:0 --channel 2023.2/stable keystone

       juju deploy --channel 8.0/stable mysql-router keystone-mysql-router
       juju integrate keystone-mysql-router:db-router mysql-innodb-cluster:db-router
       juju integrate keystone-mysql-router:shared-db keystone:shared-db

       juju integrate keystone:identity-service neutron-api:identity-service
       juju integrate keystone:certificates vault:certificates

9. deploy rabbitmq

       juju deploy --to lxd:2 --channel 3.9/stable rabbitmq-server
       juju integrate rabbitmq-server:amqp neutron-api:amqp
       juju integrate rabbitmq-server:amqp nova-compute:amqp

10. deploy nova cloud controller

        cat << EOF | tee ncc.yaml 
        nova-cloud-controller:
          network-manager: Neutron
        EOF

        juju deploy --to lxd:3 --channel 2023.2/stable --config ncc.yaml nova-cloud-controller
        juju deploy --channel 8.0/stable mysql-router ncc-mysql-router
        juju integrate ncc-mysql-router:db-router mysql-innodb-cluster:db-router
        juju integrate ncc-mysql-router:shared-db nova-cloud-controller:shared-db

        juju integrate nova-cloud-controller:identity-service keystone:identity-service
        juju integrate nova-cloud-controller:amqp rabbitmq-server:amqp
        juju integrate nova-cloud-controller:neutron-api neutron-api:neutron-api
        juju integrate nova-cloud-controller:cloud-compute nova-compute:cloud-compute
        juju integrate nova-cloud-controller:certificates vault:certificates

11. Deploy placement

        juju deploy --to lxd:3 --channel 2023.2/stable placement
        juju deploy --channel 8.0/stable mysql-router placement-mysql-router
        juju integrate placement-mysql-router:db-router mysql-innodb-cluster:db-router
        juju integrate placement-mysql-router:shared-db placement:shared-db
        juju integrate placement:identity-service keystone:identity-service
        juju integrate placement:placement nova-cloud-controller:placement
        juju integrate placement:certificates vault:certificates
                     
12. Deploy openstack dashboard

        juju deploy --to lxd:2 --channel 2023.2/stable openstack-dashboard
        juju deploy --channel 8.0/stable mysql-router dashboard-mysql-router
        juju integrate dashboard-mysql-router:db-router mysql-innodb-cluster:db-router
        juju integrate dashboard-mysql-router:shared-db openstack-dashboard:shared-db
        juju integrate openstack-dashboard:identity-service keystone:identity-service
        juju integrate openstack-dashboard:certificates vault:certificates
        


13. Deploy glance

        juju deploy --to lxd:3 --channel 2023.2/stable glance
        juju deploy --channel 8.0/stable mysql-router glance-mysql-router
        juju integrate glance-mysql-router:db-router mysql-innodb-cluster:db-router
        juju integrate glance-mysql-router:shared-db glance:shared-db
        juju integrate glance:image-service nova-cloud-controller:image-service
        juju integrate glance:image-service nova-compute:image-service
        juju integrate glance:identity-service keystone:identity-service
        juju integrate glance:certificates vault:certificates

14. deploy ceph monitor

        cat << EOF | tee ceph-mon.yaml
        ceph-mon:
          expected-osd-count: 4
          monitor-count: 3
        EOF

        juju deploy -n 3 --to lxd:0,lxd:1,lxd:2 --channel reef/stable --config ceph-mon.yaml ceph-mon
        juju integrate ceph-mon:osd ceph-osd:mon
        juju integrate ceph-mon:client nova-compute:ceph
        juju integrate ceph-mon:client glance:ceph

15. deploy cinder monitor

        cat << EOF | tee cinder.yaml
        cinder:
          block-device: None
          glance-api-version: 2
        EOF

        juju deploy --to lxd:1 --channel 2023.2/stable --config cinder.yaml cinder
        juju deploy --channel 8.0/stable mysql-router cinder-mysql-router
        juju integrate cinder-mysql-router:db-router mysql-innodb-cluster:db-router
        juju integrate cinder-mysql-router:shared-db cinder:shared-db
        juju integrate cinder:cinder-volume-service nova-cloud-controller:cinder-volume-service
        juju integrate cinder:identity-service keystone:identity-service
        juju integrate cinder:amqp rabbitmq-server:amqp
        juju integrate cinder:image-service glance:image-service
        juju integrate cinder:certificates vault:certificates
        juju deploy --channel 2023.2/stable cinder-ceph 
        juju integrate cinder-ceph:storage-backend cinder:storage-backend
        juju integrate cinder-ceph:ceph ceph-mon:client
        juju integrate cinder-ceph:ceph-access nova-compute:ceph-access  

16. deploy RADOS gateway

        juju deploy --to lxd:0 --channel reef/stable ceph-radosgw
        
        juju integrate ceph-radosgw:mon ceph-mon:radosgw


17. recover from reboot

        juju run mysql-innodb-cluster/1 reboot-cluster-from-complete-outage

18. enable VNC access to vm
        
        juju config nova-cloud-controller console-access-protocol=novnc
        
19. enable port security 

        juju config neutron-api enable-ml2-port-security=True