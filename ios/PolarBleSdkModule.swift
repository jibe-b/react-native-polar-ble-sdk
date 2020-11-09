import Foundation
import PolarBleSdk
import RxSwift
import CoreBluetooth

@objc(PolarBleSdkModule)
class PolarBleSdkModule : RCTEventEmitter,
                          PolarBleApiObserver,
                          PolarBleApiPowerStateObserver,
                          PolarBleApiDeviceHrObserver,
                          PolarBleApiDeviceInfoObserver,
                          PolarBleApiDeviceFeaturesObserver,
                          PolarBleApiLogger,
                          PolarBleApiCCCWriteObserver {

    public static var emitter : RCTEventEmitter!

    var api: PolarBleApi = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Features.allFeatures.rawValue);
    var broadcast: Disposable?
    var ecgToggle: Disposable?
    var accToggle: Disposable?
    var ppgToggle: Disposable?
    var ppiToggle: Disposable?
    var searchToggle: Disposable?
    var autoConnect: Disposable?
    var entry: PolarExerciseEntry?
    var deviceId = "0A3BA92B" // TODO replace this with your device id

    override init() {
        super.init()
        PolarBleSdkModule.emitter = self

        // self.api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Features.allFeatures.rawValue);
        api.observer = self
        api.deviceHrObserver = self
        api.deviceInfoObserver = self
        api.powerStateObserver = self
        api.deviceFeaturesObserver = self
        api.logger = self
        api.cccWriteObserver = self
        api.polarFilter(false)
        // NSLog("\(PolarBleApiDefaultImpl.versionInfo())")
    }

    override func supportedEvents() -> [String]! {
        return [
            "blePower",
            "connectionState",
            "ecgFeatureReady",
            "accelerometerFeatureReady",
            "ppgFeatureReady",
            "ppiFeatureReady",
            "firmwareVersion",
            "batteryLevel",
            "hrData",
            "ecgData",
            "accData"
        ]
    }

    override static func requiresMainQueueSetup() -> Bool {
        return false // module doesn't rely on UIKit, see https://reactnative.dev/docs/native-modules-ios
    }

    @objc func connectToDevice(_ id: String) -> Void {
        deviceId = id
        self.sendEvent(withName: "connectionState", body: ["id": id, "state": "scanning"])
        do {
            try self.api.connectToDevice(id)
        } catch {}
    }

    @objc func disconnectFromDevice(_ id: String) -> Void {
        deviceId = id
        self.sendEvent(withName: "connectionState", body: ["id": id, "state": "disconnecting"])
        do {
            try self.api.disconnectFromDevice(id)
        } catch {}
    }

    @objc func startEcgStreaming() -> Void {
        if ecgToggle == nil {
            ecgToggle = api.requestEcgSettings(deviceId).asObservable().flatMap({ (settings) -> Observable<PolarEcgData> in
                return self.api.startEcgStreaming(self.deviceId, settings: settings.maxSettings())
            }).observeOn(MainScheduler.instance).subscribe{ e in
                switch e {
                case .next(let data):
                    let result: NSMutableDictionary = [:]
                    result["id"] = self.deviceId
                    result["timeStamp"] = data.timeStamp
                    let samples: NSMutableArray = []
                    for µv in data.samples {
                        // NSLog("    µV: \(µv)")
                        samples.add(µv)
                    }
                    result["samples"] = samples
                    self.sendEvent(withName: "ecgData", body: result)
                case .error(let err):
                    // NSLog("start ecg error: \(err)")
                    self.ecgToggle = nil
                case .completed:
                    break
                }
            }
        }
    }

    @objc func stopEcgStreaming() -> Void {
        if ecgToggle != nil {
            ecgToggle?.dispose()
            ecgToggle = nil
        }
    }

    @objc func startAccStreaming() -> Void {
        if accToggle == nil {
            accToggle = api.requestAccSettings(deviceId).asObservable().flatMap({ (settings) -> Observable<PolarAccData> in
                // NSLog("settings: \(settings.settings)")
                return self.api.startAccStreaming(self.deviceId, settings: settings.maxSettings())
            }).observeOn(MainScheduler.instance).subscribe{ e in
                switch e {
                case .next(let data):
                    let result: NSMutableDictionary = [:]
                    result["id"] = self.deviceId
                    result["timeStamp"] = data.timeStamp
                    let samples: NSMutableArray = []
                    for item in data.samples {
                        // NSLog("    x: \(item.x) y: \(item.y) z: \(item.z)")
                        let vec: NSMutableArray = [item.x, item.y, item.z]
                        samples.add(vec)
                    }
                    result["samples"] = samples
                    self.sendEvent(withName: "accData", body: result)
                case .error(let err):
                    // NSLog("ACC error: \(err)")
                    self.accToggle = nil
                case .completed:
                    break
                }
            }
        }
    }

    @objc func stopAccStreaming() -> Void {
        if accToggle != nil {
            accToggle?.dispose()
            accToggle = nil            
        }
    }

    @objc func startPpgStreaming() -> Void {
        if ppgToggle == nil {
            ppgToggle = api.requestPpgSettings(deviceId).asObservable().flatMap({ (settings) -> Observable<PolarPpgData> in
                return self.api.startOhrPPGStreaming(self.deviceId, settings: settings.maxSettings())
            }).observeOn(MainScheduler.instance).subscribe{ e in
                switch e {
                case .completed:
                    // NSLog("ppg finished")
                    break
                case .error(let err):
                    // NSLog("start ppg error: \(err)")
                    self.ppgToggle = nil
                case .next(let data):
                    let result: NSMutableDictionary = [:]
                    result["id"] = self.deviceId
                    let samples: NSMutableArray = []
                    for item in data.samples {
                        // NSLog("    ppg0: \(item.ppg0) ppg1: \(item.ppg1) ppg2: \(item.ppg2)")
                        let ppg: NSMutableDictionary = [:]
                        ppg["ppg0"] = item.ppg0
                        ppg["ppg1"] = item.ppg1
                        ppg["ppg2"] = item.ppg2
                        ppg["ambient"] = item.ambient
                        samples.add(ppg)
                    }
                    result["samples"] = samples
                    self.sendEvent(withName: "ppgData", body: result)
                }
            }
        }        
    }

    @objc func stopPpgStreaming() -> Void {
        if ppgToggle != nil {
            ppgToggle?.dispose()
            ppgToggle = nil        
        }
    }

    @objc func startPpiStreaming() -> Void {
        if ppiToggle == nil {
            ppiToggle = api.startOhrPPIStreaming(deviceId).observeOn(MainScheduler.instance).subscribe { e in
                switch e {
                case .completed:
                    // NSLog("ppi complete")
                    break
                case .error(let err):
                    // NSLog("start ppi error: \(err)")
                    self.ppiToggle = nil
                case .next(let data):
                    let result: NSMutableDictionary = [:]
                    result["id"] = self.deviceId
                    result["timeStamp"] = data.timeStamp
                    let samples: NSMutableArray = []
                    for item in data.samples {
                        // NSLog("PPI: \(item.ppInMs)")
                        /*
                        let sample: NSMutableDictionary = [:]
                        sample["hr"] = item.hr
                        sample["ppInMs"] = item.ppInMs
                        sample["ppErrorEstimate"] = item.ppErrorEstimate
                        sample["blockerBit"] = item.blockerBit
                        sample["skinContactStatus"] = item.skinContactStatus
                        sample["skinContactSupported"] = item.skinContactSupported
                        samples.add(sample)
                        //*/
                        samples.add(item)
                    }
                    result["samples"] = samples
                    self.sendEvent(withName: "ppiData", body: result)
                }
            }
        }
    }

    @objc func stopPpiStreaming() -> Void {
        if ppiToggle != nil {
            ppiToggle?.dispose()
            ppiToggle = nil
        }
    }

    // CALLBACK EXAMPLE :

    @objc(sampleMethod:numberArgument:callback:)
    func sampleMethod(_ stringArgument: String, numberArgument: NSNumber, callback: RCTResponseSenderBlock) -> Void {
        // %@ formats any NSObject to its string representation
        let res = String(format: "number argument: %@, string argument: %@", numberArgument, stringArgument)
        callback([NSNull(), res])
    }

    //////////////////// OVERRIDDEN CALLBACK METHODS FROM VARIOUS PARENT CLASSES

    // PolarBleApiObserver
    func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {
        // NSLog("DEVICE CONNECTING: \(polarDeviceInfo)")
        self.sendEvent(withName: "connectionState", body: ["id": polarDeviceInfo.deviceId, "state": "connecting"])
    }
    
    func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
        // NSLog("DEVICE CONNECTED: \(polarDeviceInfo)")
        // deviceId = polarDeviceInfo.deviceId
        self.sendEvent(withName: "connectionState", body: ["id": polarDeviceInfo.deviceId, "state": "connected"])
    }
    
    func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo) {
        // NSLog("DISCONNECTED: \(polarDeviceInfo)")
        self.sendEvent(withName: "connectionState", body: ["id": polarDeviceInfo.deviceId, "state": "disconnected"])
    }
    
    // PolarBleApiDeviceInfoObserver
    func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
        // NSLog("battery level updated: \(batteryLevel)")
        self.sendEvent(withName: "batteryLevel", body: ["id": identifier, "value": batteryLevel])
    }
    
    func disInformationReceived(_ identifier: String, uuid: CBUUID, value: String) {
        // NSLog("dis info: \(uuid.uuidString) value: \(value)")
        if uuid.uuidString == "00002a28-0000-1000-8000-00805f9b34fb" {
            let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
            self.sendEvent(withName: "firmwareVersion", body: ["id": identifier, "value": v])
        }
    }
    
    // PolarBleApiDeviceHrObserver
    func hrValueReceived(_ identifier: String, data: PolarHrData) {
        // NSLog("(\(identifier)) HR notification: \(data.hr) rrs: \(data.rrs) rrsMs: \(data.rrsMs) c: \(data.contact) s: \(data.contactSupported)")
        let result: NSMutableDictionary = [:]

        result["id"] = identifier
        result["hr"] = data.hr
        result["contact"] = data.contact
        result["contactSupported"] = data.contactSupported
        // no rrAvailable property for ios (android only ?)

        let rrs: NSMutableArray = []
        for item in data.rrs {
            rrs.add(item)
        }
        result["rrs"] = rrs

        let rrsMs: NSMutableArray = []
        for item in data.rrsMs {
            rrsMs.add(item)
        }
        result["rrsMs"] = rrsMs

        self.sendEvent(withName: "hrData", body: result)
    }
    
    func hrFeatureReady(_ identifier: String) {
        // NSLog("HR READY")
        self.sendEvent(withName: "hrFeatureReady", body: ["id": identifier])
    }
    
    // PolarBleApiDeviceEcgObserver
    func ecgFeatureReady(_ identifier: String) {
        // NSLog("ECG READY \(identifier)")
        self.sendEvent(withName: "ecgFeatureReady", body: ["id": identifier])
    }
    
    // PolarBleApiDeviceAccelerometerObserver
    func accFeatureReady(_ identifier: String) {
        // NSLog("ACC READY")
        self.sendEvent(withName: "accelerometerFeatureReady", body: ["id": identifier])
    }
    
    func ohrPPGFeatureReady(_ identifier: String) {
        // NSLog("OHR PPG ready")
        self.sendEvent(withName: "ppgFeatureReady", body: ["id": identifier])
    }
    
    // PolarBleApiPowerStateObserver
    func blePowerOn() {
        // NSLog("BLE ON")
        self.sendEvent(withName: "blePower", body: ["id": deviceId, "state": true])
    }
    
    func blePowerOff() {
        // NSLog("BLE OFF")
        self.sendEvent(withName: "blePower", body: ["id": deviceId, "state": false])
    }
    
    // PPI
    func ohrPPIFeatureReady(_ identifier: String) {
        // NSLog("PPI Feature ready")
        self.sendEvent(withName: "ppiFeatureReady", body: ["id": identifier])
    }

    func ftpFeatureReady(_ identifier: String) {
        // NSLog("FTP ready")
    }
    
    func message(_ str: String) {
        // NSLog(str)
    }
    
    /// ccc write observer
    func cccWrite(_ address: UUID, characteristic: CBUUID) {
        // NSLog("ccc write: \(address) chr: \(characteristic)")
    }
}


