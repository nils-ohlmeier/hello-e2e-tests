#!/bin/bash

set -ex

source ~/venv/bin/activate

export DISPLAY=:0
export LOOP_SERVER=$WORKSPACE/loop-server
#export LOOP_SERVER=/home/mozilla/loop-server
export STANDALONE_SERVER=$WORKSPACE/loop-standalone
#export STANDALONE_SERVER=/home/mozilla/loop-standalone

cd $WORKSPACE
python $WORKSPACE/marionette/marionette/runtests.py --type=browser --binary=$WORKSPACE/firefox/firefox $WORKSPACE/marionette/tests/browser/components/loop/test/functional/manifest.ini
