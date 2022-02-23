//
//  ImageViewController.swift
//  MPHPickerExample
//
//  Created by 최광현 on 2022/02/23.
//

import UIKit

class ImageViewController: UIViewController {
    
    var image: UIImage? {
        didSet {
            DispatchQueue.main.async {[weak self] in
                self?.imageView.image = self?.image
            }
        }
    }
    
    private let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.contentMode = .scaleAspectFit
        self.view.addSubview(self.imageView)
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.imageView.frame = self.view.frame
    }


}
