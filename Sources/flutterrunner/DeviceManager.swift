//
//  DeviceManager.swift
//  flutterrunner
//
//  Created by Tuğcan ÖNBAŞ on 20.12.2022.
//

import Foundation

enum DeviceManagerError: Error {
  case noDevicesFound
  case noUDIDFound
}

class DeviceManager {
  static let shared = DeviceManager()

  var availableDevices = [Device]()
  var favorites = [Device]()

  func test() {
    let devices = getAvailableDevices()
    print(devices)
  }

  private func getFlutterDevices() throws -> [Device] {
    let devicesProcess = Process()
    devicesProcess.launchPath = "/usr/bin/env"
    let pipe = Pipe()
    devicesProcess.standardOutput = pipe
    devicesProcess.standardError = pipe
    devicesProcess.arguments = ["flutter", "devices", "--machine"]
    devicesProcess.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    devicesProcess.waitUntilExit()
    pipe.fileHandleForReading.closeFile()
    devicesProcess.terminate()

    let devices = try JSONDecoder().decode([DeviceDTO].self, from: data).map {
      $0.toModel()
    }
    .filter { $0.targetPlatform.isMobile }

    devices.forEach { device in
      device.isBooted = true
      if device.targetPlatform == TargetPlatform.android {
        getAndroidEmulatorName(device)
      }
    }

    return devices
  }

  private func getAndroidEmulatorName(_ device: Device) {
    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = ["flutter", "emulators"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    guard let grepArguments = device.sdk.components(separatedBy: " ").last?.dropFirst().dropLast()
    else {
      return
    }

    let grepArgumentsString = String(grepArguments)

    process.arguments = ["flutter", "emulators", grepArgumentsString]

    process.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.terminate()

    guard let dataString = String(data: data, encoding: .utf8) else {
      return
    }

    device.emulatorName = dataString.components(separatedBy: " ")[0]
  }

  private func fetchIOSSimulators() throws -> [Device] {
    let process = Process()
    process.launchPath = "/usr/bin/env"
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    process.arguments = ["xcrun", "xctrace", "list", "devices"]

    process.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.terminate()

    guard let dataString = String(data: data, encoding: .utf8) else {
      throw DeviceManagerError.noDevicesFound
    }

    let lines = dataString.components(separatedBy: "\n")
    let iPhones = lines.filter { $0.contains("iPhone") }
    let simulators = iPhones.filter { $0.contains("Simulator") }

    let devices: [Device] = try simulators.map { line in
      let components = line.components(separatedBy: " ")
      let name = line.components(separatedBy: " Simulator")[0]
      guard let udid = components.last?.dropFirst().dropLast() else {
        throw DeviceManagerError.noUDIDFound
      }
      let isSupported = true
      let targetPlatform = TargetPlatform.ios
      let emulator = true
      let sdk = components[components.count - 2].dropFirst().dropLast()
      let capabilities = Capabilities.empty()

      let device = Device(
        name: name, id: String(udid), isSupported: isSupported, targetPlatform: targetPlatform,
        emulator: emulator, sdk: String(sdk), capabilities: capabilities)

      checkIsIOSDeviceIsBooted(device)

      return device
    }

    return devices
  }

  func checkIsIOSDeviceIsBooted(_ device: Device) {
    let process = Process()
    process.launchPath = "/usr/bin/env"
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    process.arguments = ["xcrun", "simctl", "bootstatus", device.id]

    process.launch()
    sleep(2)
    process.terminate()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    pipe.fileHandleForReading.closeFile()

    guard let dataString = String(data: data, encoding: .utf8) else {
      return
    }

    if dataString.contains("booted") {
      // print("Device is booted")
      device.isBooted = true
      return
    } else if dataString.contains("shutdown") {
      // print("Device is shutdown")
      device.isBooted = false
      return
    }
  }

  func getAvailableDevices() -> [Device] {
    var devices = [Device]()

    guard let iosSimulators = try? fetchIOSSimulators() else {
      print("No iOS simulators found")
      return []
    }
    guard let flutterDevices = try? getFlutterDevices() else {
      print("No flutter devices found")
      return []
    }

    devices.append(contentsOf: flutterDevices)

    for simulator in iosSimulators {
      if !devices.contains(where: { $0.id == simulator.id }) {
        devices.append(simulator)
      }
    }

    self.availableDevices = devices

    if self.availableDevices.isEmpty {
      print("No devices found")
      return []
    }

    print(
      """
      ==========================================================

      AVAILABLE DEVICES (\(self.availableDevices.count)):

      ==========================================================

      \(self.availableDevices.map { $0.toString() }.joined(separator: "\n\n============================\n\n"))

      ==========================================================
      """
    )

    return self.availableDevices
  }

  func bootAll(_ devices: [Device]) {
    // for device in devices {
    //   print("Booting \(device.name) (\(device.id))")
    //   device.boot()
    //   checkIsIOSDeviceIsBooted(device)
    //   print("Booted:\n\(device.toString())")
    // }
    // let process = Process()
    // process.launchPath = "/usr/bin/env"
    // process.arguments = ["open", "-a", "Simulator"]
    // process.launch()
    // process.waitUntilExit()
    // process.terminate()
    bootAndroidEmulators()
  }

  func bootAndroidEmulators() {
    let androidProcess = Process()
    let androidPipe = Pipe()
    androidProcess.standardOutput = androidPipe
    androidProcess.launchPath = "/usr/bin/env"
    // androidProcess.arguments = ["flutter", "emulators", "|", "grep", "• android"]
    androidProcess.arguments = ["flutter", "emulators"]
    androidProcess.launch()
    androidProcess.waitUntilExit()
    let data = androidPipe.fileHandleForReading.readDataToEndOfFile()
    androidPipe.fileHandleForReading.closeFile()
    androidProcess.terminate()

    guard let dataString = String(data: data, encoding: .utf8) else {
      print("No data found")
      return
    }

    let lines = dataString.components(separatedBy: "\n")
    let emulator = lines.filter { $0.contains("• android") }[0].components(separatedBy: " ")[0]

    let emulatorName = String(emulator)

    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = ["flutter", "emulators", "--launch", emulatorName]
    process.launch()
    process.waitUntilExit()
    process.terminate()

    sleep(3)

    print("Booted \(emulatorName)")

    let components = emulatorName.components(separatedBy: "_")
    guard let deviceName = components.last else {
      print("No device name found")
      return
    }

    let newName = "API \(deviceName)"

    //TODO: - NOTWORKING
    //TODO: - Check if device is booted
    //TODO: - Add device to available devices or update it

    guard let flutterDevices = try? getFlutterDevices() else {
      print("No flutter devices found")
      return
    }

    for device in flutterDevices {
      if device.sdk.contains(newName) {
        print("Booted:\n\(device.toString())")
        device.isBooted = true

        if !self.availableDevices.contains(where: { $0.id == device.id }) {
          print("Adding \(device.name) (\(device.id)) to available devices")
          self.availableDevices.append(device)
        } else {
          print("Updating \(device.name) (\(device.id)) in available devices")
          self.availableDevices = self.availableDevices.map { $0.id == device.id ? device : $0 }
        }
      }
    }
  }

  func stopAll() {
    for device in self.availableDevices {
      device.stop()
    }
  }
}