/*
@objc class PolarBroadcastData : NSObject {
    let name: String
    let hr: Int
    let battery: Bool
    
    init(_ name: String, hr: Int, battery: Bool){
        self.name = name
        self.hr = hr
        self.battery = battery
    }
}

@objc class PolarSensorSettings: NSObject {
    let settings: PolarSensorSetting
    
    init(_ settings: PolarSensorSetting) {
        self.settings = settings
    }
}

@objc class AccData: NSObject {
    let timeStamp: UInt64
    let samples: [(Int32,Int32,Int32)]
    
    init(_ timeStamp: UInt64, samples: [(Int32,Int32,Int32)]) {
        self.timeStamp = timeStamp
        self.samples = samples
    }
}

@objc class PpgData: NSObject {
    let timeStamp: UInt64
    let samples: [(Int32,Int32,Int32,Int32)]
    
    init(_ timeStamp: UInt64, samples: [(Int32,Int32,Int32,Int32)]) {
        self.timeStamp = timeStamp
        self.samples = samples
    }
}

@objc class PolarDisposable: NSObject {
    var disposable: Disposable?
    init(_ disposable: Disposable?) {
        self.disposable = disposable
    }
    
    @objc func dispose() {
        self.disposable?.dispose()
        self.disposable = nil
    }
}

@objc class ApiWrapperSwift: NSObject {
    var api: PolarBleApi
    var broadcast: Disposable?
    var autoConnect: Disposable?

    override init() {
        self.api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Features.allFeatures.rawValue);
    }
    
    @objc func startListenPolarHrBroadcast(_ next: @escaping (PolarBroadcastData) -> Void) {
        stopListenPolarHrBroadcast()
        broadcast = self.api.startListenForPolarHrBroadcasts(nil).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .completed:
                break
            case .error(let err):
                print("\(err)")
            case .next(let value):
                next(PolarBroadcastData(value.deviceInfo.name, hr: Int(value.hr), battery: value.batteryStatus))
            }
        }
    }
    
    @objc func stopListenPolarHrBroadcast() {
        broadcast?.dispose()
        broadcast = nil
    }
    
    
    @objc func startAutoConnectToPolarDevice(_ rssi: Int, polarDeviceType: String?) {
        stopAutoConnectToPolarDevice()
        autoConnect = self.api.startAutoConnectToDevice(rssi, service: nil, polarDeviceType: polarDeviceType).subscribe()
    }
    
    @objc func stopAutoConnectToPolarDevice() {
        autoConnect?.dispose()
        autoConnect = nil
    }
    
    @objc func connectToPolarDevice(_ identifier: String) {
        do{
            try self.api.connectToDevice(identifier)
        } catch {}
    }
    
    @objc func disconnectFromPolarDevice(_ identifier: String) {
        do{
            try self.api.disconnectFromDevice(identifier)
        } catch {}
    }
    
    @objc func isFeatureReady(_ identifier: String, feature: Int) -> Bool {
        return self.api.isFeatureReady(identifier, feature: Features.init(rawValue: feature) ?? Features.allFeatures)
    }
    
    @objc func setLocalTime(_ identifier: String, time: Date, success: @escaping () -> Void, error: @escaping (Error) -> Void ) {
        _ = api.setLocalTime(identifier, time: time, zone: TimeZone.current).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .completed:
                success()
            case .error(let err):
                error(err)
            }
        }
    }
    
    @objc func startRecording(_ identifier: String, exerciseId: String, interval: Int, sampleType: Int, success: @escaping () -> Void, error: @escaping (Error) -> Void ) {
        _ = api.startRecording(identifier, exerciseId: exerciseId, interval: RecordingInterval.init(rawValue: interval) ?? RecordingInterval.interval_5s, sampleType: SampleType.init(rawValue: sampleType) ?? SampleType.hr).observeOn(MainScheduler.instance).subscribe { e in
            switch e {
            case .completed:
                success()
            case .error(let err):
                error(err)
            }
        }
    }
    
    @objc func stopRecording(_ identifier: String, success: @escaping () -> Void, error: @escaping (Error) -> Void ) {
        _ = api.stopRecording(identifier).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .completed:
                success()
            case .error(let err):
                error(err)
            }
        }
    }
    
    @objc func requestRecordingStatus(_ identifier: String, success:@escaping (Bool,String) -> Void, error: @escaping (Error) -> Void ) {
        _ = api.requestRecordingStatus(identifier).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .error(let err):
                error(err)
            case .success(let value):
                success(value.ongoing,value.entryId)
            }
        }
    }
    
    @objc func requestEcgSettings(_ identifier: String, success: @escaping ((PolarSensorSettings)) -> Void, error: @escaping (Error) -> Void ) {
        _ = api.requestEcgSettings(identifier).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .error(let err):
                error(err)
            case .success(let value):
                success(PolarSensorSettings(value))
            }
        }
    }
    
    @objc func requestAccSettings(_ identifier: String, success: @escaping ((PolarSensorSettings)) -> Void, error: @escaping (Error) -> Void ) {
        _ = api.requestAccSettings(identifier).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .error(let err):
                error(err)
            case .success(let value):
                success(PolarSensorSettings(value))
            }
        }
    }
    
    @objc func requestPpgSettings(_ identifier: String, success: @escaping ((PolarSensorSettings)) -> Void, error: @escaping (Error) -> Void ) {
        _ = api.requestPpgSettings(identifier).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .error(let err):
                error(err)
            case .success(let value):
                success(PolarSensorSettings(value))
            }
        }
    }
    
    @objc func startEcgStreaming(_ identifier: String, settings: PolarSensorSettings, next: @escaping (UInt64,[Int32]) -> Void, error: @escaping (Error) -> Void ) -> PolarDisposable {
        return PolarDisposable(api.startEcgStreaming(identifier, settings: settings.settings.maxSettings()).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .completed:
                break
            case .error(let err):
                error(err)
            case .next(let value):
                next(value.timeStamp, value.samples)
            }
        })
    }
    
    @objc func startAccStreaming(_ identifier: String, settings: PolarSensorSettings, next: @escaping ((AccData)) -> Void, error: @escaping (Error) -> Void ) -> PolarDisposable {
        return PolarDisposable(api.startAccStreaming(identifier, settings: settings.settings.maxSettings()).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .completed:
                break
            case .error(let err):
                error(err)
            case .next(let value):
                next(AccData.init(value.0, samples: value.1))
            }
        })
    }
    
    @objc func startOhrPPGStreaming(_ identifier: String, settings: PolarSensorSettings, next: @escaping ((PpgData)) -> Void, error: @escaping (Error) -> Void ) -> PolarDisposable {
        return PolarDisposable(api.startOhrPPGStreaming(identifier, settings: settings.settings.maxSettings()).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .completed:
                break
            case .error(let err):
                error(err)
            case .next(let value):
                next(PpgData.init(value.0, samples: value.1))
            }
        })
    }

    @objc func startOhrPPIStreaming(_ identifier: String, next: @escaping (UInt64,[UInt16]) -> Void, error: @escaping (Error) -> Void ) -> PolarDisposable {
        return PolarDisposable(api.startOhrPPIStreaming(identifier).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .completed:
                break
            case .error(let err):
                error(err)
            case .next(let value):
                let samples = value.1.compactMap({ (sample) -> UInt16 in
                    sample.ppInMs
                })
                next(value.0,samples)
            }
        })
    }

    @objc func fetchStoredExerciseList(_ identifier: String, next: @escaping (String,Date,String) -> Void, error: @escaping (Error) -> Void ) {
        _ = api.fetchStoredExerciseList(identifier).observeOn(MainScheduler.instance).subscribe { e in
            switch e {
            case .completed:
                break
            case .next(let entry):
                next(entry.path,entry.date,entry.entryId)
            case .error(let err):
                error(err)
            }
        }
    }

    @objc func fetchExercise(_ identifier: String, path: String, date: Date, entryId: String, success: @escaping (UInt32,[UInt32]) -> Void, error: @escaping (Error) -> Void ) {
        _ = api.fetchExercise(identifier, entry: (path, date: date, entryId: entryId)).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .error(let err):
                error(err)
            case .success(let value):
                success(value.interval,value.samples)
            }
        }
    }

    @objc func removeExercise(_ identifier: String, path: String, date: Date, entryId: String, success: @escaping () -> Void, error: @escaping (Error) -> Void ) {
        _ = api.removeExercise(identifier, entry: (path, date: date, entryId: entryId)).observeOn(MainScheduler.instance).subscribe{ e in
            switch e {
            case .completed:
                success()
            case .error(let err):
                error(err)
            }
        }
    }
}
*/