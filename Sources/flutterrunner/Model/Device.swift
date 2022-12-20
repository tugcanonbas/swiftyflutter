//
//  Device.swift
//  flutterrunner
//
//  Created by Tuğcan ÖNBAŞ on 20.12.2022.
//

import Foundation

class Device {
  let name: String
  let id: String
  let isSupported: Bool
  let targetPlatform: TargetPlatform
  let emulator: Bool
  let sdk: String
  let capabilities: Capabilities
  let isFavorite: Bool
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
    process?.launchPath = "/usr/bin/env"

    process?.arguments = ["open", "-a", "Simulator", "--args", "-CurrentDeviceUDID", self.id]

    process?.launch()
    // process?.waitUntilExit()
    // process?.terminate()
    // self.process = nil
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
