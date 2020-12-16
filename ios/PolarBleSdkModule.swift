import Foundation
import PolarBleSdk
import RxSwift
import CoreBluetooth

struct Device {
    var hrReady: Bool = false
    var ecgReady: Bool = false
    var accReady: Bool = false
    var ppgReady: Bool = false
    var ppiReady: Bool = false
    var broadcast: Disposable?
    var ecgToggle: Disposable?
    var accToggle: Disposable?
    var ppgToggle: Disposable?
    var ppiToggle: Disposable?
    var searchToggle: Disposable?
    var autoConnect: Disposable?
    var entry: PolarExerciseEntry?
}

@objc(PolarBleSdkModule)
class PolarBleSdkModule : RCTEventEmitter,
                          PolarBleApiObserver,
                          PolarBleApiPowerStateObserver,
                          PolarBleApiDeviceInfoObserver,
                          PolarBleApiDeviceFeaturesObserver,
                          PolarBleApiDeviceHrObserver,
                          PolarBleApiCCCWriteObserver,
                          PolarBleApiLogger {

    public static var emitter : RCTEventEmitter!

    // var api: PolarBleApi = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Features.allFeatures.rawValue);
    var api: PolarBleApi! = nil
    /*
    var broadcast: Disposable?
    var ecgToggle: Disposable?
    var accToggle: Disposable?
    var ppgToggle: Disposable?
    var ppiToggle: Disposable?
    var searchToggle: Disposable?
    var autoConnect: Disposable?
    var entry: PolarExerciseEntry?
    var deviceId = "0A3BA92B" // TODO replace this with your device id
    */

    /*
    var devices: [String: [
        "hrReady": Bool,
        "ecgReady": Bool,
        "accReady": Bool,
        "ppgReady": Bool,
        "ppiReady": Bool,
        "ecgToggle": Disposable,
        "accToggle": Disposable,
        "ppgToggle": Disposable,
        "ppiToggle": Disposable
    ]] = [:]
    */

    var devices: [String: Device] = [:]

    override init() {
        super.init()
        PolarBleSdkModule.emitter = self

        api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Features.allFeatures.rawValue);
        // guard api != nil else { return }
        api.observer = self
        api.powerStateObserver = self
        api.deviceInfoObserver = self
        api.deviceFeaturesObserver = self
        api.deviceHrObserver = self
        api.cccWriteObserver = self
        api.logger = self

        api.polarFilter(false)
        // NSLog("\(PolarBleApiDefaultImpl.versionInfo())")
    }

    override func supportedEvents() -> [String]! {
        return [
            "blePower",
            "connectionState",
            "hrFeatureReady",
            "ecgFeatureReady",
            "accelerometerFeatureReady",
            "ppgFeatureReady",
            "ppiFeatureReady",
            "firmwareVersion",
            "batteryLevel",
            "hrData",
            "ecgData",
            "accData",
            "ppgData",
            "ppiData"
        ]
    }

    override static func requiresMainQueueSetup() -> Bool {
        return false // module doesn't rely on UIKit, see https://reactnative.dev/docs/native-modules-ios
    }

    @objc func connectToDevice(_ id: String) -> Void {
        // deviceId = id
        self.sendEvent(withName: "connectionState", body: ["id": id, "state": "scanning"])
        do {
            try self.api.connectToDevice(id)
        } catch {
            self.sendEvent(withName: "connectionState", body: ["id": id, "state": "disconnected"])
        }
    }

    @objc func disconnectFromDevice(_ id: String) -> Void {
        // deviceId = id
        self.sendEvent(withName: "connectionState", body: ["id": id, "state": "disconnecting"])
        do {
            try self.api.disconnectFromDevice(id)
        } catch {
            // e.g. if we are not already connected
            self.sendEvent(withName: "connectionState", body: ["id": id, "state": "disconnected"])
        }
    }

    // @objc func startEcgStreaming() -> Void {
    @objc func startEcgStreaming(_ id: String) -> Void {
        // let id: String = deviceId
        let d = devices[id]
        if d != nil && d.ecgReady && d.ecgToggle == nil {
            d.ecgToggle = api.requestEcgSettings(id).asObservable().flatMap({ (settings) -> Observable<PolarEcgData> in
                return self.api.startEcgStreaming(id, settings: settings.maxSettings())
            }).observeOn(MainScheduler.instance).subscribe{ e in
                switch e {
                case .next(let data):
                    let result: NSMutableDictionary = [:]
                    result["id"] = id
                    result["timeStamp"] = data.timeStamp
                    let samples: NSMutableArray = []
                    for µv in data.samples {
                        // NSLog("    µV: \(µv)")
                        samples.add(µv)
                    }
                    result["samples"] = samples
                    self.sendEvent(withName: "ecgData", body: result)
                case .error(let err):
                    NSLog("start ecg error: \(err)")
                    // self.ecgToggle = nil
                    d.ecgToggle = nil
                case .completed:
                    break
                }
            }
        }
    }

    @objc func stopEcgStreaming(_ id: String) -> Void {
        let d = devices[id]
        if d != nil && d.ecgReady && d.ecgToggle != nil {
            d.ecgToggle?.dispose()
            d.ecgToggle = nil
        }
    }

    @objc func startAccStreaming(_ id: String) -> Void {
        // let identifier: String = deviceId
        let d = devices[id]
        if d != nil && d.accready && d.accToggle == nil {
            d.accToggle = api.requestAccSettings(id).asObservable().flatMap({ (settings) -> Observable<PolarAccData> in
                // NSLog("settings: \(settings.settings)")
                return self.api.startAccStreaming(id, settings: settings.maxSettings())
            }).observeOn(MainScheduler.instance).subscribe{ e in
                switch e {
                case .next(let data):
                    let result: NSMutableDictionary = [:]
                    result["id"] = id
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
                    NSLog("start accelerometer error: \(err)")
                    // self.accToggle = nil
                    d.accToggle = nil
                case .completed:
                    break
                }
            }
        }
    }

    @objc func stopAccStreaming(_ id: String) -> Void {
        let d = devices[id]
        if d != nil && d.accReady && d.accToggle != nil {
            d.accToggle?.dispose()
            d.accToggle = nil            
        }
    }

    @objc func startPpgStreaming(_ id: String) -> Void {
        // let identifier: String = deviceId
        let d = devices[id]
        if d != nil && d.ppgReady && d.ppgToggle == nil {
            d.ppgToggle = api.requestPpgSettings(id).asObservable().flatMap({ (settings) -> Observable<PolarPpgData> in
                return self.api.startOhrPPGStreaming(id, settings: settings.maxSettings())
            }).observeOn(MainScheduler.instance).subscribe{ e in
                switch e {
                case .completed:
                    // NSLog("ppg finished")
                    break
                case .error(let err):
                    NSLog("start ppg error: \(err)")
                    // self.ppgToggle = nil
                    d.ppgToggle = nil
                case .next(let data):
                    let result: NSMutableDictionary = [:]
                    result["id"] = id
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

    @objc func stopPpgStreaming(_ id: String) -> Void {
        let d = devices[id]
        if d != nil && d.ppgReady && d.ppgToggle != nil {
            d.ppgToggle?.dispose()
            d.ppgToggle = nil        
        }
    }

    @objc func startPpiStreaming(_ id: String) -> Void {
        // let identifier: String = deviceId
        let d = devices[id]
        if d != nil && d.ppiReady && d.ppiToggle == nil {
            d.ppiToggle = api.startOhrPPIStreaming(id).observeOn(MainScheduler.instance).subscribe { e in
                switch e {
                case .completed:
                    // NSLog("ppi complete")
                    break
                case .error(let err):
                    NSLog("start ppi error: \(err)")
                    // self.ppiToggle = nil
                    d.ppiToggle = nil
                case .next(let data):
                    let result: NSMutableDictionary = [:]
                    result["id"] = id
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
                        */
                        samples.add(item)
                    }
                    result["samples"] = samples
                    self.sendEvent(withName: "ppiData", body: result)
                }
            }
        }
    }

    @objc func stopPpiStreaming(_ id: String) -> Void {
        if d != nil && d.ppiReady && d.ppiToggle != nil {
            d.ppiToggle?.dispose()
            d.ppiToggle = nil
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
        id = polarDeviceInfo.deviceId
        // self.devices.insert(id)
        self.devices[id] = Device()
        self.sendEvent(withName: "connectionState", body: ["id": id, "state": "connected"])
    }
    
    func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo) {
        // NSLog("DISCONNECTED: \(polarDeviceInfo)")
        id = polarDeviceInfo.deviceId
        // self.devices.remove(id)
        self.devices[id] = nil
        self.sendEvent(withName: "connectionState", body: ["id": id, "state": "disconnected"])
    }
    
    // PolarBleApiDeviceInfoObserver
    func batteryLevelReceived(_ id: String, batteryLevel: UInt) {
        // NSLog("battery level updated: \(batteryLevel)")
        self.sendEvent(withName: "batteryLevel", body: ["id": id, "value": batteryLevel])
    }
    
    func disInformationReceived(_ id: String, uuid: CBUUID, value: String) {
        // NSLog("dis info: \(uuid.uuidString) value: \(value)")
        if uuid.uuidString == "00002a28-0000-1000-8000-00805f9b34fb" {
            let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
            self.sendEvent(withName: "firmwareVersion", body: ["id": id, "value": v])
        }
    }
    
    // PolarBleApiDeviceHrObserver
    func hrValueReceived(_ id: String, data: PolarHrData) {
        // NSLog("(\(identifier)) HR notification: \(data.hr) rrs: \(data.rrs) rrsMs: \(data.rrsMs) c: \(data.contact) s: \(data.contactSupported)")
        let result: NSMutableDictionary = [:]

        result["id"] = id
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
    
    func hrFeatureReady(_ id: String) {
        // NSLog("HR READY")
        devices[id].hrReady = true
        self.sendEvent(withName: "hrFeatureReady", body: ["id": id])
    }
    
    // PolarBleApiDeviceEcgObserver
    func ecgFeatureReady(_ id: String) {
        // NSLog("ECG READY \(identifier)")
        devices[id].ecgReady = true
        self.sendEvent(withName: "ecgFeatureReady", body: ["id": id])
    }
    
    // PolarBleApiDeviceAccelerometerObserver
    func accFeatureReady(_ id: String) {
        // NSLog("ACC READY")
        devices[id].accReady = true
        self.sendEvent(withName: "accelerometerFeatureReady", body: ["id": id])
    }
    
    func ohrPPGFeatureReady(_ id: String) {
        // NSLog("OHR PPG ready")
        devices[id].ppgReady = true
        self.sendEvent(withName: "ppgFeatureReady", body: ["id": id])
    }
    
    // PPI
    func ohrPPIFeatureReady(_ id: String) {
        // NSLog("PPI Feature ready")
        devices[id].ppiReady = true
        self.sendEvent(withName: "ppiFeatureReady", body: ["id": id])
    }

    // PolarBleApiPowerStateObserver
    func blePowerOn() {
        // NSLog("BLE ON")
        // self.sendEvent(withName: "blePower", body: ["id": deviceId, "state": true])
    }
    
    func blePowerOff() {
        // NSLog("BLE OFF")
        // self.sendEvent(withName: "blePower", body: ["id": deviceId, "state": false])
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
