#!/bin/bash
export IP_ADDR=`juju status  | grep "vault/0" | tr -s " " | cut -f 5 -d " "`
export VAULT_ADDR="http://${IP_ADDR}:8200"
vault operator init -key-shares=5 -key-threshold=3

