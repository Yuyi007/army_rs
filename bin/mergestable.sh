#!/bin/sh
# This scripts will merge from master to stable submit them to repositories
#
# WARNING: THIS WILL RESET YOUR LOCAL REPOSITORY !!!!!!
#

GITDIRS="$KFS $KFC"
SRC=${1:master}
DST=${2:stable1}
COMMENT="mergestable.sh commit ($SRC -> $DST)"

set +e

if [ "$USER" != "jenkins" ]; then
  # needs human confirmation
  read -p "The scripts will reset your repositories, are you sure? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi
fi

######################################################################

for dir in $GITDIRS; do
  cd "$dir"

  echo "Synchronizing $dir..."
  git checkout -f $DST
  git fetch origin +$DST:refs/remotes/origin/$DST
  git clean -fd
  git reset --hard origin/$DST

  echo "Merging from $SRC to $DST..."
  git pull origin $SRC

  echo "Checking $dir changes..."
  if git status | grep 'Unmerged paths' >/dev/null 2>&1; then
    echo "There are unmerged paths in $dir, Aborting"
    git clean -fd
    git checkout .
    git reset --hard origin/$DST
  elif git status | grep 'Your branch is ahead of' >/dev/null 2>&1; then
    echo "Fast forward in $dir, pushing..."
    git pull origin $DST
    git push origin $DST
  elif git status | grep 'working directory clean' >/dev/null 2>&1; then
    echo "No Changes in $dir, Aborting"
    git clean -fd
    git checkout .
  else
    echo "Seems there are changes in $dir, commiting..."
    git status
    git add .
    git commit -am "$COMMENT"
    git pull origin $DST
    git push origin $DST

    CHECKRESULT2=$?
    if [ "$CHECKRESULT2" -ne 0 ]; then
      echo "Error 2: try again $dir..."
      git pull origin $DST
      git push origin $DST
    fi

    CHECKRESULT3=$?
    if [ "$CHECKRESULT3" -ne 0 ]; then
      echo "Error 3: try again $dir..."
      git pull origin $DST
      git push origin $DST
    fi
  fi
done

CHECKRESULT4=$?
if [ "$CHECKRESULT4" -ne 0 ]; then
  echo "Error 4: Aborting"
  exit 1
fi

echo "Done"

