#!/bin/bash
for i in {1..1000000}
do
for j in 11 174 173
do
	ping -c 2 192.168.112.$j
done
done


