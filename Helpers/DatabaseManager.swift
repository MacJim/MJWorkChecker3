//
//  DatabaseManager.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 4/17/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import Foundation
import SQLite3


private let singleton = DatabaseManager()

class DatabaseManager {
    //MARK: - Singleton stuff.
    class var shared: DatabaseManager {
        return singleton
    }
    
    
    //MARK: - Shared constants.
    static let databaseFileName = "WC.db"
    static let workSegmentsTableName = "WorkSegments"
    
    
    //MARK: - Shared database variables.
    var databaseConnection: OpaquePointer?
    var isDatabaseConnectionEstablished: Bool {
        return (databaseConnection != nil)
    }
    
    
    //MARK: - Initializers.
    fileprivate init() {
        //1. Initialize variables.
        databaseConnection = nil
        
        //2. Establish database connection.
        let databaseURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(DatabaseManager.databaseFileName)
        
        if (sqlite3_open(databaseURL.path, &databaseConnection) != SQLITE_OK) {
            databaseConnection = nil
            ErrorLogger.shared.log(errorLevel: ErrorLevel.fatalError, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to open database!")
        }
        
        //3. Create table if it does not exist.
        if (isDatabaseConnectionEstablished) {
            if (!self.createTable()) {
                ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to create table!")
            }
        }
    }
    
    deinit {
        if (isDatabaseConnectionEstablished) {
            sqlite3_close(databaseConnection)
        }
    }
    
    
    //MARK: - Create table.
    /**
     * - Returns: If the creation was successful, `true`; else, `false`.
     */
    func createTable() -> Bool {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return false
        }
        
        if (sqlite3_exec(databaseConnection, "CREATE TABLE IF NOT EXISTS " + DatabaseManager.workSegmentsTableName + " (segmentID INTEGER, startWorkingTimestamp INTEGER NOT NULL, stopWorkingTimestamp INTEGER NOT NULL, PRIMARY KEY (segmentID));", nil, nil, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when creating table: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_exec(databaseConnection, "CREATE INDEX IF NOT EXISTS WorkSegments_startWorkingTimestamp ON WorkSegments (startWorkingTimestamp);", nil, nil, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when creating index: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
//        if (sqlite3_exec(databaseConnection, "CREATE INDEX IF NOT EXISTS WorkSegments_stopWorkingTimestamp ON WorkSegments (stopWorkingTimestamp);", nil, nil, nil) != SQLITE_OK) {
//            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when creating index: " + String(cString: sqlite3_errmsg(databaseConnection)!))
//            return false
//        }
        
        return true
    }
    
    
    //MARK: - SELECT
    /**
     * - Returns: (segmentID, startWorkingTimestamp, stopWorkingTimestamp)
     */
    func getAllWorkSegments() -> [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64)]? {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return nil
        }
        
        var statement: OpaquePointer?
        let queryString = "SELECT * FROM " + DatabaseManager.workSegmentsTableName
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing SELECT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        var returnValue = [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64)]()
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let segmentID = sqlite3_column_int64(statement, 0)
            let startWorkingTimestamp = sqlite3_column_int64(statement, 1)
            let stopWorkingTimestamp = sqlite3_column_int64(statement, 2)
            
            returnValue.append((segmentID, startWorkingTimestamp, stopWorkingTimestamp))
        }
        
        return returnValue
    }
    
    /**
     * Get all work segments that starts at or after the given timestamp.
     */
    func getWorkSegmentsStartingAtOrAfterTimestamp(timestamp: Int64) -> [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64)]? {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return nil
        }
        
        var statement: OpaquePointer?
        let queryString = "SELECT * FROM " + DatabaseManager.workSegmentsTableName + " WHERE startWorkingTimestamp>=?"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error , fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing SELECT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int64(statement, 1, timestamp) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `timestamp`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        var returnValue = [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64)]()
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let segmentID = sqlite3_column_int64(statement, 0)
            let startWorkingTimestamp = sqlite3_column_int64(statement, 1)
            let stopWorkingTimestamp = sqlite3_column_int64(statement, 2)
            
            returnValue.append((segmentID, startWorkingTimestamp, stopWorkingTimestamp))
        }
        
        return returnValue
    }
    
    /**
     * - Note: Both IDs are **inclusive**.
     */
    func getWorkSegmentsWithinInternalIDRange(startID: Int64, endID: Int64) -> [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64)]? {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return nil
        }
        
        var statement: OpaquePointer?
        let queryString = "SELECT * FROM " + DatabaseManager.workSegmentsTableName + " WHERE segmentID>=? AND segmentID<=?"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing SELECT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int64(statement, 1, startID) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `startIndex`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int64(statement, 2, endID) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `endIndex`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        var returnValue = [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64)]()
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let segmentID = sqlite3_column_int64(statement, 0)
            let startWorkingTimestamp = sqlite3_column_int64(statement, 1)
            let stopWorkingTimestamp = sqlite3_column_int64(statement, 2)
            
            returnValue.append((segmentID, startWorkingTimestamp, stopWorkingTimestamp))
        }
        
        return returnValue
    }
    
    
    //MARK: - INSERT
    /**
     * - Returns: `true` on success; `false` on failure.
     */
    func addAWorkSegment(startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64) -> Bool {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return false
        }
        
        var statement: OpaquePointer?
        let queryString = "INSERT INTO " + DatabaseManager.workSegmentsTableName + " VALUES(NULL, ?, ?)"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing INSERT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_bind_int64(statement, 1, startWorkingTimestamp) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `startWorkingTimestamp`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_bind_int64(statement, 2, stopWorkingTimestamp) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `stopWorkingTimestamp`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_step(statement) != SQLITE_DONE) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when executing INSERT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        return true
    }
    
    
    //MARK: - UPDATE
    /**
     * - Returns: `true` on success; `false` on failure.
     */
    func updateSegmentTimestamps(segmentID: Int64, newStartWorkingTimestamp: Int64, newStopWorkingTimestamp: Int64) -> Bool {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return false
        }
        
        var statement: OpaquePointer?
        let queryString = "UPDATE " + DatabaseManager.workSegmentsTableName + " SET startWorkingTimestamp=?, stopWorkingTimestamp=? WHERE segmentID=?"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing UPDATE: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_bind_int64(statement, 1, newStartWorkingTimestamp) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `newStartWorkingTimestamp`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_bind_int64(statement, 2, newStopWorkingTimestamp) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `newStopWorkingTimestamp`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_bind_int64(statement, 3, segmentID) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `segmentID`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_step(statement) != SQLITE_DONE) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when executing UPDATE: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        return true
    }
}
