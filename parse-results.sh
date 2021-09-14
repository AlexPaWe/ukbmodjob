#!/usr/bin/env bash

RESULTSDIR=$1
if [[ -z $RESULTSDIR ]]; then
  RESULTSDIR=$(pwd)/results
fi

TASKSFILE=${TASKS:-$RESULTSDIR/tasks.json}

if [[ ! -f $TASKSFILE ]]; then
  echo "Missing tasks.json file!"
  exit 1
fi

if [[ ! -d $RESULTSDIR ]]; then
  echo "Missing results director!"
  exit 1
fi

unset keys
unset values
unset tasksjson
tasksjson=$(cat $TASKSFILE)
for TASKID in $(cat $TASKSFILE | jq -r "keys[]"); do
  if [[ -f $RESULTSDIR/$TASKID/results.txt ]]; then
    keys=$(cat $RESULTSDIR/$TASKID/results.txt | sed -e '6,10d' | wrkp | head -1)
    IFS="," read -a keysarr <<< $keys
    #echo "keysarr: ${keysarr[@]}"


    values=$(cat $RESULTSDIR/$TASKID/results.txt | sed -e '6,10d' | wrkp | sed -e '1,1d')
    IFS="," read -a valuesarr <<< $values
    #echo "valuesarr: ${valuesarr[@]}"

    for ((i=0; i<${#keysarr[@]}; i++));
    do
      #echo "${keysarr[i]}"
      tasksjson=$(echo "$tasksjson" | jq --arg k "${keysarr[i]}" --arg v "${valuesarr[i]}" --arg TID "$TASKID" '.[$TID] += {($k): $v}' )
    done
  fi
done

#echo "$tasksjson"

echo "$tasksjson" | jq -r 'to_entries[] | .key as $parent | .value += {"TASKID": $parent} | .value' | jq -s -r '.' | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' >> results.csv
