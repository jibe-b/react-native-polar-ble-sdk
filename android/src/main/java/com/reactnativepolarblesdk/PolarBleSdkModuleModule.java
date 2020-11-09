package com.reactnativepolarblesdk;

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
import polar.com.sdk.api.errors.PolarInvalidArgument;
import polar.com.sdk.api.model.PolarDeviceInfo;
import polar.com.sdk.api.model.PolarSensorSetting;
import polar.com.sdk.api.model.PolarAccelerometerData;
import polar.com.sdk.api.model.PolarAccelerometerData.PolarAccelerometerSample;
import polar.com.sdk.api.model.PolarEcgData;
import polar.com.sdk.api.model.PolarHrData;
import polar.com.sdk.api.model.PolarOhrPPGData;
import polar.com.sdk.api.model.PolarOhrPPGData.PolarOhrPPGSample
import polar.com.sdk.api.model.PolarOhrPPIData;
import polar.com.sdk.api.model.PolarOhrPPIData.PolarOhrPPISample
import polar.com.sdk.api.model.PolarExerciseEntry;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.Arguments;


public class PolarBleSdkModuleModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;

    public PolarBleApi api;

    // todo make hashmap of disposables with polar device id as key to manage multiple devices
    // (provided the sdk allows it)
    // e.g. :
    // private Map<String, Disposable> polarDevices = new HashMap<String, Disposable>();
    // then we will be able to call startEcgStreaming (and stopEcgStreaming) with a deviceId argument
    // (and not a useless callback)
    // for now we will keep a plugin for a single simultaneously connected sensor.
    // All events are emitted with a "id": deviceId field, so the api won't change much
    // when we add multiple sensor ability

    /*
    private class Device {
        private String deviceId = "";
        private Disposable broadcastDisposable = null;
        private Disposable ecgDisposable = null;
        private Disposable accDisposable = null;
        private Disposable ppgDisposable = null;
        private Disposable ppiDisposable = null;
        private Disposable scanDisposable = null;
        private Disposable autoConnectDisposable = null;
        private PolarExerciseEntry exerciseEntry = null;
        private String connectionState = "disconnected";

        public Device(deviceId) {
            this->deviceId = deviceId;
        }
    }
    //*/

    public String deviceId = "";
    private Disposable broadcastDisposable = null;
    private Disposable ecgDisposable = null;
    private Disposable accDisposable = null;
    private Disposable ppgDisposable = null;
    private Disposable ppiDisposable = null;
    private Disposable scanDisposable = null;
    private Disposable autoConnectDisposable = null;
    private PolarExerciseEntry exerciseEntry = null;

    private ReactApplicationContext ctx;

    public PolarBleSdkModuleModule(ReactApplicationContext reactContext) {
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
                WritableMap params = Arguments.createMap();
                params.putString("id", deviceId);
                params.putBoolean("state", powered);
                emit(ctx, "blePower", params);
            }

            /* * * * * * * * * * * * DEVICE CONNECTION * * * * * * * * * * * */

            @Override
            public void deviceConnected(PolarDeviceInfo deviceInfo) {
                WritableMap params = Arguments.createMap();
                params.putString("id", deviceInfo.deviceId);
                params.putString("state", "connected");
                emit(ctx, "connectionState", params);
                // set deviceId to deviceInfo.deviceId ?
            }

            @Override
            public void deviceConnecting(PolarDeviceInfo deviceInfo) {
                WritableMap params = Arguments.createMap();
                params.putString("id", deviceInfo.deviceId);
                params.putString("state", "connecting");
                emit(ctx, "connectionState", params);
            }

            @Override
            public void deviceDisconnected(PolarDeviceInfo deviceInfo) {
                WritableMap params = Arguments.createMap();
                params.putString("id", deviceInfo.deviceId);
                params.putString("state", "disconnected");
                emit(ctx, "connectionState", params);
                // set deviceId to null ?
            }

            /* * * * * * * * * * * * * FEATURES READY * * * * * * * * * * * * */

            @Override
            public void hrFeatureReady(String identifier) {
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                emit(ctx, "hrFeatureReady", params);
            }

            @Override
            public void ecgFeatureReady(String identifier) {
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                emit(ctx, "ecgFeatureReady", params);
            }

            @Override
            public void accelerometerFeatureReady(String identifier) {
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                emit(ctx, "accelerometerFeatureReady", params);
            }

            @Override
            public void ppgFeatureReady(String identifier) {
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                emit(ctx, "ppgFeatureReady", params);
            }

            @Override
            public void ppiFeatureReady(String identifier) {
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                emit(ctx, "ppiFeatureReady", params);
            }

            @Override
            public void biozFeatureReady(String identifier) {
                // TODO (wth is bioz ?)
            }

            @Override
            public void disInformationReceived(String identifier, UUID u, String value) {
                if (u.equals(UUID.fromString("00002a28-0000-1000-8000-00805f9b34fb"))) {
                    WritableMap params = Arguments.createMap();
                    params.putString("id", identifier);
                    params.putString("value", value.trim());
                    emit(ctx, "firmwareVersion", params);
                }
            }

            @Override
            public void batteryLevelReceived(String identifier, int level) {
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                params.putInt("value", level);
                emit(ctx, "batteryLevel", params);
            }

            @Override
            public void hrNotificationReceived(String identifier,
                                               PolarHrData hrData) {
                WritableMap params = Arguments.createMap();
                params.putString("id", identifier);
                params.putInt("hr", hrData.hr);
                params.putBoolean("contact", hrData.contactStatus);
                params.putBoolean("contactSupported", hrData.contactStatusSupported);
                params.putBoolean("rrAvailable", hrData.rrAvailable);

                WritableArray rrs = Arguments.createArray();
                for (Integer i : hrData.rrs) { rrs.pushInt(i); }
                params.putArray("rrs", rrs);

                WritableArray rrsMs = Arguments.createArray();
                for (Integer i : hrData.rrsMs) { rrsMs.pushInt(i); }
                params.putArray("rrsMs", rrsMs);

                emit(ctx, "hrData", params);
            }

            @Override
            public void polarFtpFeatureReady(String identifier) {
                // TODO (wth is polar ftp ?)
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
            ecgDisposable = api.requestEcgSettings(identifier).toFlowable().flatMap(
                (Function<PolarSensorSetting, Publisher<PolarEcgData>>) setting -> {
                    return api.startEcgStreaming(identifier, setting.maxSettings());
                }
            ).subscribe(
                ecgData -> {
                    WritableMap params = Arguments.createMap();
                    WritableArray samples = Arguments.createArray();
                    for (Integer s : ecgData.samples) {
                        samples.pushInt(s);
                    }
                    params.putString("id", identifier);
                    params.putArray("samples", samples);
                    params.putDouble("timeStamp", new Double(ecgData.timeStamp));
                    emit(reactContext, "ecgData", params);
                },
                throwable -> {
                    // Log.e(TAG, "" + throwable.toString())
                    ecgDisposable = null;
                },
                () -> {
                    // Log.d(TAG, "complete")
                }
            );

            /*
            ecgDisposable =
                api.requestEcgSettings(identifier).toFlowable().flatMap(new Function<PolarSensorSetting, Publisher<PolarEcgData>>() {
                    @Override
                    public Publisher<PolarEcgData> apply(PolarSensorSetting sensorSetting) throws Exception {
                        return api.startEcgStreaming(identifier, sensorSetting.maxSettings());
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
            //*/

            // streamCallback.invoke("ecg started");
        }        
    }

    @ReactMethod
    public void stopEcgStreaming() {
        if (ecgDisposable != null) {
            ecgDisposable.dispose();
            ecgDisposable = null;
        }
    }

    @ReactMethod
    public void startAccStreaming(/*Callback streamCallback*/) {
        final String identifier = deviceId;
        if (accDisposable == null) {
            accDisposable = api.requestAccSettings(identifier).toFlowable().flatMap(
                (Function<PolarSensorSetting, Publisher<PolarAccelerometerData>>) settings -> {
                    return api.startAccStreaming(identifier, settings.maxSettings());
                }
            ).observeOn(AndroidSchedulers.mainThread()).subscribe(
                accData -> {
                    WritableMap params = Arguments.createMap();
                    WritableArray samples = Arguments.createArray();
                    for (PolarAccelerometerSample sample : accData.samples) {
                        WritableArray vector = Arguments.createArray();
                        vector.pushInt(sample.x);
                        vector.pushInt(sample.y);
                        vector.pushInt(sample.z);
                        samples.pushArray(vector);
                    }
                    params.putString("id", identifier);
                    params.putArray("samples", samples);
                    params.putDouble("timeStamp", new Double(accData.timeStamp));
                    emit(reactContext, "accData", params);
                },
                throwable -> {
                    // Log.e(TAG,"" + throwable.getLocalizedMessage());
                    accDisposable = null;
                },
                () -> {
                    // Log.d(TAG,"complete");
                }
            );
            /*
            accDisposable =
                api.requestAccSettings(deviceId).toFlowable().flatMap(new Function<PolarSensorSetting, Publisher<PolarAccelerometerData>>() {
                    @Override
                    public Publisher<PolarAccelerometerData> apply(PolarSensorSetting sensorSetting) throws Exception {
                        return api.startAccStreaming(deviceId, sensorSetting.maxSettings());
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
                            params.putString("id", identifier);
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
            //*/

            // streamCallback.invoke("acc started");
        }
    }

    @ReactMethod
    public void stopAccStreaming() {
        if (accDisposable != null) {
            accDisposable.dispose();
            accDisposable = null;
        }
    }

    @ReactMethod
    public void startPpgStreaming() {
        final String identifier = deviceId;
        if (ppgDisposable == null) {
            ppgDisposable = api.requestPpgSettings(identifier).toFlowable().flatMap(
                (Function<PolarSensorSetting, Publisher<PolarOhrPPGData>>) setting -> {
                    api.startOhrPPGStreaming(identifier, setting.maxSettings());
                }
            ).subscribe(
                ppgData -> {
                    WritableMap params = Arguments.createMap();
                    WritableArray samples = Arguments.createArray();
                    for (PolarOhrPPGSample sample : ppgData.samples) {
                        WritableArray vector = Arguments.createMap();
                        vector.putInt("ppg0", sample.x);
                        vector.putInt("ppg1", sample.y);
                        vector.putInt("ppg2", sample.z);
                        vector.putInt("ambient", sample.ambient);
                        samples.pushMap(vector);
                    }
                    params.putString("id", identifier);
                    params.putArray("samples", samples);
                    params.putDouble("timeStamp", new Double(ppgData.timeStamp));
                    emit(reactContext, "ppgData", params);
                },
                throwable -> {
                    // Log.e(TAG,""+throwable.getLocalizedMessage())
                    ppgDisposable = null;
                },
                () -> {
                    // Log.d(TAG,"complete")
                }
            );
        }
    }

    @ReactMethod
    public void stopPpgStreaming() {
        if (ppgDisposable != null) {
            ppgDisposable.dispose();
            ppgDisposable = null;
        }
    }

    @ReactMethod
    public void startPpiStreaming() {
        final String identifier = deviceId;
        if(ppiDisposable == null) {
            ppiDisposable = api.startOhrPPIStreaming(identifier).observeOn(AndroidSchedulers.mainThread()).subscribe(
                ppiData -> {
                    WritableMap params = Arguments.createMap();
                    WritableArray samples = Arguments.createArray();
                    for (PolarOhrPPISample sample : ppiData.samples) {
                        WritableArray vector = Arguments.createMap();
                        vector.putInt("hr", sample.hr);
                        vector.putInt("ppInMs", sample.ppi);
                        vector.putInt("ppErrorEstimate", sample.errorEstimate);
                        vector.putBoolean("blockerBit", sample.blockerBit);
                        vector.putBoolean("skinContactStatus", sample.skinContactStatus);
                        vector.putBoolean("skinContactSupported", sample.skinContactSupported);
                        samples.pushMap(vector);
                    }
                    params.putString("id", identifier);
                    params.putArray("samples", samples);
                    params.putDouble("timeStamp", new Double(ppiData.timeStamp));
                    emit(reactContext, "ppiData", params);
                },
                throwable -> {
                    // Log.e(TAG,""+throwable.getLocalizedMessage());
                    ppgDisposable = null;
                },
                () -> {
                    // Log.d(TAG,"complete");
                }
            );
        }
    }

    @ReactMethod
    public void stopPpiStreaming() {
        if (ppiDisposable != null) {
            ppiDisposable.dispose();
            ppiDisposable = null;
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
