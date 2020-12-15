//
//  guestMapViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/26/20.
//

import UIKit
import Firebase
import MapKit
import Contacts


class guestMapViewController: UIViewController {
    var placeList = [Place]()
    var idsInList = [String]()
    var placesDisplayed = [Place]()
    
    @IBOutlet weak var resultsTableView: UITableView!
    
    var selectedType = ""
    var types = ["Food": "food", "Bars":"bars", "Fun": "fun", "Coffee": "coffee"]
    @IBAction func typeSelector(_ sender: UISegmentedControl) {
        selectedType = types[sender.titleForSegment(at: sender.selectedSegmentIndex)!]!
        loadPlaces()
    }
    
    let locationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    
    var currentStartIndex = 0
    var currentEndIndex = 0
    var totalPlaces = 0
    
    var currentUserId = ""
    var currentUsername = ""
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    
    @IBAction func nextPageButton(_ sender: Any) {
        getNextPage()
    }
    
    @IBAction func previousPageButton(_ sender: Any) {
        getPrevPage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if (selectedType.isEmpty) {
            selectedType = "food"
        }
        loadPlaces()
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPlaces()
    }
    
    func loadPlaces() {
        let db = Firestore.firestore()
        db.collection("places").whereField("type", isEqualTo: selectedType).order(by: "likeCount", descending: true).getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    self.idsInList.removeAll()
                    self.placeList.removeAll()
                    
                    for document in querySnapshot!.documents {
                        let id = document.documentID
                        if (!self.idsInList.contains(id)) {
                            let name = document.data()["name"] as! String
                            let address = Address.init(
                                address1: document.data()["address1"] as! String,
                                address2: document.data()["address2"] as! String,
                                address3: document.data()["address3"] as! String,
                                city:document.data()["city"] as! String,
                                zip_code:document.data()["zip_code"] as! String,
                                state:document.data()["state"] as! String,
                                display_address: document.data()["display_address"] as! [String]
                                )!
                            let placeToDisplay = Place.init(
                                id: document.data()["id"] as! String,
                                name: name,
                                displayImg: document.data()["displayImg"] as! String,
                                url: document.data()["url"] as! String,
                                phoneNum: document.data()["phoneNum"] as! String,
                                address: address,
                                coords: Coordinates.init(
                                    latitude: document.data()["latitude"] as! NSNumber,
                                    longitude: document.data()["longitude"] as! NSNumber)!,
                                docId: document.documentID,
                                likeCount: document.data()["likeCount"] as! NSNumber)!
                            self.idsInList.append(id)
                            self.placeList.append(placeToDisplay);
                        }
                    }

                    if self.placeList.count > 0 {
                        var i = 0
                        self.currentStartIndex = 0
                        self.totalPlaces = self.placeList.count
                        // Removes previous places displayed
                        self.placesDisplayed.removeAll()
                        for place in self.placeList {
                            if (i < 10) {
                                self.placesDisplayed.append(place)
                                i += 1
                            } else {
                                self.currentEndIndex = i - 1
                                break
                            }
                        }
                        self.setPageButtonsDisplay()
                        self.dropPins()
                        DispatchQueue.main.async {[weak self] in
                            self?.resultsTableView.reloadData()
                            let indexPath = NSIndexPath(row: 0, section: 0)
                            self?.resultsTableView.scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
                        }
                    }
                }
        }
    }
    
    /*
     Drop a pin on Map View for each place currently being displayed
    */
    func dropPins()  {
        self.mapView.removeAnnotations(mapView.annotations)
        var locations = [MKPointAnnotation]()
        for place in self.placesDisplayed {
            let dropPin = MKPointAnnotation()
            dropPin.title = place.name
            let latitude = place.coords.latitude as! Double
            let longitude = place.coords.longitude as! Double
            dropPin.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.mapView.addAnnotation(dropPin)
            locations.append(dropPin)
            self.mapView.showAnnotations(locations, animated: true)
        }
    }

    /*
     * Loads next 10 pages to be displayed from placesList
     */
    func getNextPage() {
        self.placesDisplayed.removeAll()
        self.currentStartIndex = self.currentEndIndex + 1
        self.currentEndIndex = self.currentStartIndex + 9
        for i in self.currentStartIndex ..< self.currentEndIndex + 1 {
            if (i < self.totalPlaces) {
                placesDisplayed.append(placeList[i])
            } else {
                self.currentEndIndex = i - 1
                break
            }
        }
        setPageButtonsDisplay()
        dropPins()
        DispatchQueue.main.async {[weak self] in
            self?.resultsTableView.reloadData()
            let indexPath = NSIndexPath(row: 0, section: 0)
            self?.resultsTableView.scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
        }
    }
    
    /*
     * Loads previous 10 pages to be displayed from placesList
     */
    func getPrevPage() {
        self.placesDisplayed.removeAll()
        self.currentStartIndex = self.currentStartIndex - 10
        for i in self.currentStartIndex ..< self.currentStartIndex + 10 {
            if (i >= 0) {
                placesDisplayed.append(placeList[i])
            }
        }
        self.currentEndIndex = self.currentStartIndex + 9
        setPageButtonsDisplay()
        dropPins()
        DispatchQueue.main.async {[weak self] in
            self?.resultsTableView.reloadData()
            let indexPath = NSIndexPath(row: 0, section: 0)
            self?.resultsTableView.scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
        }
    }
    
    /*
     * Sets next and previous buttons if there are more or previous results to display
     */
    func setPageButtonsDisplay() {
        if (self.currentStartIndex == 0) {
            self.prevButton.isHidden = true;
        } else {
            self.prevButton.isHidden = false;
        }
        
        if (self.currentEndIndex + 1 < self.totalPlaces) {
            self.nextButton.isHidden = false;
        } else {
            self.nextButton.isHidden = true;
        }
    }
}

