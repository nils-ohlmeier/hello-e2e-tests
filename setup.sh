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
BASE_URL_FIREFOX=http://pf-jenkins.qa.mtv2.mozilla.com:8080/view/firefox/job
BASE_URL_TESTS=http://pf-jenkins.qa.mtv2.mozilla.com:8080/view/tests/job
BINARY_NAME=firefox-latest-nightly.en-US
LINUX_POSTFIX=tar.bz2
MAC_POSTFIX=dmg
TESTS_POSTFIX=tests.zip
if [ "${OS}" == "MAC" ]; then
  BASE_URL_FIREFOX=${BASE_URL_FIREFOX}/firefox-nightly-mac
  BASE_URL_TESTS=${BASE_URL_TESTS}/tests-nightly-mac
  BINARY_NAME=${BINARY_NAME}.mac
  FIREFOX_ARCHIVE=${BINARY_NAME}.${MAC_POSTFIX}
elif [ "${OS}" == "LINUX" ]; then
  BASE_URL_FIREFOX=${BASE_URL_FIREFOX}/firefox-nightly-linux64
  BASE_URL_TESTS=${BASE_URL_TESTS}/tests-nightly-linux64
  BINARY_NAME=${BINARY_NAME}.linux-x86_64
  FIREFOX_ARCHIVE=${BINARY_NAME}.${LINUX_POSTFIX}
fi
BASE_URL_FIREFOX=${BASE_URL_FIREFOX}/ws/releases
BASE_URL_TESTS=${BASE_URL_TESTS}/ws/releases
TESTS_ARCHIVE=${BINARY_NAME}.${TESTS_POSTFIX}
FIREFOX_URL=${BASE_URL_FIREFOX}/${FIREFOX_ARCHIVE}
TESTS_URL=${BASE_URL_TESTS}/${TESTS_ARCHIVE}

KEY_FILE=/home/mozilla/e2e_test_files/dev.json

WGET=`which wget`
if [ ! -z ${WGET} ]; then
  ${WGET} --no-verbose ${FIREFOX_URL}
  ${WGET} --no-verbose ${TESTS_URL}
else
  curl ${FIREFOX_URL} > ${FIREFOX_ARCHIVE}
  curl ${TESTS_URL} > ${TESTS_ARCHIVE}
fi

if [ ${OS} == "MAC" ]; then
  hdiutil attach -quiet -mountpoint /Volumes/FF ${FIREFOX_ARCHIVE}
  cp -r /Volumes/FF/FirefoxNightly.app .
  umount /Volumes/FF
elif [ ${OS} == "LINUX" ]; then
  tar xvjf ${FIREFOX_ARCHIVE}
fi
unzip -u -o ${TESTS_ARCHIVE} 'marionette/*' 'mozbase/*'

cd $WORKSPACE/loop-server
npm install
# This is needed because of the TokBox keys
cp ${KEY_FILE} $WORKSPACE/loop-server/config/

cd $WORKSPACE/loop-standalone
npm install

cd $WORKSPACE
virtualenv venv
source $WORKSPACE/venv/bin/activate

# Install these first from the source so that we're using the in-tree version
# from the test files.
cd $WORKSPACE/mozbase
python setup_development.py

cd $WORKSPACE/marionette/transport
python setup.py install

cd $WORKSPACE/marionette/driver
python setup.py install

cd $WORKSPACE/marionette
python setup.py install

cd $WORKSPACE
pip install --upgrade pyperclip

# Ugly workaround for marionette always creating new profiles in /tmp/
rm -rf /tmp/*.mozrunner
# Ugly workaround for loop server filling up /tmp/
# https://bugzilla.mozilla.org/show_bug.cgi?id=1173538
rm -rf /tmp/*.heapsnapshot

cd /home/mozilla/e2e_test_files/
if [ -e test_1_browser_call.py ]; then
  cp -v test_1_browser_call.py $WORKSPACE/marionette/tests/browser/components/loop/test/functional/
fi
if [ -e config.py ]; then
  cp -v config.py $WORKSPACE/marionette/tests/browser/components/loop/test/functional/
fi
if [ -e marionette.py ]; then
  cp -v marionette.py $WORKSPACE/venv/lib/python2.7/site-packages/marionette_driver-0.2-py2.7.egg/marionette_driver/
fi
