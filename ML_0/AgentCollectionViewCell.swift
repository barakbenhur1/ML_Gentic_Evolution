//
//  AgentCollectionViewCell.swift
//  ML_0
//
//  Created by Interactech on 22/06/2021.
//

import UIKit

class AgentCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var container: UIStackView!
    @IBOutlet weak var nuOfAgents: UILabel!
    @IBOutlet weak var first: UILabel!
    @IBOutlet weak var seconed: UILabel!
    
    func set(title: String, sub:  String) {
        first.text = title
        seconed.text = sub
        
        container.layer.cornerRadius = 20
        
        container.layer.shadowPath = UIBezierPath(rect: container.bounds).cgPath
        
        container.layer.shouldRasterize = true
        
        container.layer.rasterizationScale = UIScreen.main.scale
    }
}
