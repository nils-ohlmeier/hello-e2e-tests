#!/bin/bash

set -ex

source $WORKSPACE/venv/bin/activate

export DISPLAY=:0
export LOOP_SERVER=$WORKSPACE/loop-server
#export LOOP_SERVER=/home/mozilla/loop-server
export STANDALONE_SERVER=$WORKSPACE/loop-standalone
#export STANDALONE_SERVER=/home/mozilla/loop-standalone

cd $WORKSPACE
python $WORKSPACE/marionette/marionette/runtests.py --type=browser --binary=$WORKSPACE/FirefoxNightly.app/Contents/MacOS/firefox --workspace=$WORKSPACE $WORKSPACE/loop-standalone/test/functional/
