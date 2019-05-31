//
//  WorkingSessionsManager.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 4/18/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import Foundation


class WorkingSessionsManager {
    //MARK: - Singleton stuff.
    private static let singleton = WorkingSessionsManager()
    
    class var shared: WorkingSessionsManager {
        return WorkingSessionsManager.singleton
    }
    
    
    //MARK: - Initializers and deinitializers.
    fileprivate init() {
        let userDefaults = UserDefaults.standard
        
        if let savedStartWorkingTimestamp = userDefaults.object(forKey: WorkingSessionsManager.startWorkingTimestampUserDefaultsKey) as? Int64 {
            startWorkingTimestamp = savedStartWorkingTimestamp
        } else {
            startWorkingTimestamp = nil
        }
        
        isProcessedTableViewDataUpToDate = false
    }
    
    
    //MARK: - Current working session information.
    static private let startWorkingTimestampUserDefaultsKey = "CurrentWorkingSessionStartTimestamp"
    
    /**
     * The private start working timestamp.
     *
     * - Note: Swift `Date` class actually returns `Double` timestamps. I decided not to keep that precision because that's not needed on this application's scale.
     */
    private var startWorkingTimestamp: Int64?
    var isWorkStarted: Bool {
        return (startWorkingTimestamp != nil)
    }
    
    var currentSessionWorkingDuration: Int64? {
        if let startWorkingTimestamp = startWorkingTimestamp {
            let currentDate = Date()
            return Int64(currentDate.timeIntervalSince1970) - startWorkingTimestamp
        } else {
            return nil
        }
    }
    
    
    //MARK: - Start / stop working.
    func startWorking() {
        if (isWorkStarted) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Work has already started!")
            return
        }
        
