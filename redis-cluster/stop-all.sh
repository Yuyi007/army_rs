#!/bin/sh
#

cd `dirname $0`

REDIS_CLI="./redis-cli -c"
REDIS_PORTS="7000 7001 7002 7003 7004 7005"

#for pid in `pgrep cluster`; do
#	kill $pid
#done

for port in $REDIS_PORTS; do
  if pgrep -f ":$port \[cluster\]"; then
    $REDIS_CLI -p $port shutdown save
  fi
done

sleep 1

ps aux | grep cluster
