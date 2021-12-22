//
//  UIImage+Extension.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/22.
//

import UIKit

extension UIImage {
    func resize(to nWidth: CGFloat) -> UIImage {
        let scale = nWidth / self.size.width
        let nHeight = scale * self.size.height
        let nSize = CGSize(width: nWidth, height: nHeight)
        let renderer = UIGraphicsImageRenderer(size: nSize)
        let newImage = renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: nSize))
        }
        return newImage
    }
    
    func resize(to targetSize: CGSize) -> UIImage {
        let widthScale = targetSize.width / self.size.width
        let heightScale = targetSize.height / self.size.height
        
        let scale = max(widthScale, heightScale)
        
        let newSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
