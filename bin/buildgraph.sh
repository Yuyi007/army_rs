#!/bin/sh
# This scripts will build config and submit them to repositories
#
# WARNING: THIS WILL RESET YOUR LOCAL REPOSITORY !!!!!!
#

SVNDIRS="$KOF_DESIGN"
GITDIRS="$KFS $KFC"
COMMENT="buildgraph.sh commit"

set +e

if [ "$USER" != "jenkins" ]; then
  # needs human confirmation
  read -p "The scripts will reset your repositories, are you sure? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi
fi

for dir in $SVNDIRS; do
  cd "$dir"
  #svn status --no-ignore | grep '^[I?]' | cut -c 9- | while IFS= read -r f; do rm -rf "$f"; done
  svn cleanup
  svn revert -R .
  svn up
  svn update
done

for dir in $GITDIRS; do
  cd "$dir"
  git checkout -f master
  git fetch origin
  git clean -fd
  git reset --hard origin/master
  git checkout master
done

######################################################################
# Build config

cd "$KFS"
rake scan
CHECKRESULT=$?
if [ "$CHECKRESULT" -ne 0 ]; then
  exit 1
fi

######################################################################

cd "$KFC"
git checkout -- *.prefab
git checkout -- *.mat
git checkout -- *.meta
git checkout -- *.anim
git clean -f -- *.meta

for dir in $GITDIRS; do
  cd "$dir"
  if ! git status | grep 'working directory clean' >/dev/null 2>&1; then
    echo "Seems there are changes in $dir, commiting..."
    git status
    git add .
    git commit -am "$COMMENT"
    git pull
    git push origin master
    CHECKRESULT2=$?
    if [ "$CHECKRESULT2" -ne 0 ]; then
      git pull origin master
      git push origin master
    fi
  else
    git clean -fd
    git checkout .
  fi
done

CHECKRESULT3=$?
if [ "$CHECKRESULT3" -ne 0 ]; then
  exit 1
fi


echo "Done"
