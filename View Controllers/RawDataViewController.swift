//
//  RawDataViewController.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 4/24/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import UIKit


class RawDataViewController: UITableViewController {
    //MARK: - View presenting stuff.
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    //MARK: - Table view data source.
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let tableViewData = WorkingSessionsManager.shared.processedTableViewData {
            return tableViewData.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let tableViewData = WorkingSessionsManager.shared.processedTableViewData {
            let currentMonthData = tableViewData[section]
            if let humanReadableYearAndMonth = DateFormatter.getFormattedDateStringFromAnotherFormattedDateString(sourceDateString: "\(currentMonthData.year) \(currentMonthData.month)", sourceDateFormat: "y M", resultDateFormat: "MMMM y") {
                return humanReadableYearAndMonth
            } else {
                ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "RawDataViewController", functionName: #function, lineNumber: #line, errorDescription: "Failed to convert year (\(currentMonthData.year)) and month (\(currentMonthData.month)) to human readable string.")
                return "\(currentMonthData.year) \(currentMonthData.month)"
            }
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let tableViewData = WorkingSessionsManager.shared.processedTableViewData {
            return tableViewData[section].days.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellReuseIdentifier = "RawDataTableViewCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        
        if let castedCell = cell as? RawDataTableViewCell {
            if let tableViewData = WorkingSessionsManager.shared.processedTableViewData {
                let currentMonthData = tableViewData[indexPath.section]
                let currentDayData = currentMonthData.days[indexPath.row]
                
                if let dayHumanReadableString = DateFormatter.getFormattedDateStringFromAnotherFormattedDateString(sourceDateString: "\(currentMonthData.year) \(currentMonthData.month) \(currentDayData.day)", sourceDateFormat: "y M d", resultDateStyle: .medium) {
                    castedCell.dateLable.text = dayHumanReadableString
                } else {
                    ErrorLogger.shared.log(errorLevel: ErrorLevel.warning, fileName: #file, className: "WorkingSessionsManager", functionName: #function, lineNumber: #line, errorDescription: "Failed to convert year (\(currentMonthData.year)), month (\(currentMonthData.month)) and day (\(currentDayData.day)) to human readable string.")
                    castedCell.dateLable.text = "\(currentMonthData.year) \(currentMonthData.month) \(currentDayData.day)"
                }
                
                castedCell.workingDurationLabel.text = TimeInterval.convertSecondsToFormattedString(seconds: currentDayData.totalWorkingDuration)
            }
        } else {
            ErrorLogger.shared.log(errorLevel: ErrorLevel.error, fileName: #file, className: "RawDataViewController", functionName: #function, lineNumber: #line, errorDescription: "The dequeued cell is not an instance of `RawDataTableViewCell`!")
        }
        
        return cell
    }
}
