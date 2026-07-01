import Foundation

// MARK: - Shell 工具

/// 运行 shell 命令，返回输出字符串（nil 表示失败）
@discardableResult
func runCmd(_ args: String...) async -> String? {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: args[0])
            process.arguments = Array(args.dropFirst())
            
            let outPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: output?.isEmpty == false ? output : nil)
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}

/// 运行 shell 命令，返回输出和退出码
func runCmdOutput(_ args: String...) async -> (output: String?, exitCode: Int32) {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: args[0])
            process.arguments = Array(args.dropFirst())
            
            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: (output, process.terminationStatus))
            } catch {
                continuation.resume(returning: (nil, -1))
            }
        }
    }
}

// MARK: - 字符串工具

/// Shell 转义：用单引号包裹，内部单引号用 `'\''` 转义
func shellEscape(_ s: String) -> String {
    "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

extension String {
    /// XML 转义（用于 plist 字符串值）
    var xmlEscaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
