//
//  UIView+XIB.swift
//  Utils
//
//   Created by maksim.shvetsov on 15.02.2021.
//

import UIKit

extension UIView {
    /**
     * Pass nil as container to add XIB content in current view
     */
    func addContentViewFromXib(_ container: UIView? = nil, useConstraints: Bool = true) {
        let containerView = container ?? self
        let contentSubview = UIView.loadNib(nibName: String(describing: type(of: self)), baseClass: type(of: self), owner: self)
        contentSubview.frame = bounds
        containerView.addSubview(contentSubview)
        if useConstraints {
            contentSubview.translatesAutoresizingMaskIntoConstraints = false
            contentSubview.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
            contentSubview.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
            contentSubview.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
            contentSubview.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        } else {
            contentSubview.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        }
    }
    
    static func loadNib(nibName: String, baseClass: AnyClass, owner: Any) -> UIView {
        let bundle = Bundle(for: baseClass)
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: owner, options: nil).first as! UIView
    }
}
