//
//  UICollectionView+Extension.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/24.
//

import Foundation
import UIKit

extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let attributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return attributes.map {$0.indexPath}
    }
}
