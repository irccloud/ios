#!/bin/sh
CRASHLYTICS_TOKEN=`grep CRASHLYTICS_TOKEN $PROJECT_DIR/IRCCloud/config.h | awk '{print $3}' | sed 's/"//g'`
CRASHLYTICS_SECRET=`grep CRASHLYTICS_SECRET $PROJECT_DIR/IRCCloud/config.h | awk '{print $3}' | sed 's/"//g'`
if [ -n "$CRASHLYTICS_TOKEN" ] && [[ $SDK_NAME != iphonesimulator* ]]; then ./Fabric.framework/run $CRASHLYTICS_TOKEN $CRASHLYTICS_SECRET; fi
