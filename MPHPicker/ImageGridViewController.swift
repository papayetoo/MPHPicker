//
//  ImageGridViewController.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/22.
//

import UIKit
import Photos

open class ImageGridViewController: UIViewController {
    
    private let imageGridCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }()
    
    private var allPhotos: PHFetchResult<PHAsset>? {
        didSet {
            self.imageGridCollectionView.reloadData()
        }
    }
    
    private let imageManager = PHCachingImageManager()

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.allPhotos = PHAsset.fetchAssets(with: nil)
        PHPhotoLibrary.shared().register(self)
        
        self.view.addSubview(self.imageGridCollectionView)
        self.imageGridCollectionView.delegate = self
        self.imageGridCollectionView.dataSource = self
        self.imageGridCollectionView.register(ImageGridCell.self, forCellWithReuseIdentifier: ImageGridCell.cellIdentifier)
    }
    
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.imageGridCollectionView.frame = self.view.frame
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

}

extension ImageGridViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        let oldPhotos = PHAsset.fetchAssets(with: nil)
        if let changeDetail = changeInstance.changeDetails(for: oldPhotos) {
            self.allPhotos = changeDetail.fetchResultAfterChanges
        }
    }
}

extension ImageGridViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageGridCell.cellIdentifier, for: indexPath) as? ImageGridCell,
              let asset = self.allPhotos?.object(at: indexPath.item) else {
            return UICollectionViewCell()
        }
        
        let width = view.bounds.inset(by: view.safeAreaInsets).width
        let insets = self.view.safeAreaInsets
        let size = CGSize(width: self.view.frame.width / 3 - 2, height: self.view.frame.height / 5  - 4)
        self.imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: nil, resultHandler: {(imageOrNil, _) in
            guard let image = imageOrNil else {
                return
            }
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    let resizedImage = image.resize(to: self.view.frame.width / 3 - 2)
                    cell.setImage(as: resizedImage)
                }
            }
        })
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.allPhotos?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width / 3 - 2, height: self.view.frame.height / 5 - 4)
    }
}
