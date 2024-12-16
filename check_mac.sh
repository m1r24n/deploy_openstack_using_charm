#!/bin/bash
for i in fa:16:3e:c2:e7:0b fa:16:3e:c2:e7:0b fa:16:3e:c2:e7:0b
do
for j in node{1..4}
do
	echo $j
	ssh $j "sudo ovs-appctl fdb/show br0 | grep $i"
done
done
