//
//  TargetPlatform.swift
//  flutterrunner
//
//  Created by Tuğcan ÖNBAŞ on 20.12.2022.
//

import Foundation

enum TargetPlatform: String, CaseIterable {
  case android
  case ios
  case web
  case linux
  case macos
  case windows
  case unknown

  var isMobile: Bool {
    return self == .android || self == .ios
  }

  var isDesktop: Bool {
    return self == .linux || self == .macos || self == .windows
  }

  var isWeb: Bool {
    return self == .web
  }
}