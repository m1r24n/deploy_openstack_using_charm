#!/bin/bash
juju deploy --to lxd:0 --channel reef/stable ceph-radosgw
juju integrate ceph-radosgw:mon ceph-mon:radosgw