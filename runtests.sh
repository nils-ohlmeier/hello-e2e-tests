#!/bin/bash

set -ex

if [ "$(uname)" == "Darwin" ]; then
  OS=MAC
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  OS=LINUX
else
  echo "Unsupported platform"
  exit -1
fi

if [ "${OS}" == "MAC" ]; then
  PLATFORM_SHORT=mac
  APP_INI_FILE=FirefoxNightly.app/Contents/Resources/application.ini
elif [ "${OS}" == "LINUX" ]; then
  PLATFORM_SHORT=linux-x86_64
  APP_INI_FILE=firefox/application.ini
fi

BUILDID=`sed -n -e '/^BuildID/ s/.*\= *//p' ${APP_INI_FILE}`
MAX_VERSION=`sed -n -e '/^MaxVersion/ s/.*\= *//p' ${APP_INI_FILE}`

DATED_DIRS=`sed -e "s|\(^....\)\(..\)\(..\)\(..\)\(..\)\(..\).*|\1/\2/\1-\2-\3-\4-\5-\6|" <<< ${BUILDID}`


export DISPLAY=:0
export LOOP_SERVER=$WORKSPACE/loop-server
export TEST_SERVER=local
export STANDALONE_SERVER=$WORKSPACE/loop-standalone
export MINIDUMP_STACKWALK=$WORKSPACE/minidump_stackwalk
export SYMBOLS_PATH=https://ftp.mozilla.org/pub/firefox/nightly/${DATED_DIRS}-mozilla-central/firefox-${MAX_VERSION}.en-US.${PLATFORM_SHORT}.crashreporter-symbols.zip

cd $WORKSPACE/loop-standalone
TEST_BROWSER=$WORKSPACE/firefox/firefox make functional
