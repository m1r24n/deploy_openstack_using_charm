#!/bin/bash
juju deploy -n 4 --channel reef/stable --config ceph-osd.yaml --constraints tags=compute ceph-osd
