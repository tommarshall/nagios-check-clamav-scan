# !/usr/bin/env bash

BASE_DIR=$(dirname $BATS_TEST_DIRNAME)
TMP_DIRECTORY=$(mktemp -d)

# ensure GNU date
if ! date --version >/dev/null 2>&1 ; then
  if gdate --version >/dev/null 2>&1 ; then
    date () { gdate "$@"; }
  fi
fi

# ensure GNU stat
if ! stat --version >/dev/null 2>&1 ; then
  if gstat --version >/dev/null 2>&1 ; then
    stat () { gstat "$@"; }
  fi
fi

# ensure GNU stat
if ! touch --version >/dev/null 2>&1 ; then
  if gtouch --version >/dev/null 2>&1 ; then
    touch () { gtouch "$@"; }
  fi
fi

setup() {
  cd $TMP_DIRECTORY
}

teardown() {
  if [ $BATS_TEST_COMPLETED ]; then
    echo "Deleting $TMP_DIRECTORY"
    rm -rf $TMP_DIRECTORY
  else
    echo "** Did not delete $TMP_DIRECTORY, as test failed **"
  fi

  cd $BATS_TEST_DIRNAME
}
