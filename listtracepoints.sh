#! /bin/bash

WAYFINDER_SOURCE=~/wayfinder

for file in results/*/traces.dat; do
	python3 $WAYFINDER_SOURCE/scripts/uk_trace/trace.py list $file >> traceslist.txt
done
