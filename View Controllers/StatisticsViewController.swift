//
//  SecondViewController.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 4/17/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import UIKit

class StatisticsViewController: UIViewController {
    //MARK: - IB outlets.
    @IBOutlet weak var past7DaysWorkDurationLabel: UILabel!
    @IBOutlet weak var past30DaysWorkDurationLabel: UILabel!
    
    @IBOutlet weak var overallOrDailyAverageSegmentedControl: UISegmentedControl!
    
    
    //MARK: - IB actions.
    @IBAction func overallOrDailyAverageSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        updateWorkDurationLabelsText()
    }
    
    
    //MARK: - View presenting stuff.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set monospace system font.
        past7DaysWorkDurationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: past7DaysWorkDurationLabel.font.pointSize, weight: UIFont.Weight.regular)
        past30DaysWorkDurationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: past30DaysWorkDurationLabel.font.pointSize, weight: UIFont.Weight.regular)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateWorkDurationLabelsText()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (WorkingSessionsManager.shared.isWorkStarted) {
            startUpdatingWorkDurationLabelsText()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopUpdatingWorkDurationLabelsText()
    }
    
    
    //MARK: - Update work duration.
    private var updateWorkDurationLabelsTextTimer: Timer?
    
    private func startUpdatingWorkDurationLabelsText() {
        updateWorkDurationLabelsTextTimer?.invalidate()
        updateWorkDurationLabelsTextTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(StatisticsViewController.updateWorkDurationLabelsText), userInfo: nil, repeats: true)
    }
    private func stopUpdatingWorkDurationLabelsText() {
        updateWorkDurationLabelsTextTimer?.invalidate()
        updateWorkDurationLabelsTextTimer = nil
    }
    
    @objc func updateWorkDurationLabelsText() {
        let past7DaysWorkingDuration = WorkingSessionsManager.shared.past7DaysWorkingDuration
        let past30DaysWorkingDuration = WorkingSessionsManager.shared.past30DaysWorkingDuration
        
        if (overallOrDailyAverageSegmentedControl.selectedSegmentIndex == 0) {
            //Overall.
            past7DaysWorkDurationLabel.text = TimeInterval.convertSecondsToFormattedString(seconds: past7DaysWorkingDuration)
            past30DaysWorkDurationLabel.text = TimeInterval.convertSecondsToFormattedString(seconds: past30DaysWorkingDuration)
        } else {
            //Daily average.
            let past7DaysAverageWorkingDuration = past7DaysWorkingDuration / 7
            let past30DaysAverageWorkingDuration = past30DaysWorkingDuration / 30
            
            past7DaysWorkDurationLabel.text = TimeInterval.convertSecondsToFormattedString(seconds: past7DaysAverageWorkingDuration)
            past30DaysWorkDurationLabel.text = TimeInterval.convertSecondsToFormattedString(seconds: past30DaysAverageWorkingDuration)
        }
    }
}

