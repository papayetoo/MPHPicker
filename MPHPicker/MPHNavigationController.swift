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
    private var userCollections: PHFetchResult<PHAssetCollection>!
    
    private lazy var assetsListBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(title: "모든 사진", style: .plain, target: self, action: #selector(didTouchAssetsListBarButton))
        return barButtonItem
    }()
    
    private lazy var leftBackButton = UIBarButtonItem(title: "뒤로", style: .plain, target: self, action: #selector(didTouchBackButton))
    
    public var leftBackImage: UIImage? {
        didSet {
            self.leftBackButton.title = ""
            self.leftBackButton.image = leftBackImage
        }
    }
    
    private lazy var imageCountButton = UIBarButtonItem(title: "0", style: .plain, target: nil, action: nil)
    private lazy var uploadButton = UIBarButtonItem(title: "올리기", style: .plain, target: self, action: #selector(didTouchUploadButton))
    
    private var imageGridViewController: MPHGridViewController?

    private var defaultImage = UIImage()
    
    weak var mphNavigationDelegate: MPHNavigationDelegate?
    public weak var mphUploadDelegate: MPHUploadDelegate?
    
    private var creationDateOptions: PHFetchOptions = {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return options
    }()
    
    private var assetCountOptions: PHFetchOptions = {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        return options
    }()
    
    private let imageManager: PHCachingImageManager = PHCachingImageManager()
    
    private var assetsListBarButtonTouchObserver: NSKeyValueObservation?
    private var selectedObserver: NSKeyValueObservation?
    
    @objc dynamic private var isAssetsCollectionBarButtonTouched: Bool = false
    
    private lazy var assetsListView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MPHAssetCell.self, forCellReuseIdentifier: MPHAssetCell.cellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        self.allPhotos = PHAsset.fetchAssets(with: self.creationDateOptions)
        self.userCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumUserLibrary, options: self.assetCountOptions)
        PHPhotoLibrary.shared().register(self)
        
        self.selectedObserver = MPHManager.shared.observe(\.selected, options: [.old, .new]) {[weak self](_, change) in
            guard let `self` = self, let newValue = change.newValue else {return}
            self.imageCountButton.title = "\(newValue.count)"
        }
        
        self.assetsListBarButtonTouchObserver = self.observe(\.isAssetsCollectionBarButtonTouched, options: .new) {[weak self] (_, change) in
            guard let `self` = self, let newValue = change.newValue else {return}
            newValue ? self.willShowAssetsCollectionList() : self.willHideAssetsCollectionList()
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.allPhotos = PHAsset.fetchAssets(with: self.creationDateOptions)
        PHPhotoLibrary.shared().register(self)
    }
   
   
    public override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
        self.allPhotos = PHAsset.fetchAssets(with: self.creationDateOptions)
        self.userCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumUserLibrary, options: self.assetCountOptions)
        PHPhotoLibrary.shared().register(self)
        
        self.selectedObserver = MPHManager.shared.observe(\.selected, options: [.old, .new]) {[weak self](_, change) in
            guard let `self` = self, let newValue = change.newValue else {return}
            self.imageCountButton.title = "\(newValue.count)"
        }
        
        self.assetsListBarButtonTouchObserver = self.observe(\.isAssetsCollectionBarButtonTouched, options: .new) {[weak self] (_, change) in
            guard let `self` = self, let newValue = change.newValue else {return}
            newValue ? self.willShowAssetsCollectionList() : self.willHideAssetsCollectionList()
        }
    }
    
    public convenience init() {
        let gridVC = MPHGridViewController()
        self.init(rootViewController: gridVC)
        self.mphNavigationDelegate = gridVC
        self.imageGridViewController = gridVC
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationBar.tintColor = .black
        self.navigationBar.barTintColor = .white
        self.navigationBar.backgroundColor = .white
        self.navigationBar.topItem?.leftBarButtonItems = [leftBackButton, assetsListBarButtonItem]
        self.imageCountButton.setTitleTextAttributes([.foregroundColor:UIColor.systemBlue], for: .normal)
        self.navigationBar.topItem?.rightBarButtonItems = [uploadButton, imageCountButton ]
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        self.assetsListBarButtonTouchObserver?.invalidate()
        self.selectedObserver?.invalidate()
    }
    
    
}

// MARK: - Utility functions
extension MPHNavigationController {
    @discardableResult
    public func setMPHUploadDelegete(_ delegate: MPHUploadDelegate) -> MPHNavigationController {
        self.mphUploadDelegate = delegate
        return self
    }
    
    @discardableResult
    public func setLeftBackButton(as otherImage: UIImage?) -> MPHNavigationController {
        self.leftBackButton.title = nil
        self.leftBackButton.image = otherImage
        return self
    }
    
    @discardableResult
    public func setImageGridViewDelegate(_ delegate: ImageGridViewDelegate) -> MPHNavigationController {
        self.imageGridViewController?.delegate = delegate
        return self
    }
    
    
    @discardableResult
    public func setDefaultImage(as image: UIImage?) -> MPHNavigationController {
        guard let image = image else {
            return self
        }
        self.defaultImage = image
        return self
    }
}

// MARK: - Handle Events
extension MPHNavigationController {
    @objc
    private func didTouchBackButton(_ sender: UIButton) {
        MPHManager.shared.reset()
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
        self.isAssetsCollectionBarButtonTouched.toggle()
    }
    
    private func willShowAssetsCollectionList() {
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
    
    private func willHideAssetsCollectionList() {
        self.assetsListView.removeFromSuperview()
    }
}

// MARK: - PhotoLibraryChangeObserver
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

// MARK: - UITableViewDataSource, UITableViewDelegate
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
            cell.collectionTitleLabel.text = String(format: "모든 사진 (%d)", self.allPhotos.count)
            firstImageAsset = self.allPhotos.count > 0 ? self.allPhotos.object(at: 0) : nil
        case 1...:
            guard row - 1 >= 0 else {return UITableViewCell()}
            let collection = self.userCollections.object(at: row - 1)
            let collectionAssets = PHAsset.fetchAssets(in: collection, options: creationDateOptions)
            if collectionAssets.count <= 0 {return UITableViewCell()}
            cell.collectionTitleLabel.text = String(format: "\(collection.localizedTitle ?? "") (%d)", collectionAssets.count)
            firstImageAsset = collectionAssets.count > 0 ? collectionAssets.object(at: 0) : nil
        default:
            break
        }
        let scale = UIScreen.main.scale
        let size = CGSize(width: 50 * scale, height: 50 * scale)
        guard let firstImageAsset = firstImageAsset else {
            cell.thumbnailImageView.image = self.defaultImage
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
            changedAsset = PHAsset.fetchAssets(with: self.creationDateOptions)
        case 1...:
            let collection = self.userCollections.object(at: row - 1)
            title = collection.localizedTitle
            changedAsset = PHAsset.fetchAssets(in: collection, options: creationDateOptions)
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

