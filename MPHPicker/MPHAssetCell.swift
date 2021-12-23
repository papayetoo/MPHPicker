//
//  MPHAssetCell.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/23.
//

import UIKit

class MPHAssetCell: UITableViewCell {
    
    static let cellIdentifier = "MPHAssetCell"
    
    let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let collectionTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.addSubview(collectionTitleLabel)
        self.contentView.addSubview(thumbnailImageView)
        self.setThumnailImageView()
        self.setCollectionTitleLabel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.contentView.addSubview(collectionTitleLabel)
        self.contentView.addSubview(thumbnailImageView)
        self.setThumnailImageView()
        self.setCollectionTitleLabel()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(collectionTitleLabel)
        self.contentView.addSubview(thumbnailImageView)
        self.setThumnailImageView()
        self.setCollectionTitleLabel()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    private func setThumnailImageView() {
        let width: CGFloat = 50
        let height: CGFloat = 50
        NSLayoutConstraint.activate([
            self.thumbnailImageView.widthAnchor.constraint(equalToConstant: width),
            self.thumbnailImageView.heightAnchor.constraint(equalToConstant: height),
            self.thumbnailImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
            self.thumbnailImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10)
        ])
    }
    
    private func setCollectionTitleLabel() {
        NSLayoutConstraint.activate([
            self.collectionTitleLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            self.collectionTitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            self.collectionTitleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 70)
        ])
    }
}
