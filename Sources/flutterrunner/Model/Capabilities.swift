//
//  Capabilities.swift
//  flutterrunner
//
//  Created by Tuğcan ÖNBAŞ on 20.12.2022.
//

import Foundation

struct Capabilities {
  let hotReload: Bool
  let hotRestart: Bool
  let screenshot: Bool
  let fastStart: Bool
  let flutterExit: Bool
  let hardwareRendering: Bool
  let startPaused: Bool

  static func empty() -> Capabilities {
    return Capabilities(
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
