#!/bin/sh
# This scripts will check config and out put errors
#
# WARNING: THIS WILL RESET YOUR LOCAL REPOSITORY !!!!!!
#

GITDIRS="$KFS"

set +e

if [ "$USER" != "jenkins" ]; then
  # needs human confirmation
  read -p "The scripts will reset your repositories, are you sure? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi
fi

echo "------- pulling kfs..."
for dir in $GITDIRS; do
  cd "$dir"
  git checkout -f master
  git fetch origin
  git clean -fd
  git reset --hard origin/master
  git checkout master
done

######################################################################
# Check config

echo "------- checking config..."
cd "$KFS"
rake game_config:check
CHECKRESULT=$?
if [ "$CHECKRESULT" -ne 0 ]; then
  exit 1
fi

######################################################################

echo "Done"
