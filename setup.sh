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
HOME_LOCATION=${HOME_LOCATION:-/home/mozilla/e2e_test_files}
# This may be overriden below with OVERRIDE_BASE_URL_FIREFOX
BASE_URL_FIREFOX=http://pf-jenkins.qa.mtv2.mozilla.com:8080/view/firefox/job
RELEASE_URL_FIREFOX=${RELEASE_URL_FIREFOX:-http://pf-jenkins.qa.mtv2.mozilla.com:8080/view/firefox/job}
BINARY_NAME=${BINARY_NAME:-firefox-latest-nightly.en-US}
LINUX_POSTFIX=tar.bz2
MAC_POSTFIX=dmg
if [ "${OS}" == "MAC" ]; then
  BASE_URL_FIREFOX=${BASE_URL_FIREFOX}/firefox-nightly-mac
  BINARY_NAME=${BINARY_NAME}.mac
  FIREFOX_ARCHIVE=${BINARY_NAME}.${MAC_POSTFIX}
  STACKWALK_BINARY_URL=http://hg.mozilla.org/build/tools/raw-file/tip/breakpad/osx/minidump_stackwalk
elif [ "${OS}" == "LINUX" ]; then
  BASE_URL_FIREFOX=${BASE_URL_FIREFOX}/firefox-nightly-linux64
  BINARY_NAME=${BINARY_NAME}.linux-x86_64
  FIREFOX_ARCHIVE=${BINARY_NAME}.${LINUX_POSTFIX}
  STACKWALK_BINARY_URL=http://hg.mozilla.org/build/tools/raw-file/tip/breakpad/linux64/minidump_stackwalk
fi
STACKWALK_BINARY=minidump_stackwalk
BASE_URL_FIREFOX=${OVERRIDE_BASE_URL_FIREFOX:-${BASE_URL_FIREFOX}/ws/releases}
FIREFOX_URL=${BASE_URL_FIREFOX}/${FIREFOX_ARCHIVE}

KEY_FILE=${HOME_LOCATION}/dev.json

WGET=`which wget`
if [ ! -z ${WGET} ]; then
  ${WGET} --no-verbose ${FIREFOX_URL}
  ${WGET} --no-verbose ${STACKWALK_BINARY_URL}
else
  curl ${FIREFOX_URL} > ${FIREFOX_ARCHIVE}
  curl ${STACKWALK_BINARY_URL} > ${STACKWALK_BINARY}
fi

chmod 755 ${STACKWALK_BINARY}

if [ ${OS} == "MAC" ]; then
  hdiutil attach -quiet -mountpoint /Volumes/FF ${FIREFOX_ARCHIVE}
  cp -r /Volumes/FF/FirefoxNightly.app .
  umount /Volumes/FF
elif [ ${OS} == "LINUX" ]; then
  tar xvjf ${FIREFOX_ARCHIVE}
fi

cd $WORKSPACE/loop-server
npm install
# This is needed because of the TokBox keys
cp ${KEY_FILE} $WORKSPACE/loop-server/config/

cd $WORKSPACE/loop-standalone
npm install
make build

cd ${HOME_LOCATION}
if [ -e test_1_browser_call.py ]; then
  cp -v test_1_browser_call.py $WORKSPACE/loop-standalone/test/functional/
fi
if [ -e config.py ]; then
  cp -v config.py $WORKSPACE/loop-standalone/test/functional/
fi
