#!/bin/bash
export IP_ADDR=`juju status  | grep "vault/0" | tr -s " " | cut -f 5 -d " "`
export VAULT_ADDR="http://${IP_ADDR}:8200"
export TOKEN=s.KRjvTVR2ut8OxOqjH3a37gXT
juju run vault/leader authorize-charm token=${TOKEN}
juju run vault/leader generate-root-ca
juju integrate mysql-innodb-cluster:certificates vault:certificates