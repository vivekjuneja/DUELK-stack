Use these scripts to test if log order is maintained from source till destination.

**source**: docker containers

**destination**: elasticsearch

We tested with the following steps :-

+ Run a bunch of containers
+ Using the DUELK stack, the logs can move to elasticsearch in multiple ways
+ Run the `log-matcher-extender2.sh` script or use the associated Dockerfile to build your own container
+ Example run of `log-matcher-extender2.sh` script :-
 + `log-matcher-extender2.sh 2017.02.02 85b4d7cd-c56b-44a5-b387-355dd153cb06 test_container_app.090bca98-e83f-11e6-82f8-02421de416f2 persist console`
 + The above command has the following input :-
	+ `2017.02.02` : is the logstash index data
	+ `85b4d7cd-c56b-44a5-b387-355dd153cb06` : some kind of unique id for the particular container. We use this as a TraceId
	+ `test_container_app.090bca98-e83f-11e6-82f8-02421de416f2` : this is the Marathon App Id
	+ `persist` : this is used to create log files that are used to debug the script's functioning
	+ `console` : this is some kind of log pattern that you would want to use to filter the logs from your container
+ Alternate way of using this via Container image :-
	+ Build the Dockerfile to create the image that you need, let's call it : log-platform-tester:1 
	+ Example run :-
		+ `docker run -v $(pwd)/data:/workspace/data -e RAW_LOG_USER=dummyuser -e RAW_LOG_HOST=172.17.0.1 -e ELASTICSEARCH_HOST=172.17.0.2 -e ELASTICSEARCH_PORT=9200 -e SSHPASS=dummypass -e LOGSTASH_INDEX_DATE=2017.02.02 -e LOG_TRACEID=85b4d7cd-c56b-44a5-b387-355dd153cb06 -e MARATHON_APP_ID=test_container_app.090bca98-e83f-11e6-82f8-02421de416f2 -e PERSIST_FLAG=persist -e LOG_PATTERN_FILTER=_ordCreLog  log-platform-tester:1`
