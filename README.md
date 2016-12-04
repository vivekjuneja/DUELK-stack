# KHELL-stack
Provision a full Log platform stack : Kibana, HAProxy, Elasticsearch, Logstash and Logspout. Allows for Distributed Ordered logs using Log sequence filter.

1. `docker-compose up`

2. `docker run --log-opt tag="busybox-test" --log-opt labels=label1,label2 --log-opt env=env1,env2   --log-driver=gelf --log-opt gelf-address=udp://192.168.0.13:1111 -e TYPE=testing908 -v $(pwd)/sample-logs4.txt:/sample-logs4.txt:ro busybox cat /sample-logs4.txt`



