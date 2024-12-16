#!/bin/bash
export IP_ADDR=`juju status  | grep "vault/0" | tr -s " " | cut -f 5 -d " "`
export VAULT_ADDR="http://${IP_ADDR}:8200"
export INITIAL_TOKEN=s.lyJ0rdgeMX7HeZGvvHqBWi0a
export VAULT_TOKEN=${INITIAL_TOKEN}
vault token create -ttl=10m