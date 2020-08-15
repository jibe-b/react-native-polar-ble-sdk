// import { NativeModules } from 'react-native';
// const { PolarBleSdk } = NativeModules;
// export default PolarBleSdk;

"use strict";
var React = require("react-native");
var polarBleSdk = React.NativeModules.PolarBleSdk;
// var polarEmitter = new React.NativeEventEmitter(polarBleSdk);

//*
class PolarBleSdk {
  constructor() {
    // this.onConnectionStateChanged = this.onConnectionStateChanged.bind(this);
  }

  // callback(content) {
  //   console.log(`callback : ${content}`);
  // }

  connectToDevice(deviceId) {
    polarBleSdk.connectToDevice(deviceId);
  }

  disconnectFromDevice(deviceId) {
    polarBleSdk.disconnectFromDevice(deviceId);
  }


  startEcgStreaming() {
  // streamECG() {
    polarBleSdk.startEcgStreaming();
  }

  startAccStreaming() {
    polarBleSdk.startAccStreaming();    
  }

  addListener(event, callback) {
    // return polarEmitter.addListener(event, callback);
  }

  // EVENT LISTENERS :

  // onConnectionStateChanged(connectionState) {

  // }

  // setListener(listener) {
  //   polarBleSdk.setListener(listener);
  // }

  // printSomething() {
  //   polarBleSdk.printSomething(this.callback);
  // }
};

module.exports = new PolarBleSdk();
