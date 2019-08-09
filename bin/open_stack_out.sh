#!/bin/sh

set +e

cd `dirname $0`/..

deps/eflame/stack_to_flame.sh < $1 > flame.svg && open flame.svg
