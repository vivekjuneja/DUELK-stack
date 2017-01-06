#/bin/bash


## Algorithm 
# 1. Get the logs from source - log dump (local file) or a remote location (via SSH)
# 2. Process the source logs based on two filters - this may be some kind of log classifiers like TRACEID or any keyword
# 3. Get the logs from Elasticsearch - order the logs based on the required field in ascending order.
# 4. Process the logs from Elasticsearch based on the same two filters as in step 2 
# 5. Compare the Processed logs from Step 2 and Step 4, and see if they are identical or not

SORT_FIELD_ASC="asc"
SORT_FIELD_DESC="desc"
MAX_LOGS="10000"
LOG_INDEX_PREF="logstash"
RAW_LOG_SOURCE="remote"
RAW_LOG_USER=""
RAW_LOG_HOST=""
LOG_FILTER=""
ELKTAIL_PATH=""
ELASTICSEARCH_PROTO="http"
ELASTICSEARCH_HOST=""
ELASTICSEARCH_PORT=""
SORT_FIELD=""
SORT_FIELD_ASC=""
LOG_FIELD=""
MAX_LOGS="10000"
LOG_INDEX_PREF="logstash"
LOG_INDEX_DATE=""
LOG_FILTER_1=""
LOG_FILTER_2=""
RAW_LOG_PATH=""
PERSIST_LOGS=""
PERSIST_LOGS_PERSIST="persist"


if [ "x$RAW_LOG_SOURCE" == "xremote" ];then
	echo "checking for raw logs on the remote server"
	
	# Get raw logs from remote server and filter the log filter and given pattern for processing
	ssh $RAW_LOG_USER@$RAW_LOG_HOST cat $RAW_LOG_PATH | grep "$LOG_FILTER_1" |  grep "$LOG_FILTER_2" > ${LOG_FILTER_1}_source_processed.log
else
	echo "checking for raw logs on the local file system path"

	# Filter the log filter and given pattern for processing
	cat $RAW_LOG_PATH | grep "$LOG_FILTER_1" | grep "$LOG_FILTER_2" > ${LOG_FILTER_1}_source_processed.log
fi

# Get logs from the Elasticsearch 
$ELKTAIL_PATH --url "$ELASTICSEARCH_PROTO://$ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT" \
-o "$SORT_FIELD" -r "$SORT_FIELD_ASC" -f "%$LOG_FIELD" -l -n "$MAX_LOGS" \
-i "$LOG_INDEX_PREF-$LOG_INDEX_DATE" "$LOG_FILTER_1" AND "$LOG_FILTER_2"  > ${LOG_FILTER_1}_elk.log

# Process the raw log, by filtering the LOG_FILTER, same as the Raw logs
cat ${LOG_FILTER_1}_elk.log | grep "$LOG_FILTER_2" > ${LOG_FILTER_1}_elk_processed.log

# Find difference between the Processed log from Elasticsearch and processed Raw log. 
# Look for if the log files are identical
diff ${LOG_FILTER_1}_elk_processed.log ${LOG_FILTER_1}_source_processed.log -w -s | grep "identical" > /dev/null

# Check the return code for the last diff command
out=$?

# If the logs are identical, then check if the logs need to be persisted 
# Logs are persisted by default if there is a mismatch
if [ $out -eq 0 ];then
        echo "logs are identical - ELK and Source Logs match"
        if [ "x$PERSIST_LOGS" != "x$PERSIST_LOGS_PERSIST" ]; then
                rm -rf *.log
        fi
else
        echo "logs are NOT identical - Please check the log files for detailed analysis"
fi
