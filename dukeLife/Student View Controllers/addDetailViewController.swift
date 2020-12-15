//
//  addDetailViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 11/5/20.
//

import UIKit
import Firebase
import MapKit

class addDetailViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var displayImage: UIImageView!
    @IBOutlet weak var url: UITextView!
    @IBOutlet weak var phoneNumber: UITextView!
    @IBOutlet weak var address: UITextView!
    @IBOutlet weak var buttonOutline: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addButton: UIButton!
    
    var place: Place?
    var nameText = "";
    var addressText = "";
    var phoneNumberText = "";
    var urlText = "";
    var selectedIndex = 0;
    var displayPicture: UIImage = UIImage(named: "Default")!
    var isRequested = false;
    
    @IBAction func addButton(_ sender: UIButton) {
        if (sender.currentImage == UIImage(systemName: "plus")) {
            sender.setImage(UIImage(systemName: "checkmark"), for: .normal)
            sender.setTitle("Place is Requested", for: .normal)
            addPlace()
            sender.setTitleColor(blue, for: .normal)
            buttonOutline.backgroundColor = blue
            sender.backgroundColor = white
            sender.tintColor = blue
        }
    }
    
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.name.text = nameText
        self.address.text = addressText
        self.phoneNumber.text = phoneNumberText
        self.url.text = urlText
        self.displayImage.image = displayPicture
        
        self.mapView.removeAnnotations(mapView.annotations)
        let dropPin = MKPointAnnotation()
        let latitude = self.place!.coords.latitude as! Double
        let longitude = self.place!.coords.longitude as! Double
            
        dropPin.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        dropPin.title = place!.name
        self.mapView.addAnnotation(dropPin)
        var mapRegion = MKCoordinateRegion();
        mapRegion.center.latitude = latitude;
        mapRegion.center.longitude = longitude;
        mapRegion.span.latitudeDelta = 0.01;
        mapRegion.span.longitudeDelta = 0.01;
        self.mapView.region = mapRegion;
    }
    
    /*
     * Adds a save to the database for current user ID and current place ID if user doesn't already save the place
     */
    func addPlace() {
        let db = Firestore.firestore()
        var savedPlaces = 0
        db.collection("requestedPlaces").whereField("id", isEqualTo: self.place!.id).getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for _ in querySnapshot!.documents {
                        savedPlaces += 1
                    }
                    if (savedPlaces == 0){
                        var ref: DocumentReference? = nil
                        var dispAddr = [String]()
                        var addr1 = ""
                        var addr2 = ""
                        var addr3 = ""
                        var city = ""
                        var state = ""
                        var zip = ""
                        if (self.place!.address.address1 != nil) {
                            addr1 = self.place!.address.address1!
                        }
                        if (self.place!.address.address2 != nil) {
                            addr2 = self.place!.address.address2!
                        }
                        if (self.place!.address.address3 != nil) {
                            addr3 = self.place!.address.address3!
                        }
                        if (self.place!.address.city != nil) {
                            city = self.place!.address.city!
                        }
                        if (self.place!.address.state != nil) {
                            state = self.place!.address.state!
                        }
                        if (self.place!.address.city != nil) {
                            zip = self.place!.address.zip_code!
                        }
                        if (self.place!.address.display_address != nil) {
                            dispAddr = self.place!.address.display_address!
                        }
                        ref = db.collection("requestedPlaces")
                            .addDocument(data: [
                                "id": self.place!.id,
                                "name": self.place!.name,
                                "displayImg": self.place!.displayImg,
                                "url": self.place!.url,
                                "phoneNum": self.place!.phoneNum,
                                "latitude": self.place!.coords.latitude!,
                                "longitude": self.place!.coords.longitude!,
                                "address1": addr1,
                                "address2": addr2,
                                "address3": addr3,
                                "city": city,
                                "state": state,
                                "zip_code": zip,
                                "display_address": dispAddr,
                                "type": "TBD"
                        ]) { err in
                            if let err = err {
                                print("Error adding document: \(err)")
                            } else {
                                self.isRequested = true
                            }
                        }
                    }
                }
            }
    }
}
