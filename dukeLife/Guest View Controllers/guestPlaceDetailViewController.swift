//
//  guestPlaceDetailViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/26/20.
//

import UIKit
import Firebase

let blue = UIColor(red: -0.149386, green: 0.332113, blue: 0.628713, alpha: 1)
let white = UIColor.white

protocol GuestPlaceDetailViewControllerDelegate: AnyObject {
    func update(index i: Int, status saved: Bool)
}

class guestPlaceDetailViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var likeCount: UILabel!
    @IBOutlet weak var displayImage: UIImageView!
    @IBOutlet weak var url: UITextView!
    @IBOutlet weak var phoneNumber: UITextView!
    @IBOutlet weak var address: UITextView!
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var buttonOutline: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    weak var delegate: GuestPlaceDetailViewControllerDelegate?
    
    var currentUserId = ""
    var currentUsername = ""
    
    var comments = [Comment]();
    var docId = "";
    var nameText = "";
    var addressText = "";
    var likeCountText = "";
    var phoneNumberText = "";
    var urlText = "";
    var selectedIndex = 0;
    @IBOutlet weak var saveButton: UIButton!
    var displayPicture: UIImage = UIImage(named: "Default")!
    var isSaved = false;
    
    @IBAction func imagePageButton(_ sender: Any) {
        self.performSegue(withIdentifier: "images", sender: nil)
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        if (sender.currentImage == UIImage(systemName: "trash")) {
            setUnsaved()
            unsavePlace()
        } else if (sender.currentImage == UIImage(systemName: "plus")) {
            setSaved()
            savePlace()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentTableView.delegate = self
        commentTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self,selector: #selector(self.keyboardDidShow(notification:)),
            name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(self.keyboardDidHide(notification:)),
            name: UIResponder.keyboardDidHideNotification, object: nil)
        if (isSaved) {
            setSaved()
        } else {
            setUnsaved()
        }
        self.name.text = nameText
        self.address.text = addressText
        self.likeCount.text = likeCountText
        self.phoneNumber.text = phoneNumberText
        self.url.text = urlText
        self.displayImage.image = displayPicture
        loadComments();
        self.commentTableView.rowHeight = UITableView.automaticDimension
        self.commentTableView.estimatedRowHeight = UITableView.automaticDimension
    }
    
    /* Sets button appearance if user has saved it */
    func setSaved() {
        saveButton.setImage(UIImage(systemName: "trash"), for: .normal)
        saveButton.setTitle("Unsave Place", for: .normal)
        saveButton.setTitleColor(blue, for: .normal)
        buttonOutline.backgroundColor = blue
        saveButton.backgroundColor = white
        saveButton.tintColor = blue
    }
    
    /* Sets button appearance if user hasn't saved it */
    func setUnsaved() {
        saveButton.setImage(UIImage(systemName: "plus"), for: .normal)
        saveButton.setTitle("Save Place", for: .normal)
        saveButton.setTitleColor(white, for: .normal)
        buttonOutline.backgroundColor = white
        saveButton.backgroundColor = blue
        saveButton.tintColor = white
    }
    
    /*
     * Loads comments for a place from the database to be displayed in comment section
     */
    func loadComments() {
        let db = Firestore.firestore()

        db.collection("comments").whereField("placeId", isEqualTo: self.docId).order(by: "time", descending: false).getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting comment documents: \(err)")
                } else {
                    self.comments.removeAll()
                    for document in querySnapshot!.documents {

                        let netId = document.data()["netId"] as! String
                        let userId = document.data()["userId"] as! String
                        let comment = document.data()["comment"] as! String
                        let commentToAdd = Comment.init(text: comment, netId: netId, userId: userId, commentId: document.documentID, placeId: self.docId)!
                        self.comments.append(commentToAdd);
                    }
                    if self.comments.count > 0 {
                        DispatchQueue.main.async {[weak self] in
                            self?.commentTableView.reloadData()
                            let indexPath = NSIndexPath(item: (self?.comments.count)! - 1, section: 0)
                            self?.commentTableView.scrollToRow(at: indexPath as IndexPath, at: UITableView.ScrollPosition.bottom, animated: false)
                        }
                    }
                }
        }
    }
    
    /*
     * Adds a save to the database for current user ID and current place ID if user doesn't already save the place
     */
    func savePlace() {
        let db = Firestore.firestore()
        var savedPlaces = 0
        db.collection("savedPlaces").whereField("placeId", isEqualTo: self.docId)
            .whereField("userId", isEqualTo: self.currentUserId).getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for _ in querySnapshot!.documents {
                        savedPlaces += 1
                    }
                }
            }
        if (savedPlaces == 0) {
            // Get time
            let timestamp = NSDate().timeIntervalSince1970
            let myTimeInterval = TimeInterval(timestamp)
            let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
            
            db.collection("savedPlaces").document().setData([
                "placeId": self.docId,
                "time": time,
                "userId": self.currentUserId
            ]) { err in
                if let err = err {
                    print("Error writing save document: \(err)")
                } else {
                    self.delegate?.update(index: self.selectedIndex, status: true)
                }
            }
        }
    }
    
    /*
     * Deletes a save from the database for current user ID and current place ID if user unsaves the place
     */
    func unsavePlace() {
        let db = Firestore.firestore()
        db.collection("savedPlaces").whereField("placeId", isEqualTo: self.docId)
            .whereField("userId", isEqualTo: self.currentUserId).getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error getting saved places documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        db.collection("savedPlaces").document(document.documentID).delete() { err in
                            if let err = err {
                                print("Error removing like document: \(err)")
                            } else {
                                self.delegate?.update(index: self.selectedIndex, status: false)
                            }
                        }
                    }
                }
            }
    }
    
    //MARK: Methods to manage keybaord
    @objc func keyboardDidShow(notification: NSNotification) {
        let info = notification.userInfo
        let keyBoardSize = info![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        scrollView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyBoardSize.height, right: 0.0)
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyBoardSize.height, right: 0.0)
    }

    @objc func keyboardDidHide(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
}

/*
 * Set up table view for list of comments for the place
 */
extension guestPlaceDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count;
   }
    
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = commentTableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! commentTableViewCell
        
        cell.comment.text = "\(comments[indexPath.row].netId): \(comments[indexPath.row].text)"
        return cell
    }


    // MARK: - Navigation to User Profile
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if segue.identifier == "images" {
            let destVC = segue.destination as! guestImageCollectionViewController
            destVC.placeId = docId
            destVC.currentUserId = currentUserId
            destVC.currentUsername = currentUsername
        } else {
            let destVC = segue.destination as! userProfileViewController
            let myRow = commentTableView!.indexPathForSelectedRow
            let comment = comments[myRow!.row]
            
            let selectedNetId = comment.netId
            let selectedUser = comment.userId
            
            destVC.name = selectedNetId
            destVC.userId = selectedUser
            destVC.currentUserId = currentUserId
            destVC.currentUsername = currentUsername
        }
    }
    
    // UITableViewAutomaticDimension calculates height of label contents/text
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Swift 4.2 onwards
        return UITableView.automaticDimension
    }
}
