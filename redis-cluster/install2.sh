#!/bin/sh
# setup a redis cluster

cd `dirname $0`
set -e

REDIS_SERVER=./redis-server
REDIS_CLI="./redis-cli -c"
REDIS_TRIB=./redis-trib.rb
REDIS_TAR_VER=3.0.0-beta5
REDIS_VERSION=2.9.54
REDIS_HOST=127.0.0.1
REDIS_PORTS="7000 7001 7002 7003 7004 7005"
REDIS_CONF=cluster.conf
NODES_CONF=nodes.conf
REPLICAS=1

# install redis cluster
if [ ! -f $REDIS_SERVER ] || ! $REDIS_SERVER -v | grep $REDIS_VERSION >/dev/null 2>&1; then
  rm -rf $REDIS_TAR_VER*
  wget https://github.com/antirez/redis/archive/$REDIS_TAR_VER.tar.gz
  tar zxf $REDIS_TAR_VER.tar.gz && rm -f $REDIS_TAR_VER.tar.gz
  cd redis-$REDIS_TAR_VER && make
  cp -f ./src/redis-trib.rb ../
  cp -f ./src/redis-cli ../
  cp -f ./src/redis-server ../
fi

# create cluster.conf file for each instances
for port in $REDIS_PORTS; do
  mkdir -p $port && cat > $port/$REDIS_CONF <<_EOF
port $port
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly no
daemonize yes
logfile "./redis.log"
dbfilename dump$port.rdb
save "900 1"
cluster-slave-validity-factor 0.0001
_EOF
done

# start redis if not started yet
for port in $REDIS_PORTS; do
  if [ ! -f $port/$NODES_CONF ]; then
    echo "starting redis $port"
    if pgrep $port; then
      $REDIS_CLI -p $port shutdown save
    fi
    cd $port
    .$REDIS_SERVER $REDIS_CONF
    cd ..
  else
    exit 0
  fi
done

# create cluster interactively
for port in $REDIS_PORTS; do
  if ! pgrep $port; then
    echo "redis $port has not started, exiting" && exit 0
  fi
  HOSTS="$HOSTS $REDIS_HOST:$port"
done
echo "creating redis cluster"
$REDIS_TRIB create --replicas $REPLICAS $HOSTS