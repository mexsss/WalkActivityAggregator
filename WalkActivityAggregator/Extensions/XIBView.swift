//
//  XIBView.swift
//  Utils
//
//   Created by maksim.shvetsov on 15.02.2021.
//

import UIKit

class XIBView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupXIB()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupXIB()
    }
    
    public func setupXIB() {
        backgroundColor = .clear
        clipsToBounds = true
        
        addContentViewFromXib()
    }
}
