//
//  commentTableViewCell.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/25/20.
//

import UIKit

class commentTableViewCell: UITableViewCell {

    @IBOutlet weak var comment: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sizeToFit()
        layoutIfNeeded()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
