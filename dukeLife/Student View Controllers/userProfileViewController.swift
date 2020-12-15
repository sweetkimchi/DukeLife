//
//  userProfileViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/25/20.
//

import UIKit
import Firebase
import FirebaseAuth

class userProfileViewController: UIViewController {
    @IBOutlet weak var likedPlaces: UITableView!
    @IBOutlet weak var userName: UILabel!
    
    var name = ""
    var userId = ""
    var currentUserId = ""
    var currentUsername = ""
    
    var placesList = [Place]()
    var idList = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        likedPlaces.delegate = self
        likedPlaces.dataSource = self
        userName.text = name
        loadLikedPlaces()
    }
    
    func loadLikedPlaces() {
        self.placesList.removeAll()
        self.idList.removeAll()
        let db = Firestore.firestore()
        var likedIds = [String]()
        db.collection("likes").whereField("userId", isEqualTo: self.userId).order(by: "time", descending: true).getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        likedIds.append(document.data()["placeId"] as! String)
                    }
                    let totalLikes = likedIds.count
                    var i = 1
                    for id in likedIds {
                        let docRef = db.collection("places").document(id)
                        docRef.getDocument { (document, error) in
                            if let document = document, document.exists {
                                let id = document.documentID
                                if (!self.idList.contains(id)) {
                                    let name = document.data()!["name"] as! String
                                    let address = Address.init(
                                        address1: document.data()!["address1"] as! String,
                                        address2: document.data()!["address2"] as! String,
                                        address3: document.data()!["address3"] as! String,
                                        city:document.data()!["city"]! as! String,
                                        zip_code:document.data()!["zip_code"] as! String,
                                        state:document.data()!["state"] as! String,
                                        display_address: document.data()!["display_address"] as! [String]
                                        )!
                                    let placeToDisplay = Place.init(
                                        id: document.data()!["id"] as! String,
                                        name: name,
                                        displayImg: document.data()!["displayImg"] as! String,
                                        url: document.data()!["url"] as! String,
                                        phoneNum: document.data()!["phoneNum"] as! String,
                                        address: address,
                                        coords: Coordinates.init(
                                            latitude: document.data()!["latitude"] as! NSNumber,
                                            longitude: document.data()!["longitude"] as! NSNumber)!,
                                        docId: document.documentID,
                                        likeCount: document.data()!["likeCount"] as! NSNumber)!
                                    self.idList.append(id)
                                    self.placesList.append(placeToDisplay)
                                    
                                    if (i == totalLikes) {
                                        if self.placesList.count > 0 {
                                            DispatchQueue.main.async {[weak self] in
                                                self?.likedPlaces.reloadData()
                                            }
                                        }
                                    }
                                    i += 1
                                }
                            }
                        }
                    }
                }
        }
    }
}

extension userProfileViewController: UITableViewDataSource, UITableViewDelegate, PlaceDetailViewControllerDelegate {
    
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.placesList.count;
   }

   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let db = Firestore.firestore()
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! placeTableViewCell
        
        cell.name.text = "\(self.placesList[indexPath.row].name)"
        cell.likeCount.text = "\(self.placesList[indexPath.row].likeCount)"
        db.collection("likes").whereField("placeId", isEqualTo: self.placesList[indexPath.row].docId)
            .whereField("userId", isEqualTo: self.currentUserId).getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error getting likes for place: \(err)")
                } else {
                    var count = 0;
                    for _ in querySnapshot!.documents {
                        count += 1;
                    }
                    if (count > 0) {
                        cell.likeButton.image = UIImage(systemName: "heart.fill")
                    } else {
                        cell.likeButton.image = UIImage(systemName: "heart")
                    }
                }
        }
        return cell
    }

    // MARK: - Navigation to Place Information
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! studentPlaceDetailViewController
        let myRow = likedPlaces!.indexPathForSelectedRow
        let place = placesList[myRow!.row]

        destVC.docId = place.docId
        destVC.nameText = place.name
        destVC.likeCountText = "\(place.likeCount)"
        destVC.urlText = place.url
        destVC.phoneNumberText = place.phoneNum
        destVC.currentUsername = self.currentUsername
        destVC.currentUserId = self.currentUserId
        
        destVC.delegate = self
        destVC.selectedIndex = myRow!.row
            
        let url = URL(string: place.displayImg)
        if (url != nil) {
            if let data = try? Data(contentsOf: url!)
            {
                destVC.displayPicture = UIImage(data: data)!
            }
        } else {
            destVC.displayPicture = UIImage(named: "Default")!
        }

        var addr = "";
        if (place.address.display_address!.count > 0) {
            var j = 0;
            for line in place.address.display_address! {
                if (j < place.address.display_address!.count - 1) {
                    addr += line + "\n"
                } else {
                    addr += line
                }
                j += 1
            }
        } else {
            if (!place.address.address1!.isEmpty) {
                addr += place.address.address1! + "\n"
            }
            if (!place.address.address2!.isEmpty) {
                addr += place.address.address2! + "\n"
            }
            if (!place.address.address3!.isEmpty) {
                addr += place.address.address3! + "\n"
            }
            if (!place.address.city!.isEmpty) {
                addr += place.address.city! + ", "
            }
            addr += "NC"
            if (!place.address.zip_code!.isEmpty) {
                addr += "\n" + place.address.zip_code!
            }
        }
        destVC.addressText = addr
        let selectedCell = likedPlaces!.cellForRow(at: myRow!) as! placeTableViewCell
        var liked = true
        if (selectedCell.likeButton.image == UIImage(systemName: "heart")) {
            liked = false
        }
        destVC.isLiked = liked
    }
    
    /*
     * When a user likes a place from the page, this function is called to update the like count for the cell in the TableView
     */
    func update(index i: Int, count likeNum: NSNumber) {
        placesList[i].likeCount = likeNum
        DispatchQueue.main.async {[weak self] in
            self?.likedPlaces.reloadData()
        }
    }
    
    func showAlert(message:String) {
        let alert = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}
