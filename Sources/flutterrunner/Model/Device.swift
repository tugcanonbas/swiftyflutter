//
//  Device.swift
//  flutterrunner
//
//  Created by Tuğcan ÖNBAŞ on 20.12.2022.
//

import Foundation

class Device {
  var name: String
  var id: String
  var isSupported: Bool
  var targetPlatform: TargetPlatform
  var emulator: Bool
  var emulatorName: String
  var sdk: String
  var capabilities: Capabilities
  var isFavorite: Bool
  var isBooted: Bool
  var process: Process?
  var pipe: Pipe?

  init(
    name: String, id: String, isSupported: Bool, targetPlatform: TargetPlatform, emulator: Bool,
    sdk: String, capabilities: Capabilities, isFavorite: Bool = false, isBooted: Bool = false
  ) {
    self.name = name
    self.id = id
    self.isSupported = isSupported
    self.targetPlatform = targetPlatform
    self.emulator = emulator
    self.emulatorName = ""
    self.sdk = sdk
    self.capabilities = capabilities
    self.isBooted = isBooted
    self.isFavorite = isFavorite

    self.process = nil
    self.pipe = nil
  }

  func runApp() {
    //TODO: - Chec is current working directory is a flutter project
    self.process = Process()
    process?.launchPath = "/usr/bin/env"
    self.pipe = Pipe()
    process?.standardInput = pipe

    process?.arguments = ["flutter", "run", "-d", self.id]
  }

  func stop() {
    self.process?.terminate()
    self.process = nil
    self.pipe = nil
  }

  func boot() {
    self.process = Process()
    self.pipe = Pipe()
    process?.standardOutput = pipe
    process?.launchPath = "/usr/bin/env"

    if self.targetPlatform == .ios {
      process?.arguments = ["xcrun", "simctl", "bootstatus", self.id, "-b"]
    } else if self.targetPlatform == .android {
      //TODO: - Boot all android devices
      process?.arguments = [""]
    }

    process?.launch()
    process?.waitUntilExit()
    process?.terminate()
    self.process = nil
    self.pipe = nil
  }

  func toString() -> String {
    return """
      Name: \(self.name)
      ID: \(self.id)
      Target Platform: \(self.targetPlatform)
      Emulator: \(self.emulator)
      SDK: \(self.sdk)
      Booted: \(self.isBooted)
      """
  }
}