        let currentDate = Date()
        startWorkingTimestamp = Int64(currentDate.timeIntervalSince1970)
        
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(startWorkingTimestamp, forKey: WorkingSessionsManager.startWorkingTimestampUserDefaultsKey)
    }
    
    func stopWorking() {
        if (!isWorkStarted) {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Work has not started yet!")
            return
        }
        
        let startWorkingDate = Date(timeIntervalSince1970: TimeInterval(startWorkingTimestamp!))
        
        let currentDate = Date()
        let currentTimestamp = Int64(currentDate.timeIntervalSince1970)
        
        let startOfTodayTimestamp = currentDate.startOfDay
        
        if (startWorkingDate < startOfTodayTimestamp) {
            //This segment started and ended on different days.
            //In this case, the segment will be split into smaller segments that start and stop on the same day.
            var segments = [(startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64)]()
            
            var currentSegmentStartWorkingDate = startWorkingDate
            while (currentSegmentStartWorkingDate < startOfTodayTimestamp) {
                let startOfSegment = Int64(currentSegmentStartWorkingDate.timeIntervalSince1970)
                let endOfSegment = Int64(currentSegmentStartWorkingDate.endOfDay.timeIntervalSince1970)
                segments.append((startOfSegment, endOfSegment))
                
                currentSegmentStartWorkingDate = currentSegmentStartWorkingDate.startOfNextDay
            }
            segments.append((Int64(currentSegmentStartWorkingDate.timeIntervalSince1970), currentTimestamp))
            
            for aSegment in segments {
                let segmentDuration = aSegment.stopWorkingTimestamp - aSegment.startWorkingTimestamp
                //Ignore 0 length segments.
                if (segmentDuration != 0) {
                    //Update 2 tables.
                    if let currentDayIDInDatabase = todayIDInDatabase {
                        DatabaseManager.shared.updateDayTotalWorkingDuration(workingDurationToAdd: segmentDuration, dayID: currentDayIDInDatabase)
                    } else {
                        ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to get current day ID. This segment will not be logged in the `Days` table!")
                    }
                    DatabaseManager.shared.addAWorkSegment(startWorkingTimestamp: aSegment.startWorkingTimestamp, stopWorkingTimestamp: aSegment.stopWorkingTimestamp, dayID: todayIDInDatabase)
                }
            }
        } else {
            //This segment started and ended within the same day.
            let segmentDuration = currentTimestamp - startWorkingTimestamp!
            //Ignore 0 length segment.
            if (segmentDuration != 0) {
                //Update 2 tables.
                if let currentDayIDInDatabase = todayIDInDatabase {
                    DatabaseManager.shared.updateDayTotalWorkingDuration(workingDurationToAdd: segmentDuration, dayID: currentDayIDInDatabase)
                } else {
                    ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to get current day ID. This segment will not be logged in the `Days` table!")
                }
                DatabaseManager.shared.addAWorkSegment(startWorkingTimestamp: startWorkingTimestamp!, stopWorkingTimestamp: currentTimestamp, dayID: todayIDInDatabase)
            }
        }
        
        startWorkingTimestamp = nil
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: WorkingSessionsManager.startWorkingTimestampUserDefaultsKey)
        
        
        //Reload table view data from database.
        //TODO: This is a temporary solution. Please add the segments above directly to the cache.
        isProcessedTableViewDataUpToDate = false
    }
    
    
    //MARK: - Today ID in database.
    /**
     * Today's ID in database.
     *
     * - Note: If the day does not exist in database, a new entry will be created.
     *
     * - Returns: If an error occured, `nil`.
     */
    var todayIDInDatabase: Int64? {
        let currentDate = Date()
        let startOfDayTimestamp = Int64(currentDate.startOfDay.timeIntervalSince1970)
        if let possibleExistingEntry = DatabaseManager.shared.getADay(startOfDayTimestamp: startOfDayTimestamp) {
            if let existingDayID = possibleExistingEntry.dayID {
                //An entry exists.
                return existingDayID
            } else {
                //No today entry exists in the `Days` table. Create an entry.
                let todayComponents = currentDate.components
                if let newDay = DatabaseManager.shared.addADay(startOfDayTimestamp: startOfDayTimestamp, year: Int32(todayComponents.year), month: Int32(todayComponents.month), day: Int32(todayComponents.day)) {
                    if let newDayID = newDay.dayID {
                        return newDayID
                    } else {
                        //Could not find the newly created day.
                        ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Could not find the newly created day.")
                        return nil
                    }
                } else {
                    //Failed to create today entry.
                    ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to create today entry.")
                    return nil
                }
            }
        } else {
            //An error occured when finding the existing entry.
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Cannot find current day ID in database.")
            return nil
        }
    }
    
    
    //MARK: - Today / past 7 days working duration.
    /**
     * Today working duration in seconds.
     */
    var todayWorkingDuration: Int64 {
        var totalWorkingDuration: Int64 = 0
        
        let startOfTodayTimestamp = Int64(Date().startOfDay.timeIntervalSince1970)
        
        //1. Current working session.
        if (isWorkStarted) {
            if (startWorkingTimestamp! >= startOfTodayTimestamp) {
                //Current session started today.
                totalWorkingDuration += currentSessionWorkingDuration!
            } else {
                //Current session started on a previous day.
                //In this case, there's no need to search for today in database.
                let currentDate = Date()
                return Int64(currentDate.timeIntervalSince(currentDate.startOfDay))
            }
        }
        
        //2. Today working duration in database.
        if let todayInDatabase = DatabaseManager.shared.getADay(startOfDayTimestamp: startOfTodayTimestamp) {
            if let todayWorkingDurationInDatabase = todayInDatabase.totalWorkingDuration {
                //Today exists in the `Days` table.
                totalWorkingDuration += todayWorkingDurationInDatabase
            }
        } else {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to find today in database.")
        }
        
        return totalWorkingDuration
    }
    
    /**
     * Past 7 days (including today) working duration in seconds.
     */
    var past7DaysWorkingDuration: Int64 {
        var totalWorkingDuration: Int64 = 0
        
        let startOfPrevious7DayStreakTimestamp = Int64(Date().startOfPrevious7DayStreak.timeIntervalSince1970)
        
        //1. Current working session.
        if (isWorkStarted) {
            if (startWorkingTimestamp! >= startOfPrevious7DayStreakTimestamp) {
                //Current session started in the previous 7 days.
                totalWorkingDuration += currentSessionWorkingDuration!
            } else {
                //Current session started on a previous day.
                //In this case, there's no need to search for the previous 7 days in database.
                let currentDate = Date()
                return Int64(currentDate.timeIntervalSince(currentDate.startOfPrevious7DayStreak))
            }
        }
        
        //2. Previous 7 days in database.
        if let previous7DaysInDatabase = DatabaseManager.shared.getDays(startingAtOrAfterTimestamp: startOfPrevious7DayStreakTimestamp) {
            for aDay in previous7DaysInDatabase {
                totalWorkingDuration += aDay.totalWorkingDuration
            }
        } else {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to find previous 7 days in database.")
        }
        
        return totalWorkingDuration
    }
    
    /**
     * Past 30 days (including today) working duration in seconds.
     */
    var past30DaysWorkingDuration: Int64 {
        var totalWorkingDuration: Int64 = 0
        
        let startOfPrevious30DayStreakTimestamp = Int64(Date().startOfPrevious30DayStreak.timeIntervalSince1970)
        
        //1. Current working session.
        if (isWorkStarted) {
            if (startWorkingTimestamp! >= startOfPrevious30DayStreakTimestamp) {
                //Current session started in the previous 30 days.
                totalWorkingDuration += currentSessionWorkingDuration!
            } else {
                //Current session started on a previous day.
                //In this case, there's no need to search for the previous 30 days in database.
                let currentDate = Date()
                return Int64(currentDate.timeIntervalSince(currentDate.startOfPrevious30DayStreak))
            }
        }
        
        //2. Work segments in database.
        if let previous30DaysInDatabase = DatabaseManager.shared.getDays(startingAtOrAfterTimestamp: startOfPrevious30DayStreakTimestamp) {
            for aDay in previous30DaysInDatabase {
                totalWorkingDuration += aDay.totalWorkingDuration
            }
        } else {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to find previous 30 days in database.")
        }
        
        return totalWorkingDuration
    }
    
    
    //MARK: - Raw data table view data.
    private var _tableViewDataCache: [(year: Int32, month: Int32, days: [(dayID: Int64, day: Int32, totalWorkingDuration: Int64)])]?
    
    private func loadTableViewDataFromDatabase() {
        guard let orderedAllDays = DatabaseManager.shared.getOrderedAllDays() else {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to get all days data from database.")
            return
        }
        
        _tableViewDataCache = [(year: Int32, month: Int32, days: [(dayID: Int64, day: Int32, totalWorkingDuration: Int64)])]()
        
        var lastYear: Int32?
        var lastMonth: Int32?
        var lastDays: [(dayID: Int64, day: Int32, totalWorkingDuration: Int64)]?
        for aDay in orderedAllDays {
            //1. Update `lastYear`, `lastMonth` and `lastDays` if necessary.
            if ((lastYear == nil) || (lastMonth == nil) || (lastDays == nil)) {
                //Initialize `lastYear`, `lastMonth` and `lastDays`.
                lastYear = aDay.year
                lastMonth = aDay.month
                lastDays = [(dayID: Int64, day: Int32, totalWorkingDuration: Int64)]()
            } else if (((lastYear != nil) && (lastMonth != nil)) && ((aDay.year != lastYear) || (aDay.month != lastMonth))) {
                //The current day is on a different month or year.
                //Save `lastYear`, `lastMonth` and `lastDays` in `_tableViewDataCache`.
                _tableViewDataCache?.append((lastYear!, lastMonth!, lastDays!))
                
                //Update `lastYear`, `lastMonth` and `lastDays`.
                lastYear = aDay.year
                lastMonth = aDay.month
                lastDays = [(dayID: Int64, day: Int32, totalWorkingDuration: Int64)]()
            }
            
            //2. Add current day to `lastDays`.
            var dayHumanReadableString: String! = DateFormatter.getFormattedDateStringFromAnotherFormattedDateString(sourceDateString: "\(aDay.year) \(aDay.month) \(aDay.day)", sourceDateFormat: "y M d", resultDateStyle: .medium)
            if (dayHumanReadableString == nil) {
                ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to convert year (\(aDay.year)), month (\(aDay.month)) and day (\(aDay.day)) to human readable string.")
                dayHumanReadableString = "\(aDay.year) \(aDay.month) \(aDay.day)"
            }
            
            lastDays?.append((aDay.dayID, aDay.day, aDay.totalWorkingDuration))
        }
        
        //Save the final month.
        if ((lastYear != nil) && (lastMonth != nil)) {
            //Save `lastYear`, `lastMonth` and `lastDays` in `_tableViewDataCache`.
            _tableViewDataCache?.append((lastYear!, lastMonth!, lastDays!))
        }
        
        isProcessedTableViewDataUpToDate = true
    }
    
    var isProcessedTableViewDataUpToDate: Bool
    
    /**
     * Processed table view data.
     *
     * - Note: Both "year and month"s and "month and day"s are sorted from most recent to least recent.
     */
    var processedTableViewData: [(year: Int32, month: Int32, days: [(dayID: Int64, day: Int32, totalWorkingDuration: Int64)])]? {
        if (!isProcessedTableViewDataUpToDate) {
            loadTableViewDataFromDatabase()
        }
        
        //TODO: Count in current day working duration.
        
        return _tableViewDataCache
    }
    
