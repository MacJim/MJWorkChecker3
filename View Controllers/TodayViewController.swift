//
//  TodayViewController.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 4/17/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import UIKit

class TodayViewController: UIViewController {
    // MARK: - IB outlets.
    @IBOutlet weak var todayWorkDurationLabel: UILabel!
    @IBOutlet weak var currentSessionWorkDurationLabel: UILabel!
    
    @IBOutlet weak var tapAnywhereLabel: UILabel!
    
    
    // MARK: - View presenting stuff.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set monospace system font.
        todayWorkDurationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: todayWorkDurationLabel.font.pointSize, weight: UIFont.Weight.regular)
        currentSessionWorkDurationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: currentSessionWorkDurationLabel.font.pointSize, weight: UIFont.Weight.regular)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateWorkDurationLabelsText()
        updateTapAnywhereLabelText()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (WorkingSessionsManager.shared.isWorkStarted) {
            startUpdatingWorkDurationLabelsText()
        }
        
        // Update work duration when app becomes active.
        NotificationCenter.default.addObserver(self, selector: #selector(TodayViewController.updateWorkDurationLabelsText), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopUpdatingWorkDurationLabelsText()
        
        // Stop updating work duration when this view controller is inactive.
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - UIResponder stuff
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        startOrStopWorking()
    }
    
    
    // MARK: - Start / stop working
    func startOrStopWorking() {
        let workingSessionsManager = WorkingSessionsManager.shared
        
        if (workingSessionsManager.isWorkStarted) {
            // Stop current working session.
            workingSessionsManager.stopWorking()
            stopUpdatingWorkDurationLabelsText()
            updateWorkDurationLabelsText()
            updateTapAnywhereLabelText()
        } else {
            // Start a working session.
            workingSessionsManager.startWorking()
            updateWorkDurationLabelsText()    // Update text immediately to give the user a fast response.
            startUpdatingWorkDurationLabelsText()
            updateTapAnywhereLabelText()
        }
    }
    
    
    // MARK: - Today work duration label text update
    /// This timer updates the text of `todayWorkDurationLabel` and `currentSessionWorkDurationLabel`.
    private var updateWorkDurationLabelsTextTimer: Timer?
    
    private func startUpdatingWorkDurationLabelsText() {
        updateWorkDurationLabelsTextTimer?.invalidate()
        updateWorkDurationLabelsTextTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(TodayViewController.updateWorkDurationLabelsText), userInfo: nil, repeats: true)
    }
    private func stopUpdatingWorkDurationLabelsText() {
        updateWorkDurationLabelsTextTimer?.invalidate()
        updateWorkDurationLabelsTextTimer = nil
    }
    
    /// This function is also called when the app launches from the background.
    @objc private func updateWorkDurationLabelsText() {
        let todayWorkingDuration = WorkingSessionsManager.shared.todayWorkingDuration
        todayWorkDurationLabel.text = TimeInterval.convertSecondsToFormattedString(seconds: todayWorkingDuration)
        
        if let currentSessionWorkingDuration = WorkingSessionsManager.shared.currentSessionWorkingDuration {
            currentSessionWorkDurationLabel.text = TimeInterval.convertSecondsToFormattedString(seconds: currentSessionWorkingDuration)
        } else {
            // Current session has not started.
            currentSessionWorkDurationLabel.text = "N/A"
        }
    }
    
    
    // MARK: - "Tap anywhere" label text update
    private func updateTapAnywhereLabelText() {
        if (WorkingSessionsManager.shared.isWorkStarted) {
            tapAnywhereLabel.text = "Tap anywhere to stop."
        } else {
            tapAnywhereLabel.text = "Tap anywhere to start."
        }
    }
}

