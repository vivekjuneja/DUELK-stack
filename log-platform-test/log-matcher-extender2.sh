#/bin/bash


# $1 ---> logstash index date part
# $LOG_FILTER_1 ---> traceid
# $RAW_LOG_PATH ---> raw log file path
# $4 ---> persist logs if asked to "persist"

## Defaults assigned here
DATA_DIRECTORY="./data"
SORT_FIELD_ASC="asc"
SORT_FIELD_DESC="desc"
MAX_LOGS="10000"
LOG_INDEX_PREF="logstash"
RAW_LOG_SOURCE="remote"
RAW_LOG_USER="vivek"
RAW_LOG_HOST="10.52.221.122"
ELKTAIL_PATH="$(pwd)/elktail"
ELASTICSEARCH_PROTO="http"
ELASTICSEARCH_HOST="10.52.220.189"
ELASTICSEARCH_PORT="9200"
SORT_FIELD="offset"
LOG_FIELD="data"
MAX_LOGS="10000"
LOG_INDEX_PREF="logstash"
LOG_INDEX_DATE="$1"
LOG_FILTER_1="$2" # eg:- The traceid 
LOG_FILTER_2="$5" # eg: _ordCreLog, _ordShtLog, console etc. - signifies the log type
RAW_LOG_PATH="$3"
PERSIST_LOGS="$4"
PERSIST_LOGS_PERSIST="persist"

mkdir $DATA_DIRECTORY/$LOG_FILTER_1 #This directory will hold the intermediate and processed log files for each run

if [ "x$RAW_LOG_SOURCE" == "xremote" ];then
	echo "checking for raw logs on the remote server"
	
	# Get raw logs from remote server and filter the log filter and given pattern for processing
	# ssh $RAW_LOG_USER@$RAW_LOG_HOST cat $RAW_LOG_PATH | grep "$LOG_FILTER_1" |  grep "$LOG_FILTER_2" > ${LOG_FILTER_1}_source_processed.log
	#ssh $RAW_LOG_USER@$RAW_LOG_HOST cat /var/lib/mesos/slaves/40a92cc8-7dab-4a94-b092-f0ca85ae9579-S0/frameworks/703fd5ae-3915-48b9-a66b-9e54ccede103-0000/executors/$RAW_LOG_PATH/runs/latest/stdout | grep "$LOG_FILTER_1" |  grep "$LOG_FILTER_2" > ${LOG_FILTER_1}_source_processed.log
	ssh $RAW_LOG_USER@$RAW_LOG_HOST cat /var/lib/mesos/slaves/40a92cc8-7dab-4a94-b092-f0ca85ae9579-S0/frameworks/703fd5ae-3915-48b9-a66b-9e54ccede103-0000/executors/$RAW_LOG_PATH/runs/latest/stdout > $DATA_DIRECTORY/$LOG_FILTER_1/raw_log && python3 log_processor2.py $DATA_DIRECTORY/$LOG_FILTER_1/raw_log "$LOG_FILTER_1" > $DATA_DIRECTORY/$LOG_FILTER_1/raw_log_2 && python3 log_processor2.py $DATA_DIRECTORY/$LOG_FILTER_1/raw_log_2 "$LOG_FILTER_2" > $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_source_processed.log
else
	echo "checking for raw logs on the local file system path"

	# Filter the log filter and given pattern for processing
	#cat $RAW_LOG_PATH | grep "$LOG_FILTER_1" | grep "$LOG_FILTER_2" > ${LOG_FILTER_1}_source_processed.log
 	python3 log_processor2.py $DATA_DIRECTORY/$LOG_FILTER_1/$RAW_LOG_PATH "$LOG_FILTER_1" > $DATA_DIRECTORY/$LOG_FILTER_1/raw_log_2 && python3 log_processor2.py $DATA_DIRECTORY/$LOG_FILTER_1/raw_log_2 "$LOG_FILTER_2" > $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_source_processed.log
fi

# Get logs from the Elasticsearch 
echo \
"
$ELKTAIL_PATH --url "$ELASTICSEARCH_PROTO://$ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT" \
-o "$SORT_FIELD" -r "$SORT_FIELD_ASC" -f "%$LOG_FIELD" -l -n "$MAX_LOGS" \
-i "$LOG_INDEX_PREF-$LOG_INDEX_DATE" "$LOG_FILTER_1" AND "$LOG_FILTER_2"  > $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_elk.log
"

$ELKTAIL_PATH --url "$ELASTICSEARCH_PROTO://$ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT" \
-o "$SORT_FIELD" -r "$SORT_FIELD_ASC" -f "%$LOG_FIELD" -l -n "$MAX_LOGS" \
-i "$LOG_INDEX_PREF-$LOG_INDEX_DATE" "$LOG_FILTER_1" AND "$LOG_FILTER_2"  > $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_elk.log

# Process the raw log, by filtering the LOG_FILTER, same as the Raw logs
python3 log_processor2.py $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_elk.log "$LOG_FILTER_1" > $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_elk_processed.log

#grep "$LOG_FILTER_1" $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_elk.log > $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_elk_processed.log

# Find difference between the Processed log from Elasticsearch and processed Raw log. 
# Look for if the log files are identical

#diff $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_elk_processed.log $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_source_processed.log > $DATA_DIRECTORY/$LOG_FILTER_1/diff.log

#diff $DATA_DIRECTORY/$LOG_FILTER_1/diff.log reference -w -s | grep "identical" 


diff $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_elk_processed.log $DATA_DIRECTORY/$LOG_FILTER_1/${LOG_FILTER_1}_${LOG_FILTER_2}_source_processed.log -w -s | grep "identical" #> /dev/null

# Check the return code for the last diff command
out=$?

# If the logs are identical, then check if the logs need to be persisted 
# Logs are persisted by default if there is a mismatch
if [ $out -eq 0 ];then
        echo "logs are identical - ELK and Source Logs match"
        if [ "x$PERSIST_LOGS" != "x$PERSIST_LOGS_PERSIST" ]; then
                rm -rf $DATA_DIRECTORY/$LOG_FILTER_1/*.log
        fi
else
        echo "logs are NOT identical - Please check the log files for detailed analysis"
fi

