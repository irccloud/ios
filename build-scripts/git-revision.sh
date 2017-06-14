#!/bin/sh
VERSION=`cat $PROJECT_DIR/build-scripts/VERSION`
echo -n "#define VERSION_STRING " > $PROJECT_DIR/IRCCloud/InfoPlist.h
echo $VERSION >> $PROJECT_DIR/IRCCloud/InfoPlist.h

git rev-parse 2> /dev/null > /dev/null
IS_GIT=$?

if [ $CONFIGURATION == "AppStore" ] || [ $IS_GIT -ne 0 ]; then
    bN=$VERSION
else
    bN=$(/usr/bin/git rev-parse --short HEAD)
fi
echo -n "#define GIT_VERSION " >> $PROJECT_DIR/IRCCloud/InfoPlist.h
echo $bN >> $PROJECT_DIR/IRCCloud/InfoPlist.h

CRASHLYTICS_TOKEN=`grep CRASHLYTICS_TOKEN $PROJECT_DIR/IRCCloud/config.h | awk '{print $3}' | sed 's/"//g'`
if [ -n "$CRASHLYTICS_TOKEN" ]; then
    echo -n "#define FABRIC_API_KEY " >> $PROJECT_DIR/IRCCloud/InfoPlist.h
    echo $CRASHLYTICS_TOKEN >> $PROJECT_DIR/IRCCloud/InfoPlist.h
fi

touch $PROJECT_DIR/IRCCloud/IRCCloud-Info.plist
touch $PROJECT_DIR/IRCCloud/IRCCloud-Enterprise-Info.plist
touch $PROJECT_DIR/ShareExtension/Info.plist
touch $PROJECT_DIR/ShareExtension/Info-Enterprise.plist
