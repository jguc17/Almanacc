//
//  FeedViewController.swift
//  FacebookTest
//
//  Created by Jeffrey Gu on 4/12/17.
//  Copyright © 2017 Jeffrey Gu. All rights reserved.
//

import Foundation
import UIKit


class FeedViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    
    @IBOutlet weak var collectionView: UICollectionView!
    
    //TODO:
        // get list of events (from Firebase) --> store locally as list of custom
        //      news events objects
        //          consists of: person (id),image name, event change enum (moving, new location, new work)
        // fill out collectionview data source and delegate methods accordingly
        //      for didSelectItem: segue to that particular individual's profile page (Firebase request) (push on ProfileViewController??)
        // make custom collection view cell class

    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        setupCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FeedViewCollectionCell.self, forCellWithReuseIdentifier: "cell")
        
        collectionView.isUserInteractionEnabled = true
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // TODO: pull down from Firebase to instantiate FeedEvent struct
        //      pass into cell instantiation
        
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MovieCollectionViewCell
//        
//        if let image = imageCache[indexPath.row] {
//            cell.imageView.image = image
//        }
//        else {
//            //append default N/A image if poster not available:
//            cell.imageView.image = #imageLiteral(resourceName: "not_available.jpg")
//        }
//        
//        cell.textView.text = dataStore[indexPath.row].name
//        cell.imdbID = dataStore[indexPath.row].imdbID
//        return cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FeedViewCollectionCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("calling didSelectItemAt")
        
        
        
        let cell = collectionView.cellForItem(at: indexPath) as! FeedViewCollectionCell
        
//        let cell = collectionView.cellForItem(at: indexPath) as! MovieCollectionViewCell
//        
//        if let id = cell.imdbID {
//            
//            let movieVC = MovieViewController(nibName: "MovieView", bundle: nil)
//            
//            // define movieVC's id, name and image props; other details are requested within movieVC
//            movieVC.id = id
//            movieVC.name = cell.textView.text
//            movieVC.image = cell.imageView.image
//            
//            navigationController?.pushViewController(movieVC, animated: true)
//            
//        }
//        else {
//            print ("cell selection not available")
//        }
    }

    // collection view layout delegate method
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize = collectionView.layer.bounds
        let screenWidth = screenSize.size.width*0.95
        let screenHeight = CGFloat(80)
        return CGSize(width: screenWidth, height: screenHeight)
    }
}
