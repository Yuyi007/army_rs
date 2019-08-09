#!/bin/sh
# destroy the redis cluster

cd `dirname $0`
set -e

REDIS_PORTS="7000 7001 7002 7003 7004 7005"

read -p "The scripts will reset your redis cluster, are you sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 0
fi

for port in $REDIS_PORTS; do
  rm -f $port/nodes.conf $port/dump*.rdb $port/redis.log
done

echo "reset done"