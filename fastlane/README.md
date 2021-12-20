fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios certs

```sh
[bundle exec] fastlane ios certs
```

Check all certs and provisioning profiles from github

### ios apn

```sh
[bundle exec] fastlane ios apn
```

Generate new push certs

### ios upload_symbols

```sh
[bundle exec] fastlane ios upload_symbols
```

Upload symbols to FirebaseCrashlytics

### ios push

```sh
[bundle exec] fastlane ios push
```

Build and push to iTunes Connect

### ios vers

```sh
[bundle exec] fastlane ios vers
```

Print version

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Take screenshots

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload metadata

### ios updateadhoc

```sh
[bundle exec] fastlane ios updateadhoc
```

Make sure all devices are added to the ad-hoc profile

----


## Mac

### mac push

```sh
[bundle exec] fastlane mac push
```

Build and push to iTunes Connect

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
