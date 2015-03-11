#!/bin/bash

set -ex

FIREFOX_URL=http://pf-jenkins.qa.mtv2.mozilla.com:8080/view/firefox/job/firefox-nightly-linux64/ws/releases/firefox-latest-nightly.en-US.linux-x86_64.tar.bz2
TESTS_URL=http://pf-jenkins.qa.mtv2.mozilla.com:8080/view/tests/job/tests-nightly-linux64/ws/releases/firefox-latest-nightly.en-US.linux-x86_64.tests.zip

WGET=`which wget`
if [ ! -z ${WGET} ]; then
  ${WGET} --no-verbose ${FIREFOX_URL}
  ${WGET} --no-verbose ${TESTS_URL}
else
  curl ${FIREFOX_URL} > firefox-latest-nightly.en-US.linux-x86_64.tar.bz2
  curl ${TESTS_URL} > firefox-latest-nightly.en-US.linux-x86_64.tests.zip
fi

tar xvjf firefox-latest-nightly.en-US.linux-x86_64.tar.bz2
unzip -u -o firefox-latest-nightly.en-US.linux-x86_64.tests.zip 'marionette/*'

cd $WORKSPACE/loop-server
npm install
# This is needed because of the TokBox keys
cp /home/mozilla/e2e_test_files/dev.json $WORKSPACE/loop-server/config/

cd $WORKSPACE/loop-standalone
npm install

cd $WORKSPACE
virtualenv venv
source $WORKSPACE/venv/bin/activate

cd $WORKSPACE/marionette
python setup.py install

cd $WORKSPACE/marionette/transport
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
