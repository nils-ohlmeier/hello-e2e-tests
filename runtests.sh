#!/bin/bash

set -ex

export DISPLAY=:0
export LOOP_SERVER=$WORKSPACE/loop-server
export STANDALONE_SERVER=$WORKSPACE/loop-standalone

cd $WORKSPACE/loop-standalone
TEST_BROWSER=$WORKSPACE/firefox/firefox make functional
