//
//  guestImageCollectionViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 11/3/20.
//

import UIKit
import Firebase

private let reuseIdentifier = "pictureCell"

class guestImageCollectionViewController: UICollectionViewController {
    var placeId = ""
    var currentUserId = ""
    var currentUsername = ""
    var imageURLS: [String] = []
    var images : [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        getImages()
    }

    // MARK: UICollectionViewDataSource
    func getImages(){
        let db = Firestore.firestore()
        db.collection("images").whereField("placeId", isEqualTo: placeId).getDocuments(){
            (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            if (document.data()["imageUrl"] != nil){
                                let urlString = document.data()["imageUrl"] as! String
                                self.imageURLS.append(urlString)
                                let url = URL(string: urlString)
                                if (url != nil) {
                                    if let data = try? Data(contentsOf: url!)
                                    {
                                        self.images.append(UIImage(data: data)!)
                                    }
                                } else {
                                    self.images.append(UIImage(named: "Default")!)
                                }
                            }
                        }
                        DispatchQueue.main.async {[weak self] in
                            self?.collectionView.reloadData()
                        }
                    }
                            
        }
    }
            
    
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count

    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
    
        cell.image?.image = images[indexPath.row]
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            self.performSegue(withIdentifier: "singleImageSegue", sender: indexPath)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "singleImageSegue"{
            let selectedIndexPath = sender as? NSIndexPath
            let vc = segue.destination as! ScrollViewController
            vc.imgs = images
            vc.index = selectedIndexPath!.row
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}
