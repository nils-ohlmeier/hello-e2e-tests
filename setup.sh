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
# modify the TokBox SDK on the standalone server to use Firefox fake A/V sources
cd content/shared/libs
patch -p0 < /home/mozilla/e2e_test_files/sdk.js.patch
#cp /home/mozilla/e2e_test_files/sdk.js .

# modify the TokBox SDK within Firefox to use Firefox fake A/V sources
#mkdir $WORKSPACE/temp
#cd $WORKSPACE/temp
# the omni.ja contains errors
#set +e
#unzip -q $WORKSPACE/firefox/browser/omni.ja
#set -e
#cd chrome/browser/content/browser/loop/libs/
#patch -p0 < /home/mozilla/e2e_test_files/sdk.js.patch
#cp /home/mozilla/e2e_test_files/sdk.js .
#cd $WORKSPACE/temp
#zip -qr9XD omni.ja *
#cp omni.ja $WORKSPACE/firefox/browser/
#rm -rf $WORKSPACE/temp

cd /home/mozilla/e2e_test_files/
if [ -e test_1_browser_call.py ]; then
  cp test_1_browser_call.py $WORKSPACE/marionette/tests/browser/components/loop/test/functional/
fi
if [ -e config.py ]; then
  cp config.py $WORKSPACE/marionette/tests/browser/components/loop/test/functional/
fi

source ~/venv/bin/activate

cd $WORKSPACE/marionette
python setup.py install

cd $WORKSPACE/marionette/transport
python setup.py install

cd $WORKSPACE
pip install --upgrade pyperclip

# Ugly workaround for marionette always creating new profiles in /tmp/
rm -r /tmp/*.mozrunner

