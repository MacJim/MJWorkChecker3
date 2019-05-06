//
//  RawDataTableViewCell.swift
//  MJWorkChecker3
//
//  Created by Jim Macintosh Shi on 5/6/19.
//  Copyright © 2019 Creative Sub. All rights reserved.
//

import UIKit

class RawDataTableViewCell: UITableViewCell {
    //MARK: - IB outlets.
    @IBOutlet weak var dateLable: UILabel!
    @IBOutlet weak var workingDurationLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
