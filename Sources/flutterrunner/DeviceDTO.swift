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
  let capabilities: Capabilities

  static func fromJSON(_ data: Data) -> [DeviceDTO]? {
    return try? JSONDecoder().decode([DeviceDTO].self, from: data)
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

struct Capabilities: Decodable {
  let hotReload: Bool
  let hotRestart: Bool
  let screenshot: Bool
  let fastStart: Bool
  let flutterExit: Bool
  let hardwareRendering: Bool
  let startPaused: Bool
}
