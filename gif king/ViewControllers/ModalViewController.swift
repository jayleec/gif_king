//
//  ContainerViewController.swift
//  gif king
//
//  Created by Jae Kyung Lee on 29/05/2018.
//  Copyright © 2018 Jae Kyung Lee. All rights reserved.
//

import UIKit
import GiphyCoreSDK

protocol ModalViewControllerDelegate: class {
    func addGif(url: String)
    func pickPicture()
    func expandContainerView()
    func closeExpandedView()
}

class ModalViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var placeholderView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private struct Constants {
        static let GIPHYKey = "YOUR GIPHY KEY"
        static let Inset = 4
        static let Space = 4
        static let InitialSearchTerm = "dog"
        static let Columns = 3
        static let Height = 90
    }
    
    // MARK: Properties
    
    weak var delegate: ModalViewControllerDelegate?
    let searchController = UISearchController(searchResultsController: nil)
    
    var stickerData: [Sticker] = []
    var offset = 0
    
    // MARK: Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setSearchBar()
        GiphyCore.configure(apiKey: Constants.GIPHYKey)
        searchGiphyStickers(searchTerm: Constants.InitialSearchTerm)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func addPictureBtnPressed(_ sender: Any) {
        delegate?.pickPicture()
    }
    
    @IBAction func changeBackgroundBtnPressed(_ sender: Any) {
        print("change background")
    }
    // MARK: Helpers
    
    func setSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchController.searchBar.delegate = self
        placeholderView.addSubview(searchController.searchBar)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Giphy"
        definesPresentationContext = true
    }
    
    func searchGiphyStickers(searchTerm: String) {
        
        /// Sticker Search
        let _ = GiphyCore.shared.search(searchTerm, media: .sticker, offset: offset ) { (response, error) in
            
            if let error = error as NSError? { print(error.description); return }
            
            if let response = response, let data = response.data, let _ = response.pagination {
                
                for result in data {
                    guard let thumbnail = result.images?.fixedHeightSmall?.gifUrl,
                    let url = result.images?.original?.gifUrl
                    else { return }
                    self.stickerData.append(Sticker(thumbnail: thumbnail, url: url))
                }
            } else {
                print("Giphy: No Results Found")
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        offset += 26
    }
}

// MARK: UICollectionView Delegates

extension ModalViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = Int(Int(collectionView.frame.width) / Constants.Columns - (Constants.Inset + Constants.Space))
        let height = Constants.Height
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.addGif(url: stickerData[indexPath.row].url)
        delegate?.closeExpandedView()
        // TODO: search bar cancle
    }
    
}

extension ModalViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCell", for: indexPath) as! StickerCollectionViewCell

        let sticker = stickerData[indexPath.item]
        
        guard let url = URL(string: sticker.thumbnail) else { return cell }
        cell.imageView.kf.setImage(with: url)

        return cell
    }
}

// MARK: SearchBar Delegates

extension ModalViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        delegate?.expandContainerView()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        guard let term = searchBar.text else { return }
        stickerData = []
        searchGiphyStickers(searchTerm: term)
        self.collectionView.reloadData()
//        searchBar.text = ""
//        searchBar.showsCancelButton = false
        delegate?.closeExpandedView()
        

    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
}

