//
//  ErrorLogger.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 4/19/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import Foundation
import UIKit


enum ErrorLevel {
    case info
    case warning
    case error
    case fatalError
    
    func toString() -> String {
        switch (self) {
        case .info:
            return "info"
            
        case .warning:
            return "warning"
            
        case .error:
            return "error"
            
        case .fatalError:
            return "fatal error"
        }
    }
}


class ErrorLogger {
    //MARK: - Singleton stuff.
    private static let singleton = ErrorLogger()
    
    class var shared: ErrorLogger {
        return ErrorLogger.singleton
    }
    
    
    //MARK: - Initializer.
    fileprivate init() {
        allLogs = [(errorLevel: ErrorLevel, fileName: String, className: String?, functionName: String?, lineNumber: Int, errorDescription: String)]()
    }
    
    
    //MARK: - All logs.
    /**
     * (filename, class name, method / function name, error description)
     */
    private var allLogs: [(errorLevel: ErrorLevel, fileName: String, className: String?, functionName: String?, lineNumber: Int, errorDescription: String)]
    
    func log(errorLevel: ErrorLevel, fileName: String, className: String?, functionName: String?, lineNumber: Int, errorDescription: String) {
        allLogs.append((errorLevel, fileName, className, functionName, lineNumber, errorDescription))
    }
    
    var humanReadableAllLogs: String {
        var returnValue = ""
        for aLog in allLogs {
            returnValue += "Error level: " + aLog.errorLevel.toString()
            returnValue += ", file name: " + aLog.fileName
            if let className = aLog.className {
                returnValue += ", class name: " + className
            }
            if let functionName = aLog.functionName {
                returnValue += ", function name: " + functionName
            }
            returnValue += ", line number: " + String(aLog.lineNumber)
            returnValue += ", error description: " + aLog.errorDescription
        }
        return returnValue
    }
    
    func copyAllLogsToClipboard() {
        UIPasteboard.general.string = humanReadableAllLogs
    }
}
