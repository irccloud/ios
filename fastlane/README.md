fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios certs
```
fastlane ios certs
```
Check all certs and provisioning profiles from github
### ios push
```
fastlane ios push
```
Build and push to iTunes Connect
### ios vers
```
fastlane ios vers
```
Print version
### ios screenshots
```
fastlane ios screenshots
```
Take screenshots
### ios metadata
```
fastlane ios metadata
```
Upload metadata
### ios updateadhoc
```
fastlane ios updateadhoc
```
Make sure all devices are added to the ad-hoc profile
### ios beta
```
fastlane ios beta
```
Build and upload an ad-hoc release to Crashlytics

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
