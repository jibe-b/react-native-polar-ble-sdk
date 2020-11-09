# react-native-polar-ble-sdk

## Getting started

`$ npm install react-native-polar-ble-sdk --save`

### Mostly automatic installation

`$ react-native link react-native-polar-ble-sdk`

## Usage

```javascript
import PolarBleSdkModule from 'react-native-polar-ble-sdk';
// TODO: What to do with the module?
PolarBleSdkModule;
```

## ios issues

Polar's ble sdk relies on Carthage as a dependency manager, and you will need to
[install it](https://github.com/Carthage/Carthage#installing-carthage) as well
in order to build this module.
[This comment](https://github.com/polarofficial/polar-ble-sdk/issues/97#issuecomment-702174877)
helped me to recompile RxSwift using the provided `carthage.sh` script
(see `ios/resources` for a modified version), then I was able to build the
PolaBleSdk framework using `build_sdk.sh`.
After replacing the two new frameworks into `polar-sdk-ios` I was able to build
the example project for iOS 13 using XCode 12.

