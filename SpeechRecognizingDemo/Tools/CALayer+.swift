//
//  CALayer+.swift
//  SpeechRecognizingDemo
//
//  Created by Yuan Cao on 2024/2/5.
//

import UIKit

extension CALayer {

    @IBInspectable
    var borderColorUIColor: UIColor {
        set {
            self.borderColor = newValue.cgColor
            self.borderWidth = 1
        }
        get {
            return  UIColor(cgColor: self.borderColor!)
        }
    }
}
