# DUELK-stack
Provision a full Log platform stack : Kibana, HAProxy, Elasticsearch, Logstash and Logspout. Allows for Distributed Ordered logs using Log sequence filter.

This project demonstrates how to handle distributed logs from Docker containers in a Containerized environment. We use Docker GELF Logging driver to send logs to a UDP load balancer which is then sent to 2 instances of Logstash. The Logstash servers are packaged with a custom filter that generates a sequence number pattern, and is then added to each log as an extra `sequence` field. This is sent over to Elasticsearch. Kibana 4 is used as a Log dashboard. 

We wanted to solve specifically the problem of distributed log ordering. This means if there are multiple log entries in Elasticsearch for the same Milliseconds, then the Sort order is not maintained. This can cause significant issues for developers and operators to rely on logs in a distributed environment. 

Hence, we identified a solution, where in each Logstash server generates a sequence number. We use this Sequence number as an extra field in Log data in Kibana for Sorting. 

The Logstash servers expose GELF UDP Port and are balanced in a round robin way by the UDP load balancer. To demonstrate this in a solution, we use a simple Python based load balancer implementation. However, in a production environment, this could be replaced by any Hardware or Software specific implementation including L4 load balancers.

The Logstash Docker image is a custom image that uses a Logstash Sequence filter. This filter is a ruby gem that takes TWO inputs from the OS Environment variable. One is the sequence_seed and other is sequence iterator. To explain this, let us first understand the solution :-


*Solution #1 - Using Docker Graylog Driver*

File: `docker-compose.yml`

`docker run --log-opt tag="busybox-test" --log-opt labels=label1,label2 --log-opt env=env1,env2   --log-driver=gelf --log-opt gelf-address=udp://192.168.0.13:1111 -e TYPE=testing908 -v $(pwd)/sample-logs4.txt:/sample-logs4.txt:ro busybox cat /sample-logs4.txt`

![DUELK Stack solution with Docker Graylog Driver]
(https://raw.githubusercontent.com/vivekjuneja/DUELK-stack/master/DUELK-stack.jpg)


*Solution #2 - Using Logspout with Logstash Adapter*

File: `docker-compose-logspout.yml`

![DUELK Stack solution with Logspout Logstash Adapter]
(https://raw.githubusercontent.com/vivekjuneja/DUELK-stack/master/DUELK-stack-logspout.jpg)

*Solution #3 - Using Logstash with Filebeat and Syslog*

File: `docker-compose-syslog.yml`

`docker run -v $(pwd)/sample.log:/logs/test-log.1:ro --log-opt syslog-facility=daemon --log-driver syslog --log-opt tag="docker/{{ (.ExtraAttributes nil).ENV }}/{{ (.ExtraAttributes nil).PROJECT }}"  --log-opt env=ENV,PROJECT --log-opt labels=busy1 -e ENV=prod -e PROJECT=simple-project busybox cat /logs/test-log.1`


![DUELK Stack solution with Filebeat and Logstash]
(https://raw.githubusercontent.com/vivekjuneja/DUELK-stack/master/DUELK-stack-syslog.jpg)


*Solution #4 - Using Logstash with Filebeat, Syslog and Kafka*

File: `docker-compose-syslog-kafka.yml`

`docker run -v $(pwd)/sample.log:/logs/test-log.1:ro --log-opt syslog-facility=daemon --log-driver syslog --log-opt tag="docker/{{ (.ExtraAttributes nil).ENV }}/{{ (.ExtraAttributes nil).PROJECT }}"  --log-opt env=ENV,PROJECT --log-opt labels=busy1 -e ENV=prod -e PROJECT=simple-project busybox cat /logs/test-log.1`

![DUELK Stack solution with Kafka, Filebeat and Logstash]
(https://raw.githubusercontent.com/vivekjuneja/DUELK-stack/master/DUELK-stack-kafka-syslog.jpg)

