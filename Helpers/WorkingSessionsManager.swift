//
//  WorkingSessionsManager.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 4/18/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import Foundation


private let singleton = WorkingSessionsManager()

class WorkingSessionsManager {
    //MARK: - Singleton stuff.
    class var shared: WorkingSessionsManager {
        return singleton
    }
    
    
    //MARK: - Initializers and deinitializers.
    fileprivate init() {
        let userDefaults = UserDefaults.standard
        
        if let savedStartWorkingTimestamp = userDefaults.object(forKey: WorkingSessionsManager.startWorkingTimestampUserDefaultsKey) as? Int64 {
            startWorkingTimestamp = savedStartWorkingTimestamp
        } else {
            startWorkingTimestamp = nil
        }
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
    
    
    //MARK: - Today / past 7 days working duration.
    /**
     * Today working duration in seconds.
     */
    var todayWorkingDuration: Int64 {
        //TODO:
        return 0
        let startOfToday = Date().startOfDay
    }
    
    /**
     * Past 7 days (including today) working duration in seconds.
     */
    var past7DaysWorkingDuration: Int64 {
        //TODO:
        return 0
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
                DatabaseManager.shared.addAWorkSegment(startWorkingTimestamp: aSegment.startWorkingTimestamp, stopWorkingTimestamp: aSegment.stopWorkingTimestamp)
            }
        } else {
            //This segment started and ended within the same day.
            DatabaseManager.shared.addAWorkSegment(startWorkingTimestamp: startWorkingTimestamp!, stopWorkingTimestamp: currentTimestamp)
        }
        
        startWorkingTimestamp = nil
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: WorkingSessionsManager.startWorkingTimestampUserDefaultsKey)
    }
    
    
    //MARK: - Working history.
}