/*
 * Set up table view for list of places
 */
extension guestMapViewController: UITableViewDataSource, UITableViewDelegate, GuestPlaceDetailViewControllerDelegate, CLLocationManagerDelegate {
    
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.placesDisplayed.count;
   }
    
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! placeTableViewCell
        cell.name.text = "\(self.currentStartIndex + indexPath.row + 1). \(placesDisplayed[indexPath.row].name)"
        cell.likeCount.text = "\(placesDisplayed[indexPath.row].likeCount)"
    
        var saved = false
        let db = Firestore.firestore()
        db.collection("savedPlaces").whereField("placeId", isEqualTo: placesDisplayed[indexPath.row].docId)
            .whereField("userId", isEqualTo: self.currentUserId).getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    var count = 0;
                    for _ in querySnapshot!.documents {
                        count += 1;
                    }
                    if (count > 0) {
                        saved = true
                        self.placesDisplayed[indexPath.row].setSavedStatus(saved)
                    } else {
                        saved = false
                    }
                }
        }
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! guestPlaceDetailViewController
        let myRow = resultsTableView!.indexPathForSelectedRow
        let place = placesDisplayed[myRow!.row]
        
        destVC.docId = place.docId
        destVC.nameText = place.name
        destVC.likeCountText = "\(place.likeCount)"
        destVC.urlText = place.url
        destVC.phoneNumberText = place.phoneNum
        destVC.currentUsername = self.currentUsername
        destVC.currentUserId = self.currentUserId
        destVC.delegate = self
        destVC.selectedIndex = self.currentStartIndex + myRow!.row
        
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
        destVC.isSaved = place.saved
    }
    
    func update(index i: Int, status saved: Bool) {
        placeList[i].saved = saved
        placesDisplayed[i - self.currentStartIndex].saved = saved
        DispatchQueue.main.async {[weak self] in
            self?.resultsTableView.reloadData()
            let indexPath = NSIndexPath(row: 0, section: 0)
            self?.resultsTableView.scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
        }
    }
}

private extension MKMapView {
  func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 1000) {
    let coordinateRegion = MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: regionRadius,
      longitudinalMeters: regionRadius)
    setRegion(coordinateRegion, animated: true)
  }
}


extension guestMapViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let identifier = "places"
    var view: MKMarkerAnnotationView
    if let dequeuedView = mapView.dequeueReusableAnnotationView(
      withIdentifier: identifier) as? MKMarkerAnnotationView {
      dequeuedView.annotation = annotation
        view = dequeuedView
    } else {
        view = MKMarkerAnnotationView(
        annotation: annotation,
        reuseIdentifier: identifier)
        view.canShowCallout = true
        view.calloutOffset = CGPoint(x: -5, y: 5)
        view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    }
    return view
  }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let selectedLat = (view.annotation?.coordinate.latitude)! as NSNumber
        let selectedLong = (view.annotation?.coordinate.longitude)! as NSNumber
        var ind = 0
        for place in self.placesDisplayed {
            if (place.coords.latitude == selectedLat && place.coords.longitude == selectedLong) {
                if (self.resultsTableView.numberOfSections != 0 && self.resultsTableView.numberOfRows(inSection: 0) != 0) {
                    let index = NSIndexPath(row: ind, section: 0)
                    self.resultsTableView.selectRow(at: index as IndexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
                    return
                }
            }
            ind = ind + 1
        }
    }
}