//    var processedTableViewData: [(yearAndMonthHumanReadableString: String, days: [(dayID: Int64, dayHumanReadableString: String, totalWorkingDuration: Int64)])]? {
//        guard let orderedAllDays = DatabaseManager.shared.getOrderedAllDays() else {
//            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to get all days data from database.")
//            return nil
//        }
//
//        var returnValue = [(yearAndMonthHumanReadableString: String, days: [(dayID: Int64, dayHumanReadableString: String, totalWorkingDuration: Int64)])]()
//
//        var lastYear: Int32?
//        var lastMonth: Int32?
//        var lastDays: [(dayID: Int64, dayHumanReadableString: String, totalWorkingDuration: Int64)]?
//        for aDay in orderedAllDays {
//            //1. Update `lastYear`, `lastMonth` and `lastDays` if necessary.
//            if ((lastYear == nil) || (lastMonth == nil) || (lastDays == nil)) {
//                //Initialize `lastYear`, `lastMonth` and `lastDays`.
//                lastYear = aDay.year
//                lastMonth = aDay.month
//                lastDays = [(dayID: Int64, dayHumanReadableString: String, totalWorkingDuration: Int64)]()
//            } else if (((lastYear != nil) && (lastMonth != nil)) && ((aDay.year != lastYear) || (aDay.month != lastMonth))) {
//                //The current day is on a different month or year.
//                //Save `lastYear`, `lastMonth` and `lastDays` in `returnValue`.
//                var yearAndMonthHumanReadableString: String! = DateFormatter.getFormattedDateStringFromAnotherFormattedDateString(sourceDateString: "\(lastYear!) \(lastMonth!)", sourceDateFormat: "y M", resultDateFormat: "MMMM y")
//                if (yearAndMonthHumanReadableString == nil) {
//                    ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to convert year (\(lastYear!)) and month (\(lastMonth!)) to human readable string.")
//                    yearAndMonthHumanReadableString = "\(lastYear!) \(lastMonth!)"
//                }
//                returnValue.append((yearAndMonthHumanReadableString, lastDays!))
//
//                //Update `lastYear`, `lastMonth` and `lastDays`.
//                lastYear = aDay.year
//                lastMonth = aDay.month
//                lastDays = [(dayID: Int64, dayHumanReadableString: String, totalWorkingDuration: Int64)]()
//            }
//
//            //2. Add current day to `lastDays`.
//            var dayHumanReadableString: String! = DateFormatter.getFormattedDateStringFromAnotherFormattedDateString(sourceDateString: "\(aDay.year) \(aDay.month) \(aDay.day)", sourceDateFormat: "y M d", resultDateStyle: .medium)
//            if (dayHumanReadableString == nil) {
//                ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to convert year (\(aDay.year)), month (\(aDay.month)) and day (\(aDay.day)) to human readable string.")
//                dayHumanReadableString = "\(aDay.year) \(aDay.month) \(aDay.day)"
//            }
//
//            lastDays?.append((aDay.dayID, dayHumanReadableString, aDay.totalWorkingDuration))
//        }
//
//        //Save the final month.
//        if ((lastYear != nil) && (lastMonth != nil)) {
//            //Save `lastYear`, `lastMonth` and `lastDays` in `returnValue`.
//            var yearAndMonthHumanReadableString: String! = DateFormatter.getFormattedDateStringFromAnotherFormattedDateString(sourceDateString: "\(lastYear!) \(lastMonth!)", sourceDateFormat: "y M", resultDateFormat: "MMMM y")
//            if (yearAndMonthHumanReadableString == nil) {
//                ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to convert year (\(lastYear!)) and month (\(lastMonth!)) to human readable string.")
//                yearAndMonthHumanReadableString = "\(lastYear!) \(lastMonth!)"
//            }
//            returnValue.append((yearAndMonthHumanReadableString, lastDays!))
//        }
//
//        return returnValue
//    }
//    var processedTableViewData: [(year: Int32, month: Int32, days: [(dayID: Int64, day: Int32, totalWorkingDuration: Int64)])]? {
//        guard let orderedAllDays = DatabaseManager.shared.getOrderedAllDays() else {
//            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to get all days data from database.")
//            return nil
//        }
//
//        var returnValue = [(year: Int32, month: Int32, days: [(dayID: Int64, day: Int32, totalWorkingDuration: Int64)])]()
//
//        for aDay in orderedAllDays {
//            if let previousLastMonth = returnValue.last {
//                if ((aDay.year != previousLastMonth.year) || (aDay.month != previousLastMonth.month)) {
//                    //Add new month.
//                    returnValue.append((year: aDay.year, month: aDay.month, days: [(dayID: Int64, day: Int32, totalWorkingDuration: Int64)]()))
//                }
//            } else {
//                //Add first month.
//                returnValue.append((year: aDay.year, month: aDay.month, days: [(dayID: Int64, day: Int32, totalWorkingDuration: Int64)]()))
//            }
//
//            returnValue.last?.days.append((dayID: aDay.dayID, day: aDay.day, totalWorkingDuration: aDay.totalWorkingDuration))
//        }
//
//        return returnValue
//    }
    ///Dirty. If `false`, `processedAllWorkSegmentsCache` is not up to date.
