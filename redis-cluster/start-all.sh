#!/bin/sh
#

cd `dirname $0`
set -e

REDIS_SERVER=../redis-server
REDIS_PORTS="7000 7001 7002 7003 7004 7005"

./install.sh
./stop-all.sh

for port in $REDIS_PORTS; do
	cd $port
	$REDIS_SERVER cluster.conf
	cd ..
done

ps aux | grep cluster
