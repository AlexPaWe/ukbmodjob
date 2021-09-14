#! /bin/bash

mkdir experiment_results
cp results/tasks.json experiment_results/tasks.json
cp ukbmodjob/minjob.yaml experiment_results/job.yaml

echo "Parse result.txt files..."
./parse-results.sh
cp results.csv experiment_results/results.csv
rm results.csv # to prevent additions by subsequent invocations of this script

cd experiment_results
cp -r ../results/ .
