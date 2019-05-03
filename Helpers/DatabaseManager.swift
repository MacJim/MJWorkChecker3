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
    static let daysTableName = "Days"
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
            if (!self.createTablesAndIndexes()) {
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
    func createTablesAndIndexes() -> Bool {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return false
        }
        
        if (sqlite3_exec(databaseConnection, """
            CREATE TABLE IF NOT EXISTS Days (
                dayID INTEGER,

                startOfDayTimestamp INTEGER NOT NULL,    -- The day's start timestamp. Used for sorting and finding days.

                year INTEGER,    -- 2019

                month INTEGER,    -- 11

                day INTEGER,    -- 29

                totalWorkingDuration INTEGER NOT NULL,    -- Total working duration on that specific day.


                PRIMARY KEY (dayID)
            );
            """, nil, nil, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when creating `Days` table: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_exec(databaseConnection, "CREATE INDEX IF NOT EXISTS Days_startOfDayTimestamp ON Days(startOfDayTimestamp);", nil, nil, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when creating index: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_exec(databaseConnection, """
            CREATE TABLE IF NOT EXISTS WorkSegments (
                segmentID INTEGER,

                startWorkingTimestamp INTEGER NOT NULL,    -- Start working UNIX timestamp.

                stopWorkingTimestamp INTEGER NOT NULL,    -- Stop working UNIX timestamp.

                dayID INTEGER,


                PRIMARY KEY (segmentID),

                FOREIGN KEY (dayID) REFERENCES Days(dayID) ON DELETE SET NULL
            );
            """, nil, nil, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when creating `WorkSegments` table: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_exec(databaseConnection, "CREATE INDEX IF NOT EXISTS WorkSegments_dayID ON WorkSegments(dayID);", nil, nil, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when creating index: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_exec(databaseConnection, "PRAGMA foreign_keys = ON;", nil, nil, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when enabling foreign keys: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        return true
    }
    
    
    //MARK: - Days table operations.
    //MARK: SELECT (multiple columns)
    /**
     * - Returns:
     *   - `nil` if an error occured.
     *   - An empty array if there are no records.
     */
    func getAllDays() -> [(dayID: Int64, startOfDayTimestamp: Int64, year: Int32, month: Int32, day: Int32, totalWorkingDuration: Int64)]? {
        //TODO: I really wonder if I should convert: `year` to `UInt16`; `month` and `day` to `UInt8`...
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return nil
        }
        
        var statement: OpaquePointer?
        let queryString = "SELECT * FROM " + DatabaseManager.daysTableName
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing SELECT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        var returnValue = [(dayID: Int64, startOfDayTimestamp: Int64, year: Int32, month: Int32, day: Int32, totalWorkingDuration: Int64)]()
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let dayID = sqlite3_column_int64(statement, 0)
            let startOfDayTimestamp = sqlite3_column_int64(statement, 1)
            let year = sqlite3_column_int(statement, 2)
            let month = sqlite3_column_int(statement, 3)
            let day = sqlite3_column_int(statement, 4)
            let totalWorkingDuration = sqlite3_column_int64(statement, 5)
            
            returnValue.append((dayID, startOfDayTimestamp, year, month, day, totalWorkingDuration))
        }
        
        return returnValue
    }
    
    /**
     * - Returns:
     *   - `nil` if an error occured.
     *   - An empty array if there are no records.
     */
    func getDays(startingAtOrAfterTimestamp timestamp: Int64) -> [(dayID: Int64, startOfDayTimestamp: Int64, year: Int32, month: Int32, day: Int32, totalWorkingDuration: Int64)]? {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return nil
        }
        
        var statement: OpaquePointer?
        let queryString = "SELECT * FROM " + DatabaseManager.daysTableName + " WHERE startOfDayTimestamp>=?"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error , fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing SELECT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int64(statement, 1, timestamp) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `timestamp`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        var returnValue = [(dayID: Int64, startOfDayTimestamp: Int64, year: Int32, month: Int32, day: Int32, totalWorkingDuration: Int64)]()
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let dayID = sqlite3_column_int64(statement, 0)
            let startOfDayTimestamp = sqlite3_column_int64(statement, 1)
            let year = sqlite3_column_int(statement, 2)
            let month = sqlite3_column_int(statement, 3)
            let day = sqlite3_column_int(statement, 4)
            let totalWorkingDuration = sqlite3_column_int64(statement, 5)
            
            returnValue.append((dayID, startOfDayTimestamp, year, month, day, totalWorkingDuration))
        }
        
        return returnValue
    }
    
    //MARK: SELECT (a single row)
    /**
     * - Returns:
     *   - `nil` if an error occured.
     *   - A tuple containing all `nil`s if there are no records.
     */
    func getADay(dayID: Int64) -> (dayID: Int64?, startOfDayTimestamp: Int64?, year: Int32?, month: Int32?, day: Int32?, totalWorkingDuration: Int64?)? {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return nil
        }
        
        var statement: OpaquePointer?
        let queryString = "SELECT * FROM " + DatabaseManager.daysTableName + " WHERE dayID=?"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing SELECT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int64(statement, 1, dayID) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `dayID`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        var returnValue: (dayID: Int64?, startOfDayTimestamp: Int64?, year: Int32?, month: Int32?, day: Int32?, totalWorkingDuration: Int64?) = (nil, nil, nil, nil, nil, nil)
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let dayID = sqlite3_column_int64(statement, 0)
            let startOfDayTimestamp = sqlite3_column_int64(statement, 1)
            let year = sqlite3_column_int(statement, 2)
            let month = sqlite3_column_int(statement, 3)
            let day = sqlite3_column_int(statement, 4)
            let totalWorkingDuration = sqlite3_column_int64(statement, 5)
            
            if (returnValue.dayID == nil) {
                //Only return the first result.
                returnValue = (dayID, startOfDayTimestamp, year, month, day, totalWorkingDuration)
            } else {
                //Log additional results.
                ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "An extra result is found: (\(dayID), \(startOfDayTimestamp), \(year), \(month), \(day), \(totalWorkingDuration))")
            }
        }
        
        return returnValue
    }
    
    /**
     * - Returns:
     *   - `nil` if an error occured.
     *   - A tuple containing all `nil`s if there are no records.
     */
    func getADay(year: Int32, month: Int32, day: Int32) -> (dayID: Int64?, startOfDayTimestamp: Int64?, year: Int32?, month: Int32?, day: Int32?, totalWorkingDuration: Int64?)? {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return nil
        }
        
        var statement: OpaquePointer?
        let queryString = "SELECT * FROM " + DatabaseManager.daysTableName + " WHERE year=? AND month=? AND day=?"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing SELECT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int(statement, 1, year) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `year`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int(statement, 2, month) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `month`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int(statement, 3, day) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `day`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        var returnValue: (dayID: Int64?, startOfDayTimestamp: Int64?, year: Int32?, month: Int32?, day: Int32?, totalWorkingDuration: Int64?) = (nil, nil, nil, nil, nil, nil)
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let dayID = sqlite3_column_int64(statement, 0)
            let startOfDayTimestamp = sqlite3_column_int64(statement, 1)
            let year = sqlite3_column_int(statement, 2)
            let month = sqlite3_column_int(statement, 3)
            let day = sqlite3_column_int(statement, 4)
            let totalWorkingDuration = sqlite3_column_int64(statement, 5)
            
            if (returnValue.dayID == nil) {
                //Only return the first result.
                returnValue = (dayID, startOfDayTimestamp, year, month, day, totalWorkingDuration)
            } else {
                //Log additional results.
                ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "An extra result is found: (\(dayID), \(startOfDayTimestamp), \(year), \(month), \(day), \(totalWorkingDuration))")
            }
        }
        
        return returnValue
    }
    
    /**
     * - Returns:
     *   - `nil` if an error occured.
     *   - A tuple containing all `nil`s if there are no records.
     */
    func getADay(startOfDayTimestamp timestamp: Int64) -> (dayID: Int64?, startOfDayTimestamp: Int64?, year: Int32?, month: Int32?, day: Int32?, totalWorkingDuration: Int64?)? {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return nil
        }
        
        var statement: OpaquePointer?
        let queryString = "SELECT * FROM " + DatabaseManager.daysTableName + " WHERE startOfDayTimestamp=?"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing SELECT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int64(statement, 1, timestamp) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `timestamp`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        var returnValue: (dayID: Int64?, startOfDayTimestamp: Int64?, year: Int32?, month: Int32?, day: Int32?, totalWorkingDuration: Int64?) = (nil, nil, nil, nil, nil, nil)
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let dayID = sqlite3_column_int64(statement, 0)
            let startOfDayTimestamp = sqlite3_column_int64(statement, 1)
            let year = sqlite3_column_int(statement, 2)
            let month = sqlite3_column_int(statement, 3)
            let day = sqlite3_column_int(statement, 4)
            let totalWorkingDuration = sqlite3_column_int64(statement, 5)
            
            if (returnValue.dayID == nil) {
                //Only return the first result.
                returnValue = (dayID, startOfDayTimestamp, year, month, day, totalWorkingDuration)
            } else {
                //Log additional results.
                ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "An extra result is found: (\(dayID), \(startOfDayTimestamp), \(year), \(month), \(day), \(totalWorkingDuration))")
            }
        }
        
        return returnValue
    }
    
    
    //MARK: INSERT
    /**
     * - Returns:
     *   - `nil` if an error occured.
     *   - A tuple containing all `nil`s if the insertion was considered successful, but the inserted row could not be found.
     *   - A tuple containing the created row if the creation was successful.
     */
    func addADay(startOfDayTimestamp: Int64, year: Int32, month: Int32, day: Int32) -> (dayID: Int64?, startOfDayTimestamp: Int64?, year: Int32?, month: Int32?, day: Int32?, totalWorkingDuration: Int64?)? {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return nil
        }
        
        var statement: OpaquePointer?
        let queryString = "INSERT INTO " + DatabaseManager.daysTableName + " VALUES(NULL, ?, ?, ?, ?, 0)"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing INSERT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int64(statement, 1, startOfDayTimestamp) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `startOfDayTimestamp`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int(statement, 2, year) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `year`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int(statement, 3, month) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `month`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int(statement, 4, day) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `day`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_step(statement) != SQLITE_DONE) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when executing INSERT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        return getADay(startOfDayTimestamp: startOfDayTimestamp)
    }
    
    
    //MARK: UPDATE
    /**
     * Adds `workDuration` to the day's `totalWorkingDuration`.
     *
     * - Returns:
     *   - `nil` if an error occured.
     *   - A tuple containing all `nil`s if the update was considered successful, but the updated row could not be found. This might happen if `dayID` does not exist at all
     *   - A tuple containing the created row if the creation was successful.
     */
    func updateDayTotalWorkingDuration(workDurationToAdd: Int64, dayID: Int64) -> (dayID: Int64?, startOfDayTimestamp: Int64?, year: Int32?, month: Int32?, day: Int32?, totalWorkingDuration: Int64?)? {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return nil
        }
        
        var statement: OpaquePointer?
        let queryString = "UPDATE " + DatabaseManager.daysTableName + " SET totalWorkingDuration=totalWorkingDuration+? WHERE dayID=?"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing UPDATE: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int64(statement, 1, workDurationToAdd) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `workDurationToAdd`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_bind_int64(statement, 2, dayID) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `dayID`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        if (sqlite3_step(statement) != SQLITE_DONE) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when executing UPDATE: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return nil
        }
        
        return getADay(dayID: dayID)
    }
    
    
    //MARK: - WorkSegments table operations.
    //MARK: SELECT
    /**
     * - Returns:
     *   - `nil` if an error occured.
     *   - An empty array if there are no records.
     */
    func getAllWorkSegments() -> [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64, dayID: Int64)]? {
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
        
        var returnValue = [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64, dayID: Int64)]()
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let segmentID = sqlite3_column_int64(statement, 0)
            let startWorkingTimestamp = sqlite3_column_int64(statement, 1)
            let stopWorkingTimestamp = sqlite3_column_int64(statement, 2)
            let dayID = sqlite3_column_int64(statement, 3)
            
            returnValue.append((segmentID, startWorkingTimestamp, stopWorkingTimestamp, dayID))
        }
        
        return returnValue
    }
    
    /**
     * - Returns:
     *   - `nil` if an error occured.
     *   - An empty array if there are no records.
     */
    func getWorkSegments(startingAtOrAfterTimestamp timestamp: Int64) -> [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64, dayID: Int64)]? {
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
        
        var returnValue = [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64, dayID: Int64)]()
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let segmentID = sqlite3_column_int64(statement, 0)
            let startWorkingTimestamp = sqlite3_column_int64(statement, 1)
            let stopWorkingTimestamp = sqlite3_column_int64(statement, 2)
            let dayID = sqlite3_column_int64(statement, 3)
            
            returnValue.append((segmentID, startWorkingTimestamp, stopWorkingTimestamp, dayID))
        }
        
        return returnValue
    }
    
    /**
     * - Note: Both IDs are **inclusive**.
     *
     * - Returns:
     *   - `nil` if an error occured.
     *   - An empty array if there are no records.
     */
    func getWorkSegmentsWithinInternalIDRange(startID: Int64, endID: Int64) -> [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64, dayID: Int64)]? {
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
        
        var returnValue = [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64, dayID: Int64)]()
        while (sqlite3_step(statement) == SQLITE_ROW) {
            let segmentID = sqlite3_column_int64(statement, 0)
            let startWorkingTimestamp = sqlite3_column_int64(statement, 1)
            let stopWorkingTimestamp = sqlite3_column_int64(statement, 2)
            let dayID = sqlite3_column_int64(statement, 3)
            
            returnValue.append((segmentID, startWorkingTimestamp, stopWorkingTimestamp, dayID))
        }
        
        return returnValue
    }
    
    
    //MARK: INSERT
    /**
     * - Returns: `true` on success; `false` on failure.
     */
    func addAWorkSegment(startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64, dayID: Int64?) -> Bool {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return false
        }
        
        var statement: OpaquePointer?
        let queryString = "INSERT INTO " + DatabaseManager.workSegmentsTableName + " VALUES(NULL, ?, ?, ?)"
        
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
        
        if let dayID = dayID {
            //`dayID` is not `nil` (intended).
            if (sqlite3_bind_int64(statement, 3, dayID) != SQLITE_OK) {
                ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `dayID`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
                return false
            }
        } else {
            //`dayID` is `nil` (not intended, but kept as a failsafe).
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`dayID` is `nil`!")
            
            if (sqlite3_bind_null(statement, 3) != SQLITE_OK) {
                ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `dayID` (nil): " + String(cString: sqlite3_errmsg(databaseConnection)!))
                return false
            }
        }
        
        if (sqlite3_step(statement) != SQLITE_DONE) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when executing INSERT: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        return true
    }
    
    
    //MARK: UPDATE
    /**
     * - Returns: `true` on success; `false` on failure.
     */
    func updateSegmentTimestamps(segmentID: Int64, newStartWorkingTimestamp: Int64, newStopWorkingTimestamp: Int64, newDayID: Int64) -> Bool {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return false
        }
        
        var statement: OpaquePointer?
        let queryString = "UPDATE " + DatabaseManager.workSegmentsTableName + " SET startWorkingTimestamp=?, stopWorkingTimestamp=?, dayID=? WHERE segmentID=?"
        
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
        
        if (sqlite3_bind_int64(statement, 3, newDayID) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `newDayID`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_bind_int64(statement, 4, segmentID) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `segmentID`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_step(statement) != SQLITE_DONE) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when executing UPDATE: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        return true
    }


    //MARK: DELETE
    /**
     * - Returns: `true` on success; `false` on failure.
     */
    func deleteASegment(segmentID: Int64) -> Bool {
        if (!isDatabaseConnectionEstablished) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "`databaseConnection` is `nil`!")
            return false
        }
        
        var statement: OpaquePointer?
        let queryString = "DELETE FROM " + DatabaseManager.workSegmentsTableName + " WHERE segmentID=?"
        
        if (sqlite3_prepare(databaseConnection, queryString, -1, &statement, nil) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when preparing DELETE: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_bind_int64(statement, 1, segmentID) != SQLITE_OK) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when binding `segmentID`: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        if (sqlite3_step(statement) != SQLITE_DONE) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "DatabaseManager", functionName: #function, lineNumber: #line, errorDescription: "Error when executing DELETE: " + String(cString: sqlite3_errmsg(databaseConnection)!))
            return false
        }
        
        return true
    }
}
