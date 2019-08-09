#!/bin/sh
# This scripts will build config and submit them to repositories
#
# WARNING: THIS WILL RESET YOUR LOCAL REPOSITORY !!!!!!
GITDIRS="${DESIGN}/database $RS $RU"
COMMENT="buildconfig.sh commit"
BRANCH="master"
RAKE_TASK="jenkins_config"

if [[ $1 ]]; then
  BRANCH="$1"
fi

if [[ $2 ]]; then
  RAKE_TASK="$2"
fi

set +e

if [ "$USER" != "jenkins" ]; then
  # needs human confirmation
  read -p "The scripts will reset your repositories, are you sure? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi
fi


for dir in $GITDIRS; do
  git checkout -f $BRANCH
  git fetch origin +$BRANCH:refs/remotes/origin/$BRANCH
  git clean -fd
  git reset --hard origin/$BRANCH
done

######################################################################
# Build config

cd "$RS"
rake $RAKE_TASK
CHECKRESULT=$?
if [ "$CHECKRESULT" -ne 0 ]; then
  exit 1
fi

######################################################################


for dir in $GITDIRS; do
  cd "$dir"
  if ! git status | grep 'working directory clean' >/dev/null 2>&1; then
    echo "Seems there are changes in $dir, commiting..."
    git status
    git add .
    git commit -am "$COMMENT"
    git pull origin $BRANCH
    git push origin $BRANCH

    CHECKRESULT2=$?
    if [ "$CHECKRESULT2" -ne 0 ]; then
      git pull origin $BRANCH
      git push origin $BRANCH
    fi

    CHECKRESULT3=$?
    if [ "$CHECKRESULT3" -ne 0 ]; then
      git pull origin $BRANCH
      git push origin $BRANCH
    fi
  else
    git clean -fd
    git checkout .
  fi
done

CHECKRESULT4=$?
if [ "$CHECKRESULT4" -ne 0 ]; then
  exit 1
fi

echo "Done"

