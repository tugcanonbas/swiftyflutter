//
//  DeviceManager.swift
//  flutterrunner
//
//  Created by Tuğcan ÖNBAŞ on 20.12.2022.
//

import Foundation

class DeviceManager {
  var availableDevices = [Device]()
  var favorites = [Device]()
  var processes = [Process]()
  var pipes = [Pipe]()

  let shared = DeviceManager()

  private init() {
    self.availableDevices = []
    self.favorites = []
    self.processes = []
    self.pipes = []
  }

  private func fetchAvailableDevices() {
    let devicesProcess = Process()
    devicesProcess.launchPath = "/usr/bin/env"
    let pipe = Pipe()
    // pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    devicesProcess.standardOutput = pipe
    devicesProcess.standardError = pipe
    devicesProcess.arguments = ["flutter", "devices", "--machine"]
    devicesProcess.launch()
    devicesProcess.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    pipe.fileHandleForReading.closeFile()
    devicesProcess.terminate()

    guard let devices = Device.fromJSON(data) else {
      print("Could not parse devices")
      return
    }

    self.availableDevices = devices
  }

  func getAvailableDevices() -> [Device] {
    return self.availableDevices
  }
}
