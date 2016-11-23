//
//  ViewController.swift
//  BLEApp
//
//  Created by Yevhen Kim on 2016-11-21.
//  Copyright © 2016 Yevhen Kim. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    //declare UI variables for view controller
    var titleLabel:  UILabel = UILabel()
    var statusLabel: UILabel = UILabel()
    var tempLabel:   UILabel = UILabel()
    
    //declare BLE variables
    var manager:    CBCentralManager!
    var sensorPeripheral: CBPeripheral!
    
    //declare BLE name and service constant, check GATT for more services
//    let BLE_NAME = ""
//    let BLE_SCRATCH_UUID = UIDevice.current.identifierForVendor!.uuidString
//    let BLE_SERVICE_UUID = CBUUID(string: UIDevice.current.identifierForVendor!.uuidString)
//    
    // IR Temp UUIDs check GATT for more services
    let TEMP_ServiceUUID = CBUUID(string: "F000AA00-0451-4000-B000-000000000000")
    let TEMP_DataUUID    = CBUUID(string: "F000AA01-0451-4000-B000-000000000000")
    let TEMP_ConfigUUID  = CBUUID(string: "F000AA02-0451-4000-B000-000000000000")

    //declare instance of stylesheet class
    let stylesheet: Stylesheet = Stylesheet.sharedInstance
    
//: pragma mark viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup title label
        titleLabel.text = "My sensor tag"
        titleLabel.font = stylesheet.titleText
        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: self.view.frame.midX, y: self.titleLabel.bounds.midY + 28)
        self.view.addSubview(titleLabel)
        
        //setup status label
        statusLabel.textAlignment = stylesheet.centerAlignmant
        statusLabel.text = "Loading..."
        statusLabel.font = stylesheet.subTitleText
        statusLabel.sizeToFit()
        statusLabel.frame = CGRect(x: self.view.frame.origin.x, y: self.titleLabel.frame.maxY, width: self.view.frame.width, height: self.statusLabel.bounds.height)
        self.view.addSubview(statusLabel)
        
        //setup temperature label
        tempLabel.text = "00"
        tempLabel.font = stylesheet.bigText
        tempLabel.sizeToFit()
        tempLabel.center = self.view.center
        self.view.addSubview(tempLabel)
        
        //initialize central manager on load
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    //check hardware BLE status
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil, options: nil)
            self.statusLabel.text = "Searching for BLE Devices"
        case .poweredOff:
            //FIXME change for something meaningful
            print("Bluetooth on this device is currently powered off")
        case .unsupported:
            //FIXME change for something meaningful
            print("This device does not support Bluetooth Low Energy")
        case .unauthorized:
            //FIXME change for something meaningful
            print("This app is not authorized to use Bluetooth Low Energy")
        case .resetting:
            //FIXME change for something meaningful
            print("The BLE Manager is resetting; a state update is pending")
        case .unknown:
            //FIXME change for something meaningful
            print("The state of the BLE Manager is unknown")
            self.statusLabel.text = "Sensor Tag NOT Found"
        }
    }

    //did descover peripherial
    @nonobjc func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : AnyObject], rssi RSSI: NSNumber) {
        let deviceName = "SensorTag"
        let nameOfDeviceFound = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? String
        if (nameOfDeviceFound == deviceName) {
            //update status label
            self.statusLabel.text = "Sensor Tag Found"
            //stop scanning
            self.manager.stopScan()
            
            //set as perepherial to use and establish connection
            self.sensorPeripheral = peripheral
            self.sensorPeripheral.delegate = self
            self.manager.connect(peripheral, options: nil)
        }
        else {
            self.statusLabel.text = "Sensor Tag Not Found"
        }
        
    }
    
    //connection to a peripheral
    //discover services of the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.statusLabel.text = "Discovering peripheral services"
        peripheral.discoverServices(nil)
    }
    
    //check for validation of discovered service against TEMP_ServiceUUID
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.statusLabel.text = "Looking at peripheral services"
        for service in peripheral.services! {
            let lookingService = service as CBService
            if service.uuid == TEMP_ServiceUUID {
                //dicrover characteristics of IR Temperature Service
                peripheral.discoverCharacteristics(nil, for: lookingService)
            }
            //list of UUIDs
            print(lookingService.uuid)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //update status label
        self.statusLabel.text = "Enabling sensor"
        
        //0x01 data byte to enable sensor
        var enableValue = 1
        //in swift 3 sizeof(UInt8) changed to MemoryLayout<UInt8>.size
        let enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)
        
        //check the uuid of each characteristic to find config and data characteristics
        for characteristic in service.characteristics! {
            let lookingCharacteristic = characteristic as CBCharacteristic
            //check against  data  uuid
            if lookingCharacteristic.uuid == TEMP_DataUUID {
                //enable sensor notification
                self.sensorPeripheral.setNotifyValue(true, for: lookingCharacteristic)
            }
            //check for config characteristic
            if lookingCharacteristic.uuid == TEMP_ConfigUUID {
                //enable sensor
                self.sensorPeripheral.writeValue(enableBytes as Data, for: lookingCharacteristic, type: .withResponse)
            }
        }
    }
    
    //get data value when they are updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        self.statusLabel.text = "Connected"
        
        if characteristic.uuid == TEMP_DataUUID {
            //convert NSData to array of signed 16 bit values
            let dataBytes = characteristic.value
            let dataLength = dataBytes?.count
            var dataArray = [UInt8](repeating: 0, count: dataLength!)
            //swift 3 for Data getBytes changed to copyBytes
            dataBytes?.copyBytes(to: &dataArray, count: dataLength! * MemoryLayout<UInt16>.size)
            
            //element 1 of the array will be ambient temparature raw value
            let ambientTemp = Double(dataArray[1])/128
            self.tempLabel.text = String(format: "\(ambientTemp)")
        }
    }
    
    //if disconnected, start searching again
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.statusLabel.text = "Disconnected"
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
}

