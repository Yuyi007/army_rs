#!/bin/sh
# check deploy success by checking pids
#

cd `dirname $0`/..

if [ "$#" -ne 1 ]; then
  echo "usage: $0 PID_DIR"
  exit 1
fi

PID_DIR=$1
HOST_NAME=`hostname`

# remove deprecated pids
remove_pids ()
{
  for PID_FILE in `find $PID_DIR -mmin +10 -name '*.pid'`; do
    PID=`cat $PID_FILE`
    # echo "checking old pid file $PID_FILE PID=$PID..."
    if ! ps aux | grep $PID | grep -v 'grep' >/dev/null 2>&1; then
      echo "$HOST_NAME: $PID_FILE old process $PID does not exists!"
      rm -f "$PID_FILE"
    fi
  done
}

# check if there is old pids
check_pids()
{
  ! find $PID_DIR -mmin +5 -name '*.pid' | grep pid | grep -v 'tmp/queries'
}

# wait for process to start
wait_pids ()
{
  C=0; until check_pids || [ $C -gt 30 ]; do C=$((C+1)); sleep 3; done
}

check_alive ()
{
  PID=`cat $1`
  ps aux | grep $PID | grep -v 'grep' >/dev/null 2>&1
}

check_process_alive ()
{
  for PID_FILE in `find $PID_DIR -name '*.pid'`; do
    # echo "checking new pid file $PID_FILE..."
    C=0;
    until check_alive $PID_FILE || [ $C -gt 120 ]; do
      echo "$HOST_NAME: $PID_FILE new process $PID does not exists! waiting... (C=$C)"
      C=$((C+1))
      sleep 3
    done
    if ! check_alive $PID_FILE; then
      echo "$HOST_NAME: $PID_FILE new process $PID does not exists!"
      return 1
    fi
    sleep 1
  done
  return 0
}

echo "$HOST_NAME: remove deprecated pids..."
remove_pids

echo "$HOST_NAME: waiting for new pids..."
wait_pids >/dev/null 2>&1

echo "$HOST_NAME: check new pids..."
if ! check_pids; then
  echo "$HOST_NAME: check_pids failed!"
  exit 2
fi

echo "$HOST_NAME: checking new processes are alive..."
if ! check_process_alive; then
  echo "$HOST_NAME: check_process_alive failed!"
  exit 3
fi
