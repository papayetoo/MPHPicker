//
//  UIImage+Extension.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/22.
//

import UIKit

extension UIImage {
    func resize(newWidth: CGFloat) -> UIImage {
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        let size = CGSize(width: newWidth, height: newHeight)
        let render = UIGraphicsImageRenderer(size: size)
        let renderImage = render.image { context in self.draw(in: CGRect(origin: .zero, size: size)) }
        print("화면 배율: \(UIScreen.main.scale)")
        // 배수 print("origin: \(self), resize: \(renderImage)") printDataSize(renderImage)
        return renderImage
    }
    
    func resize(to targetSize: CGSize) -> UIImage {
        let widthScale = targetSize.width / self.size.width
        let heightScale = targetSize.height / self.size.height
        
        let scale = max(widthScale, heightScale)
        
        let newSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let newImage = renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return newImage
    }
}
