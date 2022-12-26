import FileWatcher
import Foundation

@main
public struct flutterrunner {

  public static func main() {
    print(
      """

      Welcome to swiftyflutter!

      """
    )
    defer {
      print("Exiting..")
      DeviceManager.shared.stopAll()
    }
    // Control-C handler
    signal(SIGINT) { signal in
      print("Exiting..")
      DeviceManager.shared.stopAll()
      exit(0)
    }

    run()
    RunLoop.main.run()
  }

  static func run() {
    let devices = DeviceManager.shared.getAvailableDevices()

    if devices.first(where: { $0.isBooted == true }) != nil {
      Util.print("Booted device found. Starting the app in debug mode..")

      let bootedDevices = devices.filter { $0.isBooted == true }

      bootedDevices.forEach { device in
        device.runApp()
      }

    } else {
      Util.print("Trying to boot the devices..")
      DeviceManager.shared.bootAll(devices)

      let bootedDevices = devices.filter { $0.isBooted == true }

      bootedDevices.forEach { device in
        device.runApp()
      }
    }

    let processes: [Process] = devices.filter { $0.process != nil }.map { $0.process! }
    let pipes: [Pipe] = devices.filter { $0.pipe != nil }.map { $0.pipe! }

    Util.print("Processes: \(processes.count)")

    if processes.count > 0 {
      launchProcesses(processes)

      fileWatcherProcess(pipes: pipes, processes: processes)
    }
  }

  // public static func runsubs() {
  //   let devicesProcess = Process()
  //   devicesProcess.launchPath = "/usr/bin/env"
  //   let pipe = Pipe()
  //   // pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
  //   devicesProcess.standardOutput = pipe
  //   devicesProcess.standardError = pipe
  //   devicesProcess.arguments = ["flutter", "devices", "--machine"]
  //   devicesProcess.launch()
  //   devicesProcess.waitUntilExit()
  //   let data = pipe.fileHandleForReading.readDataToEndOfFile()
  //   pipe.fileHandleForReading.closeFile()
  //   devicesProcess.terminate()

  //   guard let devices = DeviceDTO.fromJSON(data) else {
  //     print("Could not parse devices")
  //     return
  //   }

  //   var processes = [Process]()
  //   var pipes = [Pipe]()

  //   defer {
  //     processes.forEach { $0.terminate() }
  //   }

  //   devices.forEach { device in
  //     print("Device: \(device.name), \(device.targetPlatform), (\(device.id))")

  //     if device.targetPlatform.contains("ios") || device.targetPlatform.contains("android") {
  //       let (process, pipe) = device.run()
  //       processes.append(process)
  //       pipes.append(pipe)
  //     }
  //   }

  //   launchProcesses(processes)

  //   fileWatcherProcess(pipes: pipes, processes: processes)

  //   RunLoop.main.run()
  // }

  static func launchProcesses(_ processes: [Process]) {
    for process in processes {
      let tmpPipe = Pipe()
      process.standardOutput = tmpPipe

      print("Launching: \(process.arguments![3])")
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
  }

  static func fileWatcherProcess(pipes: [Pipe], processes: [Process]) {
    print("Start watching files..")

    let filewatcher = FileWatcher([
      NSString(string: FileManager.default.currentDirectoryPath + "/lib").expandingTildeInPath
    ])

    filewatcher.callback = { event in
      if event.path.hasSuffix(".dart") {
        for pipe in pipes {
          //   print("File changed: \(event.path)")
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
          Press:
          'r' to reload,
          'R' to restart,
          'q/Q' to quit,
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
          processes.forEach { $0.terminate() }
          exit(0)
        }
      }
      input.waitForDataInBackgroundAndNotify()
    }
  }
}
