import { NativeModules } from 'react-native';

const { PolarBleSdkModule } = NativeModules;

class PolarBleSdk {
  constructor() {
    // todo ?
  }

  connectToDevice(deviceId) {
    PolarBleSdkModule.connectToDevice(deviceId);
  }

  disconnectFromDevice(deviceId) {
    PolarBleSdkModule.disconnectFromDevice(deviceId);
  }

  startEcgStreaming() {
    PolarBleSdkModule.startEcgStreaming();
  }

  startAccStreaming() {
    PolarBleSdkModule.startAccStreaming();    
  }

  stopEcgStreaming() {
    PolarBleSdkModule.stopEcgStreaming();
  }

  stopAccStreaming() {
    PolarBleSdkModule.stopAccStreaming();    
  }

  sampleMethod(number, string, callback) {
    PolarBleSdkModule.sampleMethod(number, string, callback);
  }

  // addListener(event, callback) {
  //   // return polarEmitter.addListener(event, callback);
  // }
}

export default new PolarBleSdk();
// export default PolarBleSdkModule;
