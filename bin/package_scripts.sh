#!/bin/sh

set -e
set -f
cd `dirname $0`/../client

package()
{
  ENTRY_FILE=$1
  SRC_FILE=$2
  OUT_FILE=$3

  COMPILE_LUA="../bin/luac32 -s -o $OUT_FILE $SRC_FILE"
  COMPILE_LUA_WIN="../bin/luac32.exe -s -o $OUT_FILE $SRC_FILE"
  COMPILE_LUAJIT="luajit -b $SRC_FILE $OUT_FILE"
  COMPILE_NONE="cp -f $SRC_FILE $OUT_FILE"

  if uname -a | grep 'Darwin' >/dev/null 2>&1; then
    echo "Packaging $OUT_FILE on Mac OS..."
    MAKE_SQUISHY="luajit make_squishy"
    SQUISH="luajit squish --with-minify --with-uglify"
    COMPILE="$COMPILE_NONE"
    if ! command -v luajit >/dev/null 2>&1; then
      echo "installing luajit..."
      brew install luajit
    fi
  else
    echo "Packaging $OUT_FILE on Windows..."
    MAKE_SQUISHY="lua.exe make_squishy"
    SQUISH="lua.exe ./squish"
    COMPILE="$COMPILE_NONE"
  fi

  $MAKE_SQUISHY -f $ENTRY_FILE

  echo "Backing up cl.lua..."
  set +e
  CUR_COMMIT=`git rev-parse --verify HEAD`
  git diff-index --quiet HEAD --
  if [ $? == 1 ]; then
    echo "You have uncommited changes, ${SRC_FILE} will be different from ${CUR_COMMIT}!"
    CUR_COMMIT=${CUR_COMMIT}_mod
  fi
  cp -f $SRC_FILE $SRC_FILE.`date +%Y%m%d-%H%M%S`.${CUR_COMMIT}
  set -e

  echo 'Squishing sources...'
  $SQUISH

  echo 'Compiling to luajit bytecode...'
  $COMPILE

  echo 'Gzipping...'
  gzip -n $OUT_FILE && mv $OUT_FILE.gz $OUT_FILE

  echo "Encrypting..."
  ruby <<<"
    require '../bin/encrypt'
    text = IO.read('$OUT_FILE')
    File.open('$OUT_FILE', 'wb+') { |f| f.write(encrypt text) }
  "

  set +f
  cp -f $OUT_FILE $RU/proj.ios/Data/Raw
  cp -f $OUT_FILE $RU/proj.android/proj_debug/race/src/main/assets/
  cp -f $OUT_FILE $RU/proj.android/proj_product/race/src/main/assets/
  mv $OUT_FILE $RU/Assets/StreamingAssets/$OUT_FILE
}

package entry.lua cl.lua cl.lc
