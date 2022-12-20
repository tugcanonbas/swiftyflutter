import Foundation
import FileWatcher

@main
public struct flutterrunner {

    public static func main() {
        let devicesProcess = Process()
        devicesProcess.launchPath = "/usr/bin/env"
        let pipe = Pipe()
        devicesProcess.standardOutput = pipe
        devicesProcess.standardError = pipe
        devicesProcess.arguments = ["flutter", "devices", "--machine"]
        devicesProcess.launch()
        devicesProcess.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        devicesProcess.terminate()

        guard let devices = Device.fromJSON(data) else {
            print("Could not parse devices")
            return
        }

        var processes = [Process]()
        var pipes = [Pipe]()

        devices.forEach { device in
            print("Device: \(device.name), \(device.targetPlatform), (\(device.id))")
            let (process, pipe) = device.run()

            processes.append(process)
            pipes.append(pipe)
        }


        for process in processes {
            let tmpPipe = Pipe()
            process.standardOutput = tmpPipe

            defer {
                process.terminate()
            }

            process.launch()

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

let filewatcher = FileWatcher([NSString(string: FileManager.default.currentDirectoryPath + "/lib").expandingTildeInPath])

filewatcher.callback = { event in
  if event.path.hasSuffix(".dart") {
    for pipe in pipes {
        print("File changed: \(event.path)")
        pipe.fileHandleForWriting.write("r".data(using: .utf8)!)
        
    }
  }
}

filewatcher.start()

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