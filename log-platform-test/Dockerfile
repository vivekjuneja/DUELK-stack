FROM python:3

MAINTAINER vivek@gsshop.com

COPY . /workspace

RUN apt-get update && apt-get install -y sshpass && mkdir /workspace/data

WORKDIR /workspace


ENTRYPOINT ./log-matcher-extender2.sh ${LOGSTASH_INDEX_DATE} ${LOG_TRACEID} ${MARATHON_APP_ID} ${PERSIST_FLAG} ${LOG_PATTERN_FILTER}


