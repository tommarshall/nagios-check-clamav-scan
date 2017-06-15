# !/usr/bin/env bash

BASE_DIR=$(dirname $BATS_TEST_DIRNAME)
TMP_DIRECTORY=$(mktemp -d)

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
