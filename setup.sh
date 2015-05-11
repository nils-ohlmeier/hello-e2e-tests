#!/bin/bash

set -ex

BASE_URL_FIREFOX=http://pf-jenkins.qa.mtv2.mozilla.com:8080/view/firefox/job/firefox-nightly-linux64/ws/releases
BASE_URL_TESTS=http://pf-jenkins.qa.mtv2.mozilla.com:8080/view/tests/job/tests-nightly-linux64/ws/releases
BINARY_NAME=firefox-latest-nightly.en-US.linux-x86_64
FIREFOX_URL=${BASE_URL_FIREFOX}/${BINARY_NAME}.dmg
TESTS_URL=${BASE_URL_TESTS}/${BINARY_NAME}.tests.zip

KEY_FILE=/home/mozilla/e2e_test_files/dev.json

WGET=`which wget`
if [ ! -z ${WGET} ]; then
  ${WGET} --no-verbose ${FIREFOX_URL}
  ${WGET} --no-verbose ${TESTS_URL}
else
  curl ${FIREFOX_URL} > ${BINARY_NAME}.tar.bz2
  curl ${TESTS_URL} > ${BINARY_NAME}.tests.zip
fi

tar xvjf ${BINARY_NAME}.tar.bz2
unzip -u -o ${BINARY_NAME}.tests.zip 'marionette/*' 'mozbase/*'

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
