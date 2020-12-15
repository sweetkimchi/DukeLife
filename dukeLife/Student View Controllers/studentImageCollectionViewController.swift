//
//  studentImageCollectionViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/28/20.
//

import UIKit
import Firebase

private let reuseIdentifier = "pictureCell"

class studentImageCollectionViewController: UICollectionViewController {
    @IBAction func addPhotoButton(_ sender: Any) {
        self.showAlert()
    }
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

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if (kind == UICollectionView.elementKindSectionFooter) {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FooterCollectionReusableView", for: indexPath)
            return footerView
        } else if (kind == UICollectionView.elementKindSectionHeader) {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderCollectionReusableView", for: indexPath)
            return headerView
        }
        fatalError()
    }

}

//MARK:- Image Picker
extension studentImageCollectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private func showAlert() {
        let alert = UIAlertController(title: "Image Selection", message: "From where you want to pick this image?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(action: UIAlertAction) in
            self.getImage(fromSourceType: .camera)
        }))
        alert.addAction(UIAlertAction(title: "Photo Album", style: .default, handler: {(action: UIAlertAction) in
            self.getImage(fromSourceType: .photoLibrary)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = sourceType
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }

    //MARK:- UIImagePickerViewDelegate.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true) { [weak self] in
            guard (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) != nil else { return }
            if let imgUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL{
                    let imgName = imgUrl.lastPathComponent
                    let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
                    let localPath = documentDirectory?.appending(imgName)

                    let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
                    let data = image.pngData()! as NSData
                    data.write(toFile: localPath!, atomically: true)
                    
                    let storage = Storage.storage()
                    let storageRef = storage.reference()
                    // Create a reference to the file you want to upload
                    let timestamp = NSDate().timeIntervalSince1970
                    let myTimeInterval = TimeInterval(timestamp)
                    let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
                    let formatter = DateFormatter()
                    formatter.dateFormat = "ddMMMyyyyHH:mm"
                    let uniqueName = self!.currentUserId +  formatter.string(from: time as Date)
                    let photoRef = storageRef.child("images/\(uniqueName).jpg")
                
                self?.images.append(image)
                DispatchQueue.main.async {[weak self] in
                    self?.collectionView.reloadData()
                }

                // Upload the file to storage and store in database
                let uploadTask = photoRef.putData(data as Data, metadata: nil) { (metadata, error) in
                      guard let metadata = metadata else {
                        print("Error uploading \(String(describing: error))")
                        return
                      }
                      photoRef.downloadURL { (url, error) in
                        guard let downloadURL = url else {
                            print("Error uploading \(String(describing: error))")
                          return
                        }
                        let db = Firestore.firestore()
                        var ref: DocumentReference? = nil
                        ref = db.collection("images").addDocument(data: [
                            "imageUrl": downloadURL.absoluteString,
                            "placeId": self?.placeId,
                            "userId": self?.currentUserId
                        ])
                        { err in
                            if let err = err {
                                print("Error adding document: \(err)")
                            }
                        }
                      }
                    }
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
