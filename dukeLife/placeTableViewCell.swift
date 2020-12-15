//
//  placeTableViewCell.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/23/20.
//

import UIKit

class placeTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var likeCount: UILabel!
    @IBOutlet weak var likeButton: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