//    var isProcessedAllWorkSegmentsDataUpToDate: Bool
    /**
     * [year: [month: [day: (total working duration, [(segment ID in database, work duration)])]]]
     */
//    var processedAllWorkSegmentsData: [Int: [Int: [Int: (totalWorkingDuration: Int64, segments: [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64)])]]]
    
//    private func addAWorkSegmentToProcessedAllWorkSegmentsData(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64) {
//        let segmentWorkingDuration = stopWorkingTimestamp - startWorkingTimestamp
//
//        let startDate = Date(timeIntervalSince1970: TimeInterval(startWorkingTimestamp))
//        let startDateComponents = startDate.components
//        let year = startDateComponents.year
//        let month = startDateComponents.month
//        let day = startDateComponents.day
//
//        //Initialize the dictionary if it's not fully initialized.
//        if (processedAllWorkSegmentsData[year] == nil) {
//            processedAllWorkSegmentsData[year] = [Int: [Int: (totalWorkingDuration: Int64, segments: [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64)])]]()
//        }
//
//        if (processedAllWorkSegmentsData[year]?[month] == nil) {
//            processedAllWorkSegmentsData[year]?[month] = [Int: (totalWorkingDuration: Int64, segments: [(segmentID: Int64, startWorkingTimestamp: Int64, stopWorkingTimestamp: Int64)])]()
//        }
//
//        if (processedAllWorkSegmentsData[year]?[month]?[day] == nil) {
//            processedAllWorkSegmentsData[year]?[month]?[day] = (totalWorkingDuration: 0, segments: [])
//        }
//
//        processedAllWorkSegmentsData[year]?[month]?[day]?.totalWorkingDuration += segmentWorkingDuration
//        processedAllWorkSegmentsData[year]?[month]?[day]?.segments.append((segmentID, startWorkingTimestamp, stopWorkingTimestamp))
//    }
    
    /**
     * Loads all work segments data from database.
     */
//    private func loadTableViewDataFromDatabase() {
//        if let allWorkSegments = DatabaseManager.shared.getAllWorkSegments() {
//            for aWorkSegment in allWorkSegments {
//                let segmentID = aWorkSegment.segmentID
//
//                addAWorkSegmentToProcessedAllWorkSegmentsData(segmentID: segmentID, startWorkingTimestamp: aWorkSegment.startWorkingTimestamp, stopWorkingTimestamp: aWorkSegment.stopWorkingTimestamp)
//            }
//        } else {
//            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to get all work segments from DatabaseManager.")
//        }
//
//        isProcessedAllWorkSegmentsDataUpToDate = true
//    }
}

