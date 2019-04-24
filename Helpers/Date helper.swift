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
