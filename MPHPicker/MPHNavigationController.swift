//
//  MPHNavigationController.swift
//  MPHPicker
//
//  Created by 최광현 on 2021/12/23.
//

import UIKit
import Photos

protocol MPHNavigationDelegate: NSObject {
    func didChangeAssets(_ assets: PHFetchResult<PHAsset>?)
}

public protocol MPHUploadDelegate: NSObject {
    func willUploadSelectedImageAssets()
}

open class MPHNavigationController: UINavigationController {
    
    private let backButton = UIButton()
    
    private var allPhotos: PHFetchResult<PHAsset>!
    private var userCollections: PHFetchResult<PHCollection>!
    
    private lazy var assetsListBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(title: "모든 사진", style: .plain, target: self, action: #selector(didTouchAssetsListBarButton))
        return barButtonItem
    }()
    
    private lazy var leftBackButton = UIBarButtonItem(title: "뒤로", style: .plain, target: self, action: #selector(didTouchBackButton))
    
    private lazy var imageCountBarButtonItem = UIBarButtonItem(title: "0", style: .plain, target: nil, action: nil)
    private lazy var uploadBarButtonItem = UIBarButtonItem(title: "올리기", style: .plain, target: self, action: #selector(didTouchUploadButton))
    
    weak var mphNavigationDelegate: MPHNavigationDelegate?
    public weak var mphUploadDelegate: MPHUploadDelegate?
    
    private var fetchingOptions: PHFetchOptions = {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return options
    }()
    
    private let imageManager: PHCachingImageManager = PHCachingImageManager()
    
    private var assetsListBarButtonTouchObserver: NSKeyValueObservation?
    private var selectedObserver: NSKeyValueObservation?
    
    private lazy var assetsListView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MPHAssetCell.self, forCellReuseIdentifier: MPHAssetCell.cellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        self.allPhotos = PHAsset.fetchAssets(with: self.fetchingOptions)
        self.userCollections = PHCollection.fetchTopLevelUserCollections(with: nil)
        PHPhotoLibrary.shared().register(self)
        
        self.selectedObserver = MPHManager.shared.observe(\.selected, options: [.old, .new]) {[weak self](_, change) in
            guard let `self` = self, let newValue = change.newValue else {return}
            self.imageCountBarButtonItem.title = "\(newValue.count)"
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.allPhotos = PHAsset.fetchAssets(with: self.fetchingOptions)
        self.userCollections = PHCollection.fetchTopLevelUserCollections(with: nil)
        PHPhotoLibrary.shared().register(self)
    }
    
    public convenience init() {
        let gridVC = ImageGridViewController()
        self.init(rootViewController: gridVC)
        self.mphNavigationDelegate = gridVC
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationBar.tintColor = .black
        self.navigationBar.backgroundColor = .white
        self.navigationBar.topItem?.leftBarButtonItems = [leftBackButton, assetsListBarButtonItem]
        imageCountBarButtonItem.setTitleTextAttributes([.foregroundColor:UIColor.systemBlue], for: .normal)
        self.navigationBar.topItem?.rightBarButtonItems = [uploadBarButtonItem, imageCountBarButtonItem ]
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        self.selectedObserver?.invalidate()
    }
    
    
}

extension MPHNavigationController {
    @objc
    private func didTouchBackButton(_ sender: UIButton) {
        MPHManager.shared.selected.removeAll()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    private func didTouchUploadButton() {
        self.dismiss(animated: true) {[weak self] in
            self?.mphUploadDelegate?.willUploadSelectedImageAssets()
        }
    }
    
    @objc
    private func didTouchAssetsListBarButton(_ sender: AnyObject) {
        guard let topView = self.topViewController?.view else {
            return
        }
        topView.addSubview(self.assetsListView)
        NSLayoutConstraint.activate([
            self.assetsListView.topAnchor.constraint(equalTo: topView.safeAreaLayoutGuide.topAnchor),
            self.assetsListView.bottomAnchor.constraint(equalTo: topView.bottomAnchor),
            self.assetsListView.leadingAnchor.constraint(equalTo: topView.safeAreaLayoutGuide.leadingAnchor),
            self.assetsListView.trailingAnchor.constraint(equalTo: topView.safeAreaLayoutGuide.trailingAnchor),
        ])
    }
}

extension MPHNavigationController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            if let changeDetails = changeInstance.changeDetails(for: self.allPhotos) {
                self.allPhotos = changeDetails.fetchResultAfterChanges
            }
            
            if let changeDetails = changeInstance.changeDetails(for: self.userCollections) {
                self.userCollections = changeDetails.fetchResultAfterChanges
            }
        }
    }
}

extension MPHNavigationController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userCollections.count + 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MPHAssetCell.cellIdentifier, for: indexPath) as? MPHAssetCell else {return UITableViewCell()}
        let row = indexPath.row
        var firstImageAsset: PHAsset?
        switch row {
        case 0:
            cell.collectionTitleLabel.text = "모든 사진"
            firstImageAsset = self.allPhotos.object(at: 0)
        case 1...:
            guard let collection = self.userCollections.object(at: row - 1) as? PHAssetCollection else {return UITableViewCell()}
            cell.collectionTitleLabel.text = collection.localizedTitle
            let collectionAssets = PHAsset.fetchAssets(in: collection, options: fetchingOptions)
            if collectionAssets.count <= 0 {break}
            firstImageAsset = collectionAssets.object(at: 0)
        default:
            break
        }
        let scale = UIScreen.main.scale
        let size = CGSize(width: 50 * scale, height: 50 * scale)
        guard let firstImageAsset = firstImageAsset else {
            return cell
        }
        self.imageManager.requestImage(for: firstImageAsset,
                                          targetSize: size,
                                          contentMode: .aspectFit,
                                          options: nil)
        {(image, _) in
            DispatchQueue.main.async {
                cell.thumbnailImageView.image = image
            }
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            MPHManager.shared.selected.removeAll()
            DispatchQueue.main.async {
                self.assetsListView.removeFromSuperview()
            }
        }
        let row = indexPath.row
        var title: String? = nil
        var changedAsset: PHFetchResult<PHAsset>? = nil
        switch row {
        case 0:
            title = "모든 사진"
            changedAsset = allPhotos
        case 1...:
            guard let collection = self.userCollections.object(at: row - 1) as? PHAssetCollection else {return}
            title = collection.localizedTitle
            changedAsset = PHAsset.fetchKeyAssets(in: collection, options: fetchingOptions)
        default:
            title = ""
        }
        self.assetsListBarButtonItem.title = title
        self.mphNavigationDelegate?.didChangeAssets(changedAsset)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
