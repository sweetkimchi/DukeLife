//
//  studentPlaceDetailViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/23/20.
//

import UIKit
import Firebase

protocol PlaceDetailViewControllerDelegate: AnyObject {
    func update(index i: Int, count likeNum: NSNumber)
}

class studentPlaceDetailViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var likeCount: UILabel!
    @IBOutlet weak var displayImage: UIImageView!
    @IBOutlet weak var url: UITextView!
    @IBOutlet weak var phoneNumber: UITextView!
    @IBOutlet weak var address: UITextView!
    @IBOutlet weak var commentInput: UITextField!
    @IBOutlet weak var commentTableView: UITableView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBAction func returnKey(_ sender: Any) {
        if (!commentInput.text!.isEmpty) {
            saveComment(input: commentInput.text!)
            commentInput.text = ""
        }
        commentInput.endEditing(true)
    }
    var currentUserId = ""
    var currentUsername = ""
    
    weak var delegate: PlaceDetailViewControllerDelegate?
    var comments = [Comment]();
    var docId = "";
    var nameText = "";
    var addressText = "";
    var likeCountText = "";
    var phoneNumberText = "";
    var urlText = "";
    var selectedIndex = 0;
    @IBOutlet weak var likeImage: UIButton!
    var displayPicture: UIImage = UIImage(named: "Default")!
    var isLiked = false;

    @IBAction func imagePageButton(_ sender: Any) {
        self.performSegue(withIdentifier: "images", sender: nil)
    }

    @IBAction func likeButton(_ sender: UIButton) {
        let oldCount = (likeCount.text as! NSString).integerValue
        if (sender.currentImage == UIImage(systemName: "heart")) {
            sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            likePlace()
            likeCountText = "\(oldCount + 1)"
            likeCount.text = "\(oldCount + 1)"
            
            delegate?.update(index: self.selectedIndex, count: NSNumber(value: oldCount + 1))
        } else if (sender.currentImage == UIImage(systemName: "heart.fill")) {
            sender.setImage(UIImage(systemName: "heart"), for: .normal)
            unlikePlace()
            
            if (oldCount != 0) {
                likeCountText = "\(oldCount - 1)"
                likeCount.text = "\(oldCount - 1)"
                delegate?.update(index: self.selectedIndex, count: NSNumber(value: oldCount - 1))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentTableView.delegate = self
        commentTableView.dataSource = self
        self.commentInput.delegate = self
        
        NotificationCenter.default.addObserver(self,selector: #selector(self.keyboardDidShow(notification:)),
            name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(self.keyboardDidHide(notification:)),
            name: UIResponder.keyboardDidHideNotification, object: nil)
        
        self.name.text = nameText
        self.address.text = addressText
        self.likeCount.text = likeCountText
        self.phoneNumber.text = phoneNumberText
        self.url.text = urlText
        self.displayImage.image = displayPicture
        loadComments();
        
        if (isLiked) {
            likeImage.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            likeImage.setImage(UIImage(systemName: "heart"), for: .normal)
        }
        self.commentTableView.rowHeight = UITableView.automaticDimension
        self.commentTableView.estimatedRowHeight = UITableView.automaticDimension
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
     * Adds a like to the database for current user ID and current place ID if user doesn't already like the place
     */
    func likePlace() {
        let db = Firestore.firestore()
        var storedLikes = 0;
        db.collection("likes").whereField("placeId", isEqualTo: self.docId)
            .whereField("userId", isEqualTo: self.currentUserId).getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for _ in querySnapshot!.documents {
                        storedLikes += 1
                    }
                }
            }
        if (storedLikes == 0) {
            let timestamp = NSDate().timeIntervalSince1970
            let myTimeInterval = TimeInterval(timestamp)
            let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
            
            db.collection("likes").document().setData([
                "placeId": self.docId,
                "time": time,
                "userId": self.currentUserId
            ]) { err in
                if let err = err {
                    print("Error writing like document: \(err)")
                }
            }
            let docRef = db.collection("places").document(self.docId)

            db.runTransaction({ (transaction, errorPointer) -> Any? in
                let placeDocument: DocumentSnapshot
                do {
                    try placeDocument = transaction.getDocument(docRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard let oldLikeCount = placeDocument.data()?["likeCount"] as? Int else {
                    let error = NSError(
                        domain: "AppErrorDomain",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(placeDocument)"
                        ]
                    )
                    errorPointer?.pointee = error
                    return nil
                }
                transaction.updateData(["likeCount": oldLikeCount + 1], forDocument: docRef)
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Increment in likeCount failed: \(error)")
                }
            }
        }
    }
    
    /*
     * Deletes a like to the database for current user ID and current place ID if user unlikes the place
     */
    func unlikePlace() {
        let db = Firestore.firestore()
        db.collection("likes").whereField("placeId", isEqualTo: self.docId)
            .whereField("userId", isEqualTo: self.currentUserId).getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error getting like documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        db.collection("likes").document(document.documentID).delete() { err in
                            if let err = err {
                                print("Error removing like document: \(err)")
                            }
                        }
                    }
                }
            }
        let docRef = db.collection("places").document(self.docId)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let placeDocument: DocumentSnapshot
            do {
                try placeDocument = transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            guard let oldLikeCount = placeDocument.data()?["likeCount"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(placeDocument)"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            var newLikeCount = 0;
            if (oldLikeCount > 0) {
                newLikeCount = oldLikeCount - 1
            }
            transaction.updateData(["likeCount": newLikeCount], forDocument: docRef)
            return nil
        }) { (object, error) in
            if let error = error {
                print("Decrementing like count for place during an unlike has failed: \(error)")
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
extension studentPlaceDetailViewController: UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count;
   }
    
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = commentTableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! commentTableViewCell
        
        cell.comment.text = "\(comments[indexPath.row].netId): \(comments[indexPath.row].text)"
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (self.comments[indexPath.row].userId == self.currentUserId) {
            return true
        }
        return false
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let db = Firestore.firestore()
        if editingStyle == .delete {
            db.collection("comments").document(self.comments[indexPath.row].commentId).delete() { err in
                if let err = err {
                    print("Error removing comment document: \(err)")
                } else {
                    self.comments.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }


    // MARK: - Navigation to User Profile
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "images" {
            let destVC = segue.destination as! studentImageCollectionViewController
            destVC.placeId = docId
            destVC.currentUserId = self.currentUserId
            destVC.currentUsername = self.currentUsername
        } else {
            let destVC = segue.destination as! userProfileViewController
            let myRow = commentTableView!.indexPathForSelectedRow
            let comment = comments[myRow!.row]
            
            let selectedNetId = comment.netId
            let selectedUser = comment.userId

            destVC.name = selectedNetId
            destVC.userId = selectedUser
            destVC.currentUsername = self.currentUsername
            destVC.currentUserId = self.currentUserId
        }
    }

    func saveComment(input: String) {
        let db = Firestore.firestore()
        let timestamp = NSDate().timeIntervalSince1970
        let myTimeInterval = TimeInterval(timestamp)
        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
            
        var ref: DocumentReference? = nil
        ref = db.collection("comments").addDocument(data: [
            "comment": input,
            "netId": self.currentUsername,
            "placeId": self.docId,
            "time": time,
            "userId": self.currentUserId
        ])
        { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                let commentId = ref!.documentID
                let newComment = Comment.init(text: input, netId: self.currentUsername, userId: self.currentUserId, commentId: commentId, placeId: self.docId)!
                self.comments.append(newComment)
                DispatchQueue.main.async {[weak self] in
                    self?.commentTableView.reloadData()
                    let indexPath = NSIndexPath(item: (self?.comments.count)! - 1, section: 0)
                    self?.commentTableView.scrollToRow(at: indexPath as IndexPath, at: UITableView.ScrollPosition.bottom, animated: false)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
