//
//  MPHManager.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/23.
//

import Foundation
import UIKit
import Photos

public protocol MPHManagerDelegate: NSObject {}

extension MPHManagerDelegate {
    func didFillUpImageAssets() {}
}

open class MPHManager: NSObject {
    
    @objc dynamic var selected: [String] = []
    public var selectedImageAssets: [UIImage] = []
    public static let shared = MPHManager()
    public weak var delegate: MPHManagerDelegate?
    public var maxImageCount: Int {
        get {
            Self.Config.maxImage
        }
        set {
            Self.Config.maxImage = newValue
        }
    }
    
    private override init() {}
    
    
    enum Config {
        static var borderColor: UIColor = UIColor.white.withAlphaComponent(0.3)
        static var borderWidth: CGFloat = 2
        static var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3)
        static var selectedColor: UIColor = UIColor.systemBlue
        static var maxImage: Int = 5
    }
    
    @discardableResult
    public func reset() -> MPHManager {
        self.selectedImageAssets.removeAll()
        self.selected.removeAll()
        return self
    }
    
    @discardableResult
    public func setMaxImage(_ numberOfImages: Int) -> MPHManager {
        MPHManager.Config.maxImage = numberOfImages
        return self
    }
}
