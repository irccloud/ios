#!/bin/bash
VERSION=`cat $PROJECT_DIR/build-scripts/VERSION`
echo -n "#define VERSION_STRING " > $PROJECT_DIR/IRCCloud/InfoPlist.h
echo $VERSION >> $PROJECT_DIR/IRCCloud/InfoPlist.h

git rev-parse 2> /dev/null > /dev/null
IS_GIT=$?

if [ $CONFIGURATION == "AppStore" ] || [ $IS_GIT -ne 0 ]; then
    bN=$((`cat $PROJECT_DIR/build-scripts/BUILD`+1))
    echo -n $bN > $PROJECT_DIR/build-scripts/BUILD
else
    bN=$(/usr/bin/git rev-parse --short HEAD)
fi
echo -n "#define GIT_VERSION " >> $PROJECT_DIR/IRCCloud/InfoPlist.h
if [ $PLATFORM_NAME == "iphonesimulator" ]; then
    echo `cat $PROJECT_DIR/build-scripts/BUILD` >> $PROJECT_DIR/IRCCloud/InfoPlist.h
else
    echo $bN >> $PROJECT_DIR/IRCCloud/InfoPlist.h
fi

CRASHLYTICS_TOKEN=`grep CRASHLYTICS_TOKEN $PROJECT_DIR/IRCCloud/config.h | awk '{print $3}' | sed 's/"//g'`
if [ -n "$CRASHLYTICS_TOKEN" ]; then
    echo -n "#define FABRIC_API_KEY " >> $PROJECT_DIR/IRCCloud/InfoPlist.h
    echo $CRASHLYTICS_TOKEN >> $PROJECT_DIR/IRCCloud/InfoPlist.h
fi

if [ $SDK_VERSION == "13.0" ]; then
     echo "#define MANIFEST_KEY Application Scene Manifest" >> $PROJECT_DIR/IRCCloud/InfoPlist.h
     echo "#define SCENE_CONFIGURATIONS_KEY UISceneConfigurations" >> $PROJECT_DIR/IRCCloud/InfoPlist.h
     echo "#define MULTI_WINDOW_KEY UIApplicationSupportsMultipleScenes" >> $PROJECT_DIR/IRCCloud/InfoPlist.h
fi

touch $PROJECT_DIR/IRCCloud/IRCCloud-Info.plist
touch $PROJECT_DIR/IRCCloud/IRCCloud-Enterprise-Info.plist
touch $PROJECT_DIR/ShareExtension/Info.plist
touch $PROJECT_DIR/ShareExtension/Info-Enterprise.plist
touch $PROJECT_DIR/NotificationService/Info.plist
