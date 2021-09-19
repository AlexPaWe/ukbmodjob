#!/usr/bin/env bash

RESULTSDIR=$1
if [[ -z $RESULTSDIR ]]; then
  RESULTSDIR=$(pwd)/results
fi

TASKSFILE=${TASKS:-$RESULTSDIR/tasks.json}

ITERATIONS=10

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
  for (( j=1; j <= ITERATIONS; j++)); do
    if [[ -f $RESULTSDIR/$TASKID/results$j.txt ]]; then
      keys="$(cat $RESULTSDIR/$TASKID/results$j.txt | sed -e '6,10d' | wrkp | head -1),Iteration"
      IFS="," read -a keysarr <<< $keys
      #echo "keysarr: ${keysarr[@]}"


      values="$(cat $RESULTSDIR/$TASKID/results$j.txt | sed -e '6,10d' | wrkp | sed -e '1,1d'),$j"
      IFS="," read -a valuesarr <<< $values
      #echo "valuesarr: ${valuesarr[@]}"

      for ((i=0; i<${#keysarr[@]}; i++));
      do
        #echo "${keysarr[i]}"
        tasksjson=$(echo "$tasksjson" | jq --arg k "${keysarr[i]}" --arg v "${valuesarr[i]}" --arg TID "$TASKID" '.[$TID] += {($k): $v}' )
      done
      
      NEW_TASKID="$TASKID-$j"
      tasksjson=$(echo "$tasksjson" | jq --arg NEW_TID "$NEW_TASKID" --arg j "$j" '. += {($NEW_TID): $j}' | jq --arg NEW_TID "$NEW_TASKID" --arg TID "$TASKID" '.[$NEW_TID] = .[$TID]')
      echo "$tasksjson"
    fi
  done
  # Delete original json entry for TASKID without iteration number
  tasksjson=$(echo "$tasksjson" | jq --arg TID "$TASKID" 'del(.[$TID])')
done

#echo "$tasksjson"

echo "$tasksjson" | jq -r 'to_entries[] | .key as $parent | .value += {"TASKID": $parent} | .value' | jq -s -r '.' | jq -r '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' >> results.csv
