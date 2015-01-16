//
//  BTLE.swift
//  SwiftHRM
//
//  Created by Tim Fenton on 1/13/15.
//  Copyright (c) 2015 Tim Fenton. All rights reserved.
//

import Foundation
import CoreBluetooth

class BTLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var central = CBCentralManager()
    var discoveredPeripheral:CBPeripheral?
    
    let hrmServiceUUID = CBUUID.init( string:"180D" )
    //let scratchCharUUID = CBUUID.init( string:"A495FF21-C5B1-4B44-B512-1370F02D74DE" )
    
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }
    
    /////////////////////////////////////////////////////////////////
    // callback: called when a peripheral is discovered
    /////////////////////////////////////////////////////////////////
    func centralManager(central: CBCentralManager!,
        didDiscoverPeripheral peripheral: CBPeripheral!,
        advertisementData: [NSObject : AnyObject]!,
        RSSI: NSNumber!) {
            
            //if( peripheral.name != nil && peripheral.name == "Bean")
            if true
            {
                central.connectPeripheral(peripheral, options: nil)
                
                // We have to set the discoveredPeripheral var we declared earlier to reference the peripheral, otherwise we won't be able to interact with it in didConnectPeripheral. And you will get state = connecting> is being dealloc'ed while pending connection error.
                
                self.discoveredPeripheral = peripheral
                
                // Hardware beacon
                println("PERIPHERAL NAME: \(peripheral.name)\n AdvertisementData: \(advertisementData)\n RSSI: \(RSSI)\n")
                
                println("UUID DESCRIPTION: \(peripheral.identifier.UUIDString)\n")
                
                println("IDENTIFIER: \(peripheral.identifier)\n")
                
                println( "FOUND PERIPHERALS: \(peripheral) AdvertisementData: \(advertisementData) RSSI: \(RSSI)\n" )
                
                // stop scanning, saves the battery
                central.stopScan()
            }
            
    }
    
    /////////////////////////////////////////////////////////////////
    // callback: called when a peripheral connects
    /////////////////////////////////////////////////////////////////
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        
        peripheral.delegate = self
        peripheral.discoverServices(nil )
        
        println("Connected to peripheral")
        var outputStr : String
        outputStr = "Name: " + peripheral.name
        outputStr = "\(outputStr)\nID: "
        outputStr = outputStr + peripheral.identifier.UUIDString
        println( outputStr )
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println( "FAILED TO CONNECT \(error)" )
    }
    
    /////////////////////////////////////////////////////////////////
    // callback: called with BT LE state changes
    /////////////////////////////////////////////////////////////////
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        
        switch central.state {
            
        case .PoweredOff:
            println("CoreBluetooth BLE hardware is powered off")
            break
        case .PoweredOn:
            println("CoreBluetooth BLE hardware is powered on and ready")
            let hrmUUID = CBUUID.init( string:"180D" )
            central.scanForPeripheralsWithServices([hrmUUID] , options: nil)
            break
        case .Resetting:
            println("CoreBluetooth BLE hardware is resetting")
            break
        case .Unauthorized:
            println("CoreBluetooth BLE state is unauthorized")
            break
        case .Unknown:
            println("CoreBluetooth BLE state is unknown")
            break
        case .Unsupported:
            println("CoreBluetooth BLE hardware is unsupported on this platform")
            break
        default:
            break
        }
    }
    
    /////////////////////////////////////////////////////////////////
    // callback: called when services are discovered on a peripheral
    /////////////////////////////////////////////////////////////////
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverServices error: NSError!) {
            
            if( error == nil)
            {
                for serv in peripheral.services
                {
                    //println(serv)
                    peripheral.discoverCharacteristics(nil, forService: serv as CBService)
                }
            }
    }
    
    /////////////////////////////////////////////////////////////////
    // callback: called when characterisics for a service are discovered
    /////////////////////////////////////////////////////////////////
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverCharacteristicsForService service: CBService!,
        error: NSError!)
    {
        if( error == nil )
        {
            for characteristic in service.characteristics
            {
                println("********FOUND CHARACTERISTIC:")
                println( characteristic )
                if( service.UUID == CBUUID.init( string:"A495FF20-C5B1-4B44-B512-1370F02D74DE"))
                {
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
                    peripheral.readValueForCharacteristic(characteristic as CBCharacteristic)
                }
                println(characteristic.UUID)
                if( characteristic.UUID == CBUUID.init( string:"2A37"))
                {
                    println("##Enabling read for 2A37")
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
                    peripheral.readValueForCharacteristic(characteristic as CBCharacteristic)
                }
                
            }
        }
    }
    
    /////////////////////////////////////////////////////////////////
    // callback: called when notifiactation state is changed from yes to no or vice versa
    /////////////////////////////////////////////////////////////////
    func peripheral(peripheral: CBPeripheral!,
        didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!){
            if( error == nil )
            {
                println( characteristic.value )
            }
    }
    
    /////////////////////////////////////////////////////////////////
    // callback: called when a notification is received from the peripheral
    // found notification center code here:
    //    http://dev.iachieved.it/iachievedit/nsnotifications-with-userinfo-in-swift/
    /////////////////////////////////////////////////////////////////
    func peripheral(peripheral: CBPeripheral!,
        didUpdateValueForCharacteristic characteristic: CBCharacteristic!,
        error: NSError!)
    {
        // Get the Heart Rate Monitor BPM
        let data = characteristic.value
        let reportData = UnsafePointer<UInt8>(data.bytes)
        var bpm : UInt16
        var rawByte : UInt8
        var outputString = ""
        rawByte = UInt8(reportData[0])
        bpm = 0
        
        if ((rawByte & 0x01) == 0) {          // 2
            // Retrieve the BPM value for the Heart Rate Monitor
            bpm = UInt16( reportData[1] )
        }
        else {
            bpm = CFSwapInt16LittleToHost(UInt16(reportData[1]))
        }
        
        outputString = String(bpm)
        //println(outputString)
        
        var dataDict = Dictionary<String, Int>()
        dataDict["HeartRate"] = Int(bpm)
        // and store the rssi
        peripheral.readRSSI()
        if peripheral.RSSI == nil {
            dataDict["RSSI"] = 0
        }
        else {
            dataDict["RSSI"] = Int(peripheral.RSSI)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(heartBeatKey, object:nil, userInfo:["heartRate" : String(bpm)] )
    }
}

