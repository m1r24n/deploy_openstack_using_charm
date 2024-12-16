#!/bin/bash
export IP_ADDR=`juju status  | grep "vault/0" | tr -s " " | cut -f 5 -d " "`
export VAULT_ADDR="http://${IP_ADDR}:8200"
export KEY1=Q2itZpX3iAay4L0jZ61UrRkNscTNjHW+wINZMtCyy41B
export KEY2=lKk0rscvbEOkuz3Uej367TIrj1oFKg0aVYLoNPzTNQbo
export KEY3=o5J9n9zkGRhndmSYghwiIgKyMkOwCMvI1IVNORvZxq8R
vault operator unseal ${KEY1}
vault operator unseal ${KEY2}
vault operator unseal ${KEY3}
