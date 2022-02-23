//
//  ImageGridViewController.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/22.
//

import UIKit
import Photos

public protocol ImageGridViewDelegate: NSObject {
    func didFillUpAssets()
}

open class MPHGridViewController: UIViewController {
    
    private let gridCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        return collectionView
    }()
    
    private var fetchingAssets: PHFetchResult<PHAsset>! {
        didSet {
            DispatchQueue.main.async {
                self.gridCollectionView.reloadData()
            }
        }
    }
    
    private var previousPreaheatRect = CGRect.zero
    
    public weak var delegate: ImageGridViewDelegate?

    public override func viewDidLoad() {
        super.viewDidLoad()
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.fetchingAssets = PHAsset.fetchAssets(with: options)
        PHPhotoLibrary.shared().register(self)
        
        self.view.addSubview(self.gridCollectionView)
        self.gridCollectionView.delegate = self
        self.gridCollectionView.dataSource = self
        self.gridCollectionView.register(MPHGridCell.self, forCellWithReuseIdentifier: MPHGridCell.cellIdentifier)
    }
    
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.gridCollectionView.frame = self.view.frame
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

}

extension MPHGridViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let changeDetail = changeInstance.changeDetails(for: self.fetchingAssets) {
            self.fetchingAssets = changeDetail.fetchResultAfterChanges
        }
    }
    
    fileprivate func updateCachedAssets() {
        guard isViewLoaded && view.window != nil else {return}
        
        let visibleRect = CGRect(origin: self.gridCollectionView.contentOffset,
                                 size: self.gridCollectionView.bounds.size)
        let preaheatRect = visibleRect.insetBy(dx: 0, dy: -5 * visibleRect.height)
        let delta = abs(preaheatRect.midY - self.previousPreaheatRect.midY)
        guard delta > view.bounds.height / 5 else {return}
        
        let (addedRects, removedRects) = self.differencesBetweenRects(self.previousPreaheatRect, preaheatRect)
        let addAssets = addedRects
            .flatMap {rect in gridCollectionView.indexPathsForElements(in: rect)}
            .map {indexPath in fetchingAssets.object(at: indexPath.item)}
        let removeAssets = removedRects
            .flatMap {rect in gridCollectionView.indexPathsForElements(in: rect)}
            .map {indexPath in fetchingAssets.object(at: indexPath.item)}
        
        let width = self.view.frame.width / 3 - 2
        let scale = UIScreen.main.scale
        let size = CGSize(width: width * scale, height: width * scale)
        DispatchQueue.global().async {
            MPHManager.shared.imageManager.startCachingImages(for: addAssets, targetSize: size, contentMode: .aspectFill, options: nil)
            MPHManager.shared.imageManager.stopCachingImages(for: removeAssets, targetSize: size, contentMode: .aspectFill, options: nil)
        }
        
        self.previousPreaheatRect = preaheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: new.origin.y,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.origin.y,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.origin.y,
                                 width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: new.origin.y,
                                 width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}

extension MPHGridViewController {
    @discardableResult
    public func setImageGridViewDelegate(_ delegate: ImageGridViewDelegate?) -> MPHGridViewController{
        self.delegate = delegate
        return self
    }
}

extension MPHGridViewController: MPHNavigationDelegate {
    func didChangeAssets(_ assets: PHFetchResult<PHAsset>?) {
        self.fetchingAssets = assets
    }
}

extension MPHGridViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MPHGridCell.cellIdentifier, for: indexPath) as? MPHGridCell,
              let asset = self.fetchingAssets?.object(at: indexPath.item) else {
            return UICollectionViewCell()
        }
        
        let width = self.view.frame.width / 3 - 2
        let scale = UIScreen.main.scale
        let size = CGSize(width: CGFloat(asset.pixelWidth) * scale, height: CGFloat(asset.pixelHeight) * scale)
        cell.assetIdentifier = asset.localIdentifier
        DispatchQueue.global().async {
            MPHManager.shared.imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil, resultHandler: {(imageOrNil, _) in
                guard let image = imageOrNil, cell.assetIdentifier == asset.localIdentifier else {
                    return
                }
                DispatchQueue.main.async {
                    cell.setImage(as: image)
                }
            })
        }
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
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? MPHGridCell,
              let assetIdentifer = cell.assetIdentifier else {
            return
        }
        
        // assetIdentifier를 가지고 있을 때는
        guard !MPHManager.shared.selected.contains(assetIdentifer) else {
            cell.changeSelectedAssets()
            return
        }
        
        // 최대 선택보다 작을 때는
        guard MPHManager.shared.selectedImageAssets.count >= MPHManager.Config.maxImage else {
            cell.changeSelectedAssets()
            return
        }
        self.delegate?.didFillUpAssets()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateCachedAssets()
    }
}
