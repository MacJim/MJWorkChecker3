//
//  NSDate helper.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 4/20/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import Foundation


extension Date {
    public var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    public var endOfDay: Date {
        let tempDateComponents = DateComponents(calendar: Calendar.current, day: 1, second: -1)
        return Calendar.current.date(byAdding: tempDateComponents, to: startOfDay)!
    }
    
    public var startOfPrevious7DayStreak: Date {
        let tempDateComponents = DateComponents(calendar: Calendar.current, day: -6)
        return Calendar.current.date(byAdding: tempDateComponents, to: startOfDay)!
    }
    
    public var startOfPrevious30DayStreak: Date {
        let tempDateComponents = DateComponents(calendar: Calendar.current, day: -29)
        return Calendar.current.date(byAdding: tempDateComponents, to: startOfDay)!
    }
    
    public var startOfNextDay: Date {
        let tempDateComponents = DateComponents(calendar: Calendar.current, day: 1)
        return Calendar.current.date(byAdding: tempDateComponents, to: startOfDay)!
    }
}

extension Date {
    public var components: (year: Int, month: Int, day: Int) {
        let calendar = Calendar.current
        return (calendar.component(.year, from: self), calendar.component(.month, from: self), calendar.component(.day, from: self))
    }
}

extension DateFormatter {
    /**
     * Date format reference: https://www.codingexplorer.com/swiftly-getting-human-readable-date-nsdateformatter/
     */
    public class func getFormattedDateStringFromAnotherFormattedDateString(sourceDateString: String, sourceDateFormat: String, resultDateFormat: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = sourceDateFormat
        
        guard let date = formatter.date(from: sourceDateString) else {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DateFormatter", functionName: #function, lineNumber: #line, errorDescription: "Failed to initialize date from source date string \"\(sourceDateString)\" and souce date format \"\(sourceDateFormat)\"")
            return nil
        }
        
        formatter.dateFormat = resultDateFormat
        return formatter.string(from: date)
    }
    
    public class func getFormattedDateStringFromAnotherFormattedDateString(sourceDateString: String, sourceDateFormat: String, resultDateStyle: DateFormatter.Style) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = sourceDateFormat
        
        guard let date = formatter.date(from: sourceDateString) else {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "DateFormatter", functionName: #function, lineNumber: #line, errorDescription: "Failed to initialize date from source date string \"\(sourceDateString)\" and souce date format \"\(sourceDateFormat)\"")
            return nil
        }
        
        formatter.dateStyle = resultDateStyle
        return formatter.string(from: date)
    }
}

