import FileWatcher
import Foundation

@main
public struct flutterrunner {

  public static func main() {
    runsubs()
  }

  public static func runsubs() {
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

    var processes = [Process]()
    var pipes = [Pipe]()

    defer {
      processes.forEach { $0.terminate() }
    }

    devices.forEach { device in
      print("Device: \(device.name), \(device.targetPlatform), (\(device.id))")

      if device.targetPlatform.contains("ios") || device.targetPlatform.contains("android") {
        let (process, pipe) = device.run()
        processes.append(process)
        pipes.append(pipe)
      }
    }

    for process in processes {
      let tmpPipe = Pipe()
      process.standardOutput = tmpPipe

      process.launch()

      process.terminationHandler = { process in
        print("Process terminated: \(process.arguments![3])")
      }

      while true {
        let data = tmpPipe.fileHandleForReading.availableData
        if let string = String(data: data, encoding: .utf8) {
          // print(string)
          if string.contains("Running with sound null safety") {
            print("Running on \(process.arguments![3])")
            break
          }
        }
        sleep(2)
      }
    }

    print("Start watching files..")

    let filewatcher = FileWatcher([
      NSString(string: FileManager.default.currentDirectoryPath + "/lib").expandingTildeInPath
    ])

    filewatcher.callback = { event in
      if event.path.hasSuffix(".dart") {
        for pipe in pipes {
          print("File changed: \(event.path)")
          pipe.fileHandleForWriting.write("r".data(using: .utf8)!)

        }
      }
    }

    filewatcher.start()

    // Get input from user
    let input = FileHandle.standardInput
    input.waitForDataInBackgroundAndNotify()

    print(
      """
          Press 'r' to reload,
          'R' to restart,
          'q' to quit..
      """
    )

    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(
      forName: NSNotification.Name.NSFileHandleDataAvailable, object: input, queue: nil
    ) { notification in
      let data = input.availableData
      if let string = String(data: data, encoding: .utf8) {
        if string.contains("r") {
          print("Reloading..")
          pipes.forEach { $0.fileHandleForWriting.write("r".data(using: .utf8)!) }
        } else if string.contains("R") {
          print("Restarting..")
          pipes.forEach { $0.fileHandleForWriting.write("R".data(using: .utf8)!) }
        } else if string.contains("q") || string.contains("Q") {
          print("Quitting..")
          pipes.forEach { $0.fileHandleForWriting.write("q".data(using: .utf8)!) }
        }
      }
      input.waitForDataInBackgroundAndNotify()
    }

    RunLoop.main.run()
  }
}

struct Device: Decodable {
  let name: String
  let id: String
  let isSupported: Bool
  let targetPlatform: String
  let emulator: Bool
  let sdk: String
  let capabilities: Capabilities

  static func fromJSON(_ data: Data) -> [Device]? {
    return try? JSONDecoder().decode([Device].self, from: data)
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
