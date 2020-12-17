# react-native-polar-ble-sdk

## Getting started

`$ npm install react-native-polar-ble-sdk --save`

### Mostly automatic installation

`$ react-native link react-native-polar-ble-sdk`

## Usage

```javascript
import {
  NativeModules,
  NativeEventEmitter,
} from 'react-native';

import PolarBleSdk from 'react-native-polar-ble-sdk';

const polarEmitter = new NativeEventEmitter(NativeModules.PolarBleSdkModule);

////////// currently available events

polarEmitter.addListener('connectionState', ({ id, state }) => {
  console.log(`device ${id} connection state : ${state}`);
});

polarEmitter.addListener('firmwareVersion', ({ id, value }) => {
  console.log(`device ${id} firmware version : ${value}`);  
});

polarEmitter.addListener('batteryLevel', ({ id, value }) => {
  console.log(`device ${id} battery level : ${value}`);  
});

polarEmitter.addListener('ecgFeatureReady', ({ id }) => {
  console.log(`ecg feature ready on device ${id}`);    
});

polarEmitter.addListener('accelerometerFeatureReady', ({ id }) => {
  console.log(`accelerometer feature ready on device ${id}`);    
});

polarEmitter.addListener('ppgFeatureReady', ({ id }) => {
  console.log(`ppg feature ready on device ${id}`);      
});

polarEmitter.addListener('ppiFeatureReady', ({ id }) => {
  console.log(`ppi feature ready on device ${id}`);    
});

polarEmitter.addListener('hrData', (data) => {
  const {
    id,
    hr,
    contact,
    contactSupported,
    rrAvailable,
    rrs,
    rrsMs,  
  } = data;
});

polarEmitter.addListener('ecgData', (data) => {
  const { id, timeStamp, samples } = data;
  const {

  } = samples[0];
});

polarEmitter.addListener('accData', (data) => {
  const { id, timeStamp, samples } = data;
  const {

  } = samples[0];
});

polarEmitter.addListener('ppgData', (data) => {
  const { id, timeStamp, samples } = data;
  const {

  } = samples[0];
});

polarEmitter.addListener('ppiData', (data) => {
  const { id, timeStamp, samples } = data;
  const {

  } = samples[0];
});

////////// currently available methods

// polar device's id also appearing in the advertised device name
const id = '12345XYZ';

PolarBleSdk.connectToDevice(id);

// now wait for the 'connectionState' event to be emitted with the right id
// and a 'connected' state value, then wait for corresponding 'xxxFeatureReady'
// event to be emitted with the right id before calling
// PolarBleSdk.startXxxStreaming() to start receiving the data from event
// 'xxxData' (except for hrData, which is emitted continuously as soon as
// the device is connected)

// will work with both H10 and OH1 devices
PolarBleSdk.startAccStreaming()
PolarBleSdk.stopAccStreaming();

// will only work with H10 devices
PolarBleSdk.startEcgStreaming();
PolarBleSdk.stopEcgStreaming();

// will only work with OH1 devices
PolarBleSdk.startPpgStreaming()
PolarBleSdk.stopPpgStreaming();
PolarBleSdk.startPpiStreaming();
PolarBleSdk.stopPpiStreaming();

PolarBleSdk.disconnectFromDevice(id);
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

