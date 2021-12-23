//
//  ImageGridCell.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/22.
//

import UIKit

open class MPHGridCell: UICollectionViewCell {
    
    private let opaqueView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isHidden = true
        return view
    }()
    private let imageView = UIImageView()
    let circleButton: UIButton = { rect in
        let button = UIButton(frame: rect)
        button.layer.borderColor = MPHManager.MPHGridCircleConfiguration.borderColor.cgColor
        button.layer.borderWidth = MPHManager.MPHGridCircleConfiguration.borderWidth
        button.layer.cornerRadius = rect.width / 2
        button.backgroundColor = MPHManager.MPHGridCircleConfiguration.backgroundColor
        
        button.setTitleColor(.white, for: .selected)
        return button
    }(CGRect(origin: .zero, size: CGSize(width: 26, height: 26)))
    
    static let cellIdentifier = "MPHGridCell"
    
    public typealias AssetIdentifier = String

    var assetIdentifier: AssetIdentifier? {
        didSet {
            guard let assetIdentifier = assetIdentifier,
                  let index = MPHManager.shared.selected.firstIndex(where: {$0 == assetIdentifier}) else {return}
            self.circleButton.isSelected = true
            self.imageView.layer.borderWidth = MPHManager.MPHGridCircleConfiguration.borderWidth
            self.imageView.layer.borderColor = MPHManager.MPHGridCircleConfiguration.selectedBackground.cgColor
            self.opaqueView.isHidden = false
            self.circleButton.backgroundColor = MPHManager.MPHGridCircleConfiguration.selectedBackground
            self.circleButton.setTitle("\(index + 1)", for: .selected)
        }
    }
    var selectionObserver: NSKeyValueObservation?
    var selectedObserver: NSKeyValueObservation?
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        dump("ImageGridCell init with coder")
        self.contentView.addSubview(self.imageView)
        self.imageView.addSubview(self.opaqueView)
        self.contentView.addSubview(self.circleButton)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        dump("ImageGridCell init with frame")
        self.contentView.addSubview(self.imageView)
        self.imageView.addSubview(self.opaqueView)
        self.contentView.addSubview(self.circleButton)
        
        self.circleButton.addTarget(self, action: #selector(changeSelectedAssets), for: .touchUpInside )
        
//        self.selectionObserver = self.circleButton.observe(\.isSelected, options: [.old, .new]) {[weak self] (button, change) in
//            guard let `self` = self,
//                  let newValue = change.newValue,
//                  let assetIdentifier = self.assetIdentifier else {return}
//
//            self.opaqueView.isHidden = !newValue
//            self.circleButton.backgroundColor = newValue ? MPHManager.MPHGridCircleConfiguration.selectedBackground : MPHManager.MPHGridCircleConfiguration.backgroundColor
//            self.imageView.layer.borderWidth = newValue ? 2 : 0
//            self.imageView.layer.borderColor = newValue ? MPHManager.MPHGridCircleConfiguration.selectedBackground.cgColor : UIColor.clear.cgColor
//        }
        
        self.selectedObserver = MPHManager.shared.observe(\.selected, options: [.old, .new], changeHandler: {[weak self] (_, change) in
            guard let `self` = self,
                  let newSelected = change.newValue,
                  let assetIdentifier = self.assetIdentifier else {return}
            let assetIsSelected = MPHManager.shared.selected.contains(assetIdentifier)
            self.opaqueView.isHidden = !assetIsSelected
            self.circleButton.backgroundColor = assetIsSelected ? MPHManager.MPHGridCircleConfiguration.selectedBackground : MPHManager.MPHGridCircleConfiguration.backgroundColor
            self.imageView.layer.borderWidth = assetIsSelected ? 2 : 0
            self.imageView.layer.borderColor = assetIsSelected ? MPHManager.MPHGridCircleConfiguration.selectedBackground.cgColor : UIColor.clear.cgColor
            self.circleButton.isSelected = assetIsSelected
            guard let index = newSelected.firstIndex(where: {$0 == assetIdentifier}) else {return}
            self.circleButton.setTitle("\(index + 1)", for: .selected)
        })
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.contentView.frame
        self.opaqueView.frame = self.imageView.frame
        self.circleButton.frame.origin.x = self.contentView.frame.maxX - 34
        self.circleButton.frame.origin.y = self.contentView.frame.minY + 8
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.imageView.layer.borderColor = UIColor.clear.cgColor
        self.imageView.layer.borderWidth = 0
        self.circleButton.backgroundColor = MPHManager.MPHGridCircleConfiguration.backgroundColor
        self.opaqueView.isHidden = true
        self.circleButton.isSelected = false
    }
    
    deinit{
        self.selectionObserver?.invalidate()
        self.selectedObserver?.invalidate()
    }
    
    func setImage(as image: UIImage) {
        self.imageView.image = image
//        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
    }
    
    @objc
    func changeSelectedAssets() {
        guard let assetIdentifier = assetIdentifier else {
            return
        }
        if !MPHManager.shared.selected.contains(assetIdentifier) {
            if MPHManager.shared.selected.count >= MPHManager.MPHGridCircleConfiguration.maxImage {
                MPHManager.shared.delegate?.didFillUpImageAssets()
                return
            }
            MPHManager.shared.selected.append(assetIdentifier)
            MPHManager.shared.selectedImageAssets.append(self.imageView.image ?? UIImage())
        } else {
            guard let index = MPHManager.shared.selected.firstIndex(where: {$0 == assetIdentifier}) else {return}
            MPHManager.shared.selected.remove(at: index)
            MPHManager.shared.selectedImageAssets.remove(at: index)
        }
        
    }
}
