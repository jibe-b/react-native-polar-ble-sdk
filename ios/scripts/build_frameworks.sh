#!/usr/bin/env bash

# procedure found here :
# https://github.com/polarofficial/polar-ble-sdk/issues/97#issuecomment-702174877

# go to current script directory
# (see https://stackoverflow.com/questions/3349105/how-to-set-current-working-directory-to-the-directory-of-the-script-in-bash)
cd $(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

# get custom carthage script (needs carthage installed)
source ./carthage.sh

# then go to PolarBleSdk source folder
cd ../../polar-ble-sdk/sources/iOS/ios-communications

# now call the modified carthage script to rebuild RxSwift
cart update RxSwift --no-use-binaries --platform iOS

# then build the PolarBleSdk framework
source ./build_sdk.sh

# for some reason the build_sdk.h script ends up cd'ing into 3rd_party_sdk
# so we come back where we were before
cd ..

# and finally copy the two new frameworks into the ios sdk folder,
# replacing the original ones :
cp -r ./Carthage/Build/iOS/RxSwift.framework ../../../polar-sdk-ios
cp -r ./3rd_party_sdk/PolarBleSdk.framework ../../../polar-sdk-ios
