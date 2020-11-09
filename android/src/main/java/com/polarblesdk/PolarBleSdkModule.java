package com.polarblesdk;

import android.content.Context;
// import android.support.annotation.Nullable;
import androidx.annotation.Nullable;
import android.bluetooth.BluetoothAdapter;

import java.util.UUID;

import org.reactivestreams.Publisher;

import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers;
import io.reactivex.rxjava3.disposables.Disposable;
import io.reactivex.rxjava3.functions.Action;
import io.reactivex.rxjava3.functions.Consumer;
import io.reactivex.rxjava3.functions.Function;
import polar.com.sdk.api.PolarBleApi;
import polar.com.sdk.api.PolarBleApiCallback;
import polar.com.sdk.api.PolarBleApiDefaultImpl;
import polar.com.sdk.api.model.PolarDeviceInfo;
import polar.com.sdk.api.model.PolarAccelerometerData;
import polar.com.sdk.api.model.PolarAccelerometerData.PolarAccelerometerSample;
import polar.com.sdk.api.model.PolarEcgData;
import polar.com.sdk.api.model.PolarHrData;
import polar.com.sdk.api.model.PolarSensorSetting;
import polar.com.sdk.api.errors.PolarInvalidArgument;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.Arguments;


public class PolarBleSdkModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;

    public PolarBleApi api;

    // todo make hashmap of disposables with polar device id as key to manage multpile devices (if the sdk allows it)
    // e.g. :
    // private Map<String, Disposable> polarDevices = new HashMap<String, Disposable>();
    // then we will be able to call startEcgStreaming (and stopEcgStreaming) with a deviceId argument
    // (and not a useless callback)
    // for now we will keep a plugin for a single simultaneously connected sensor.
    // All events are emitted with a "id": deviceId field, so the api won't change much
    // when we add multiple sensor ability

    public String deviceId = "";
    private Disposable ecgDisposable = null;
    private Disposable accDisposable = null;

    private ReactApplicationContext ctx;

    public PolarBleSdkModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        ctx = reactContext;

        api = PolarBleApiDefaultImpl.defaultImplementation(reactContext,
                PolarBleApi.FEATURE_POLAR_SENSOR_STREAMING |
                        PolarBleApi.FEATURE_BATTERY_INFO |
                        PolarBleApi.FEATURE_DEVICE_INFO |
                        PolarBleApi.FEATURE_HR);

        api.setApiCallback(new PolarBleApiCallback() {
            @Override
            public void blePowerStateChanged(boolean powered) {
                // Log.d(TAG, "BluetoothStateChanged " + powered);
            }

            /* * * * * * * * * * * * DEVICE CONNECTION * * * * * * * * * * * */

            @Override
            public void deviceConnected(PolarDeviceInfo polarDeviceInfo) {
                // Log.d(TAG, "Device connected " + polarDeviceInfo.deviceId);
                // Toast.makeText(classContext, R.string.connected,
                //         Toast.LENGTH_SHORT).show();
                // connectTimeout.removeCallbacks(abortConnect);
                // buttonConnect.setText("DISCONNECT");
                // buttonRecord.setEnabled(true);
                // buttonRecord.setAlpha(1);
                WritableMap params = Arguments.createMap();
                params.putString("id", polarDeviceInfo.deviceId);
                params.putString("state", "connected");
                // emit(ctx, "events", params);
                emit(ctx, "connectionState", params);
            }

            @Override
            public void deviceConnecting(PolarDeviceInfo polarDeviceInfo) {
                // buttonConnect.setText("CONNECTING ...");
                WritableMap params = Arguments.createMap();
                params.putString("id", polarDeviceInfo.deviceId);
                params.putString("state", "connecting");
                // emit(ctx, "events", params);
                emit(ctx, "connectionState", params);
            }

            @Override
            public void deviceDisconnected(PolarDeviceInfo polarDeviceInfo) {
                // Log.d(TAG, "Device disconnected " + polarDeviceInfo);
                // buttonConnect.setText("CONNECT");
                // buttonRecord.setEnabled(false);
                // buttonRecord.setAlpha(0.5f);
                // textViewFW.setText("");
                // textViewHR.setText("");
                WritableMap params = Arguments.createMap();
                params.putString("id", polarDeviceInfo.deviceId);
                params.putString("state", "disconnected");
                // emit(ctx, "events", params);
                emit(ctx, "connectionState", params);
            }

            /* * * * * * * * * * * * * FEATURES READY * * * * * * * * * * * * */

            @Override
            public void hrFeatureReady(String identifier) {
                // WritableMap params = Arguments.createMap();
                // params.putBoolean("hr", true);
                // emit(ctx, "featureReady", params);
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                // params.putString("feature", "hr");
                emit(ctx, "hrFeatureReady", params);
            }

            @Override
            public void ecgFeatureReady(String identifier) {
                // WritableMap params = Arguments.createMap();
                // params.putBoolean("ecg", true);
                // emit(ctx, "featureReady", params);
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                // params.putString("feature", "ecg");
                emit(ctx, "ecgFeatureReady", params);
            }

            @Override
            public void accelerometerFeatureReady(String identifier) {
                // WritableMap params = Arguments.createMap();
                // params.putBoolean("accelerometer", true);
                // emit(ctx, "featureReady", params);
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                // params.putString("feature", "accelerometer");
                emit(ctx, "accelerometerFeatureReady", params);
            }

            @Override
            public void ppgFeatureReady(String identifier) {
                // Log.d(TAG, "PPG Feature ready " + identifier);
            }

            @Override
            public void ppiFeatureReady(String identifier) {
                // Log.d(TAG, "PPI Feature ready " + identifier);
            }

            @Override
            public void biozFeatureReady(String identifier) {
                // Log.d(TAG, "BIOZ Feature ready " + identifier);
            }

            @Override
            public void disInformationReceived(String identifier, UUID u, String value) {
                if (u.equals(UUID.fromString("00002a28-0000-1000-8000-00805f9b34fb"))) {
                    WritableMap params = Arguments.createMap();
                    params.putString("id", identifier);
                    params.putString("value", value.trim());
                    emit(ctx, "firmwareVersion", params);
                    // Log.d(TAG, "Firmware: " + identifier + " " + value.trim());
                    // textViewFW.append(msg + "\n");
                }
            }

            @Override
            public void batteryLevelReceived(String identifier, int level) {
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                params.putInt("value", level);
                emit(ctx, "batteryLevel", params);
                // Log.d(TAG, "Battery level " + identifier + " " + level);
                // Toast.makeText(classContext, msg, Toast.LENGTH_LONG).show();
                // textViewFW.append(msg + "\n");
            }

            @Override
            public void hrNotificationReceived(String identifier,
                                               PolarHrData polarHrData) {
                // Log.d(TAG, "HR " + polarHrData.hr);
                // textViewHR.setText(String.valueOf(polarHrData.hr));
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                params.putInt("hr", polarHrData.hr);

                params.putBoolean("contactStatus", polarHrData.contactStatus);
                params.putBoolean("contactStatusSupported", polarHrData.contactStatusSupported);
                params.putBoolean("rrAvailable", polarHrData.rrAvailable);

                WritableArray rrs = Arguments.createArray();
                for (Integer i : polarHrData.rrs) { rrs.pushInt(i); }
                params.putArray("rrs", rrs);

                WritableArray rrsMs = Arguments.createArray();
                for (Integer i : polarHrData.rrsMs) { rrsMs.pushInt(i); }
                params.putArray("rrsMs", rrsMs);

                emit(ctx, "hrData", params);
            }

            @Override
            public void polarFtpFeatureReady(String identifier) {
                // Log.d(TAG, "Polar FTP ready " + identifier); // see this later ... ?
            }
        });
    }

    @Override
    public String getName() {
        return "PolarBleSdk";
    }

    /*
    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put("truc", 1);
        return constants;
    }
    //*/

    private void emit(ReactContext reactContext,
                           String eventName,
                           @Nullable WritableMap params) {
      reactContext
          .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
          .emit(eventName, params);
    }

    @ReactMethod
    public void connectToDevice(String deviceId) {
        this.deviceId = deviceId;
        try {
            api.connectToDevice(this.deviceId);
        } catch (Exception e) {

        }
    }

    @ReactMethod
    public void disconnectFromDevice(String deviceId) {
        this.deviceId = deviceId;
        try {
            api.disconnectFromDevice(this.deviceId);
        } catch (Exception e) {

        }
    }

    @ReactMethod
    public void startEcgStreaming(/*Callback streamCallback*/) {
        final String identifier = deviceId;
        if (ecgDisposable == null) {
            ecgDisposable =
                    api.requestEcgSettings(identifier).toFlowable().flatMap(new Function<PolarSensorSetting, Publisher<PolarEcgData>>() {
                        @Override
                        public Publisher<PolarEcgData> apply(PolarSensorSetting sensorSetting) throws Exception {
                            return api.startEcgStreaming(deviceId,
                                    sensorSetting.maxSettings());
                        }
                    }).observeOn(AndroidSchedulers.mainThread()).subscribe(
                            new Consumer<PolarEcgData>() {
                                @Override
                                public void accept(PolarEcgData polarEcgData) throws Exception {
                                    WritableMap params = Arguments.createMap();
                                    WritableArray samples = Arguments.createArray();
                                    for (Integer s : polarEcgData.samples) {
                                        samples.pushInt(s);
                                    }
                                    params.putString("id", identifier);
                                    params.putArray("samples", samples);
                                    params.putDouble("timeStamp", new Double(polarEcgData.timeStamp));
                                    emit(reactContext, "ecgData", params);
                                }
                            },
                            new Consumer<Throwable>() {
                                @Override
                                public void accept(Throwable throwable) throws Exception {
                                    // Log.e(TAG,
                                    //         "" + throwable.getLocalizedMessage());
                                    ecgDisposable = null;
                                }
                            },
                            new Action() {
                                @Override
                                public void run() throws Exception {
                                    // Log.d(TAG, "complete");
                                }
                            }
                    );

            // streamCallback.invoke("ecg started");
        // } else {
        //     // NOTE stops streaming if it is "running"
        //     ecgDisposable.dispose();
        //     ecgDisposable = null;
        //     // streamCallback.invoke("ecg disposed");
        }        
    }

    @ReactMethod
    public void stopEcgStreaming() {
        if (ecgDisposable != null) {
            ecgDisposable.dispose();
            ecgDisposable = null;
        }
    }

    //*
    @ReactMethod
    public void startAccStreaming(/*Callback streamCallback*/) {
        if (accDisposable == null) {
            accDisposable =
                    api.requestAccSettings(deviceId).toFlowable().flatMap(new Function<PolarSensorSetting, Publisher<PolarAccelerometerData>>() {
                        @Override
                        public Publisher<PolarAccelerometerData> apply(PolarSensorSetting sensorSetting) throws Exception {
                            return api.startAccStreaming(deviceId,
                                    sensorSetting.maxSettings());
                        }
                    }).observeOn(AndroidSchedulers.mainThread()).subscribe(
                            new Consumer<PolarAccelerometerData>() {
                                @Override
                                public void accept(PolarAccelerometerData polarAccData) throws Exception {
                                    WritableMap params = Arguments.createMap();
                                    WritableArray samples = Arguments.createArray();
                                    for (PolarAccelerometerSample sample : polarAccData.samples) {
                                        WritableArray vector = Arguments.createArray();
                                        vector.pushInt(sample.x);
                                        vector.pushInt(sample.y);
                                        vector.pushInt(sample.z);
                                        samples.pushArray(vector);
                                    }
                                    params.putArray("samples", samples);
                                    params.putDouble("timeStamp", (double)(polarAccData.timeStamp));
                                    // params.putString("connectionState", "disconnected");
                                    emit(reactContext, "accData", params);
                                }
                            },
                            new Consumer<Throwable>() {
                                @Override
                                public void accept(Throwable throwable) throws Exception {
                                    // Log.e(TAG,
                                    //         "" + throwable.getLocalizedMessage());
                                    accDisposable = null;
                                }
                            },
                            new Action() {
                                @Override
                                public void run() throws Exception {
                                    // Log.d(TAG, "complete");
                                }
                            }
                    );
            // streamCallback.invoke("acc started");
        // } else {
        //     accDisposable.dispose();
        //     accDisposable = null;
        //     // streamCallback.invoke("acc disposed");
        }
    }
    //*/

    @ReactMethod
    public void stopAccStreaming() {
        if (accDisposable != null) {
            accDisposable.dispose();
            accDisposable = null;
        }
    }

    @ReactMethod
    public void sampleMethod(String stringArgument, int numberArgument, Callback callback) {
        // TODO: Implement some actually useful functionality
        callback.invoke("Received numberArgument: " + numberArgument + " stringArgument: " + stringArgument);
    }

    @ReactMethod
    public void printSomething(Callback callback) {
        // return "something";
        callback.invoke("something");
    }
}
