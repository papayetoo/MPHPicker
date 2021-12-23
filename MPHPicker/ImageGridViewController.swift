//
//  ImageGridViewController.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/22.
//

import UIKit
import Photos

protocol ImageGridViewDelegate: NSObject {
    func didFillUpAssets()
}

open class ImageGridViewController: UIViewController {
    
    private let imageGridCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }()
    
    private var fetchingAssets: PHFetchResult<PHAsset>? {
        didSet {
            self.imageGridCollectionView.reloadData()
        }
    }
    
    private let imageManager = PHCachingImageManager()
    
    weak var delegate: ImageGridViewDelegate?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fetchingAssets = PHAsset.fetchAssets(with: nil)
        PHPhotoLibrary.shared().register(self)
        
        self.view.addSubview(self.imageGridCollectionView)
        self.imageGridCollectionView.delegate = self
        self.imageGridCollectionView.dataSource = self
        self.imageGridCollectionView.register(MPHGridCell.self, forCellWithReuseIdentifier: MPHGridCell.cellIdentifier)
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
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let oldPhotos = PHAsset.fetchAssets(with: fetchOptions)
        if let changeDetail = changeInstance.changeDetails(for: oldPhotos) {
            self.fetchingAssets = changeDetail.fetchResultAfterChanges
        }
    }
}

extension ImageGridViewController: MPHNavigationDelegate {
    func didChangeAssets(_ assets: PHFetchResult<PHAsset>?) {
        self.fetchingAssets = assets
    }
}

extension ImageGridViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MPHGridCell.cellIdentifier, for: indexPath) as? MPHGridCell,
              let asset = self.fetchingAssets?.object(at: indexPath.item) else {
            return UICollectionViewCell()
        }
        
        let width = self.view.frame.width / 3 - 2
        let scale = UIScreen.main.scale
        let size = CGSize(width: width * scale, height: width * scale)
        cell.assetIdentifier = asset.localIdentifier
        self.imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil, resultHandler: {(imageOrNil, _) in
            guard let image = imageOrNil else {
                return
            }
            DispatchQueue.main.async {
                cell.setImage(as: image)
            }
        })
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchingAssets?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.view.frame.width / 3 - 2
        return CGSize(width: width, height: width)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MPHGridCell else {return}
        cell.changeSelectedAssets()
    }
}
