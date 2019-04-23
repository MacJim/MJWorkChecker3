//
//  TodayViewController.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 4/17/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import UIKit

class TodayViewController: UIViewController {
    //MARK: - IB outlets.
    @IBOutlet weak var todayWorkDurationLabel: UILabel!
    @IBOutlet weak var startOrStopWorkingButton: UIButton!

    
    //MARK: - IB actions.
    @IBAction func startOrStopWorkingButtonPressed(_ sender: UIButton) {
        let workingSessionsManager = WorkingSessionsManager.shared
        if (workingSessionsManager.isWorkStarted) {
            //Stop current working session.
            workingSessionsManager.stopWorking()
            stopUpdatingTodayWorkDurationLabelText()
            updateTodayWorkDurationLabelText()
        } else {
            //Start a working session.
            workingSessionsManager.startWorking()
            startUpdatingTodayWorkDurationLabelText()
        }
        
        updateStartOrStopWorkingButtonText()
    }
    
    
    //MARK: - View presenting stuff.
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateTodayWorkDurationLabelText()
        updateStartOrStopWorkingButtonText()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (WorkingSessionsManager.shared.isWorkStarted) {
            startUpdatingTodayWorkDurationLabelText()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopUpdatingTodayWorkDurationLabelText()
    }
    
    
    //MARK: - Today work duration label text update.
    private var updateTodayWorkDurationLabelTextTimer: Timer?
    
    private func startUpdatingTodayWorkDurationLabelText() {
        updateTodayWorkDurationLabelTextTimer?.invalidate()
        updateTodayWorkDurationLabelTextTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(TodayViewController.updateTodayWorkDurationLabelText), userInfo: nil, repeats: true)
    }
    private func stopUpdatingTodayWorkDurationLabelText() {
        updateTodayWorkDurationLabelTextTimer?.invalidate()
        updateTodayWorkDurationLabelTextTimer = nil
    }
    
    @objc private func updateTodayWorkDurationLabelText() {
        let todayWorkingDuration = WorkingSessionsManager.shared.todayWorkingDuration
        
        todayWorkDurationLabel.text = TimeInterval.convertSecondsToFormattedString(seconds: todayWorkingDuration)
    }
    
    
    //MARK: - Start / stop working button text update.
    private func updateStartOrStopWorkingButtonText() {
        if (WorkingSessionsManager.shared.isWorkStarted) {
            startOrStopWorkingButton.setTitle("Stop", for: UIControl.State.normal)
        } else {
            startOrStopWorkingButton.setTitle("Start", for: UIControl.State.normal)
        }
    }
}

