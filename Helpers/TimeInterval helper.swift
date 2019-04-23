//
//  TimeInterval helper.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 4/23/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import Foundation


extension TimeInterval {
    ///HH:MM:SS
    public func toFormattedString() -> String {
        let hours = Int(self / 60 / 60)
        let minutes = Int((self - Double(hours) * 60 * 60) / 60)
        let seconds = Int(self - Double(hours) * 60 * 60 - Double(minutes) * 60)
        
        let hoursString = "\(hours)"
        var minutesString = "\(minutes)"
        if (minutes < 10) {
            minutesString = "0" + minutesString
        }
        var secondsString = "\(seconds)"
        if (seconds < 10) {
            secondsString = "0" + secondsString
        }
        
        return hoursString + ":" + minutesString + ":" + secondsString
    }
    
    public static func convertSecondsToFormattedString(seconds: Int64) -> String {
        var totalSeconds = seconds
        var returnValue = ""
        
        let hours = totalSeconds / 3600
        totalSeconds -= hours * 3600
        returnValue += "\(hours):"
        
        let minutes = totalSeconds / 60
        totalSeconds -= minutes * 60
        if (minutes < 10) {
            returnValue += "0"
        }
        returnValue += "\(minutes):"
        
        let seconds = totalSeconds
        if (seconds < 10) {
            returnValue += "0"
        }
        returnValue += "\(seconds)"
        
        return returnValue
    }
}
