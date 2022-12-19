import Foundation
import ShellOut

@main
public struct flutterrunner {

    public static func main() {
        guard let devices = try? shellOut(to: "flutter", arguments: ["devices"]) else {
            print("Error: flutter devices failed")
            return
        }

        print("Devices: \(devices)")

// Output:
// Pixel 5 (mobile)            • 12091FDD4001BF                       • android-arm64  • Android 13 (API 33)
// Digitastic SE 2020 (mobile) • 00008030-0011493A3E45802E            • ios            • iOS 16.1.2 20B110
// iPhone 14 Pro Max (mobile)  • F8668852-E0CD-4811-BDE0-91362BE11DA5 • ios            • com.apple.CoreSimulator.SimRuntime.iOS-16-2 (simulator)
// macOS (desktop)             • macos                                • darwin-arm64   • macOS 13.1 22C65 darwin-arm
// Chrome (web)                • chrome                               • web-javascript • Google Chrome 108.0.5359.124

// Select device ids from output without macOS and Chrome


        let lines = devices.components(separatedBy: "\n")

        // print("Lines: \(lines)")

        let selectedLines = lines.filter { line in
            return line.contains("mobile")
        }

        // print("Selected lines: \(selectedLines)")

        var selectedDevicesUUIDs = [String]()

        for line in selectedLines {
            let components = line.components(separatedBy: "•")
            let uuid = components[1].trimmingCharacters(in: .whitespaces)
            selectedDevicesUUIDs.append(uuid)
        }

        // print(selectedDevicesUUIDs)

        var processes = [Process]()
        var pipes = [Pipe]()
        selectedDevicesUUIDs.forEach { uuid in
            let process = Process()
            process.launchPath = "/usr/bin/env"
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            let file = pipe.fileHandleForReading
            file.readabilityHandler = { file in
                if let line = String(data: file.availableData, encoding: .utf8) {
                    print(line)
                }
            }

            process.arguments = ["flutter", "run", "-d", uuid]
            processes.append(process)
            pipes.append(pipe)
        }

        processes.enumerated().forEach { process in
            process.element.launch()
            let file = pipes[process.offset].fileHandleForReading
            file.readabilityHandler = { file in
                if let line = String(data: file.availableData, encoding: .utf8) {
                    guard line.contains("Running with sound null safety") else {
                        print("Error: flutter run failed")
                        return
                    }
                }
            }
        }

        processes.forEach { process in
            process.waitUntilExit()
        }

        RunLoop.main.run()
    }
}