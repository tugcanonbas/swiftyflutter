//
//  Device.swift
//  flutterrunner
//
//  Created by Tuğcan ÖNBAŞ on 20.12.2022.
//

import Foundation

struct DeviceDTO: Decodable {
  let name: String
  let id: String
  let isSupported: Bool
  let targetPlatform: String
  let emulator: Bool
  let sdk: String
  let capabilities: CapabilitiesDTO

  static func fromJSON(_ data: Data) -> [DeviceDTO]? {
    return try? JSONDecoder().decode([DeviceDTO].self, from: data)
  }

  func toModel() -> Device {

    let target =
      TargetPlatform.allCases.first(where: { $0.rawValue == self.targetPlatform }) ?? .unknown

    return Device(
      name: self.name,
      id: self.id,
      isSupported: self.isSupported,
      targetPlatform: target,
      emulator: self.emulator,
      sdk: self.sdk,
      capabilities: Capabilities(
        hotReload: self.capabilities.hotReload,
        hotRestart: self.capabilities.hotRestart,
        screenshot: self.capabilities.screenshot,
        fastStart: self.capabilities.fastStart,
        flutterExit: self.capabilities.flutterExit,
        hardwareRendering: self.capabilities.hardwareRendering,
        startPaused: self.capabilities.startPaused
      )
    )
  }

  func run() -> (Process, Pipe) {
    let process = Process()
    process.launchPath = "/usr/bin/env"
    let pipe = Pipe()
    // process.standardOutput = pipe
    // process.standardError = pipe
    process.standardInput = pipe

    process.arguments = ["flutter", "run", "-d", self.id]

    return (process, pipe)
  }
}

struct CapabilitiesDTO: Decodable {
  let hotReload: Bool
  let hotRestart: Bool
  let screenshot: Bool
  let fastStart: Bool
  let flutterExit: Bool
  let hardwareRendering: Bool
  let startPaused: Bool

  static func empty() -> CapabilitiesDTO {
    return CapabilitiesDTO(
      hotReload: false,
      hotRestart: false,
      screenshot: false,
      fastStart: false,
      flutterExit: false,
      hardwareRendering: false,
      startPaused: false
    )
  }
}
