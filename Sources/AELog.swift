//
// AELog.swift
//
// Copyright (c) 2016 Marko Tadić <tadija@me.com> http://tadija.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation

// MARK: - Top Level

/** 
    Writes the textual representations of current timestamp, thread name,
    file name, line number and function name into the standard output.
 
    You can optionally provide custom message to be added at the end of a log line.
 
    - NOTE: If `AELog` setting "Enabled" is set to "NO" this will do nothing.
 
    - parameter message: Custom text which will be added at the end of a log line
*/
public func aelog(_ message: Any = "", path: String = #file, lineNumber: Int = #line, function: String = #function) {
    let thread = Thread.current
    AELog.shared.log(thread: thread, path: path, lineNumber: lineNumber, function: function, message: "\(message)")
}

// MARK: - AELog

/// Handles logging called from `aelog` top-level function.
open class AELog {
    
    // MARK: Properties
    
    static let shared = AELog()
    
    weak var delegate: AELogDelegate?
    
    let settings = Settings()
    let queue = DispatchQueue(label: "AELog", attributes: [])
    
    // MARK: API

    /// Configures delegate for `AELog` singleton. Use this if you need additional functionality after each line of log.
    open class func launch(with delegate: AELogDelegate) {
        AELog.shared.delegate = delegate
    }
    
    func log(thread: Thread, path: String, lineNumber: Int, function: String, message: String) {
        queue.async { [unowned self] in
            if self.settings.isEnabled {
                let fileName = self.getFileName(for: path)
                if self.isLogEnabledForFileWithName(fileName) {
                    
                    let line = Line(thread: thread, file: fileName, number: lineNumber, function: function, message: message)
                    print(line.description)
                    
                    DispatchQueue.main.async(execute: {
                        self.delegate?.didLog(line)
                    })
                }
            }
        }
    }
    
    // MARK: Helpers
    
    private func getFileName(for path: String) -> String {
        guard let
            fileName = NSURL(fileURLWithPath: path).deletingPathExtension?.lastPathComponent
        else { return "Unknown" }
        return fileName
    }
    
    private func isLogEnabledForFileWithName(_ fileName: String) -> Bool {
        guard let
            files = settings.files,
            let fileEnabled = files[fileName]
        else { return true }
        return fileEnabled
    }
    
}

// MARK: - AELogDelegate

/// Forwards logged lines via `didLog:` function.
public protocol AELogDelegate: class {
    
    func didLog(_ line: Line)
    
}
