//
//  ImageGridCell.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/22.
//

import UIKit

open class ImageGridCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    
    static let cellIdentifier = "ImageGridCell"
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.contentView.addSubview(self.imageView)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.imageView)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.contentView.frame
    }
    
    func setImage(as image: UIImage) {
        self.imageView.image = image
    }

}
