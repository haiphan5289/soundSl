//
//  MusicCell.swift
//  SoundRain
//
//  Created by Phan Hai on 23/08/2020.
//  Copyright © 2020 Phan Hai. All rights reserved.
//

import UIKit
import Kingfisher

class MusicCell: UICollectionViewCell {

    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var lbTitle: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func updateUI(model: MusicModel) {
        guard let img = model.img else {
            return
        }
        
        guard let url = URL(string: img) else {
            return
        }
        
        self.img.kf.setImage(with: url)
        self.lbTitle.text = model.title
    }

}
