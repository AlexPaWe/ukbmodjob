#! /bin/bash

for file in results/*/results*.txt; do
	cat $file | sed -e '6,10d' | wrkp >> $file.csv
done

i=0
for folder in results/*; do
	echo "$folder"
	i=0
	for csvfile in "$folder"/*csv; do
		echo "$csvfile"
		if [[ $i -eq 0 ]]; then
			head -1 "$csvfile" > "$folder"/combined.csv
		fi
		tail -n +2 "$csvfile" >> "$folder"/combined.csv
		i=$(( $i + 1 ))
	done
done

#cd results
#for folder in *; do
#	echo $folder
#	if [[ $folder != "tasks.json" ]]; then
#		cd $folder
#		
#		for txtfile in results*.txt; do
#			echo $txtfile
#			#cat $txtfile
#			cat $txtfile | sed -e '6,10d' | wrkp >> $txtfile.csv
#			#cat $txtfile.csv
#		done
#		
#		#i=0
#		#for csvfile in *.csv; do
#		#	echo $csvfile
#		#	if [[ $i -eq 0 ]]; then
#		#		head -1 "$csvfile" > combined.csv
#		#	fi
#		#	tail -n +2 "$csvfile" >> combined.csv
#		#	i=$(( $i + 1 ))
#		#done
#		#cat combined.csv
#	fi
#done
