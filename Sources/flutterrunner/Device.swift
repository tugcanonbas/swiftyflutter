//
//  Device.swift
//  flutterrunner
//
//  Created by Tuğcan ÖNBAŞ on 20.12.2022.
//

import Foundation

struct Device {
  let name: String
  let id: String
  let isSupported: Bool
  let targetPlatform: DeviceType
  let emulator: Bool
  let sdk: String
  let capabilities: Capabilities
}
