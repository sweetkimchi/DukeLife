//
//  addPlaceTableViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 11/5/20.
//

import UIKit
import Firebase

class addPlaceTableViewController: UITableViewController, UISearchBarDelegate {
    struct coords: Codable {
        var latitude: Decimal?
        var longitude: Decimal?
    }
    
    struct business: Codable {
        var id:String?
        var name: String?
        var url: String?
        var coordinates: coords?
        var image_url:String?
        var location: Address?
        var display_phone: String?
    }
    
    struct apiResponse: Codable {
        var businesses:[business]
    }
    
    struct businessResponse: Codable {
        var name: String?
        var photos: [String]?
    }
    
    var placeList = [Place]()
    var idsInDatabase = [String]()
    
    var searchString = ""
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        loadExisitingPlaces()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.placeList.count
    }
    
    func loadExisitingPlaces() {
        let db = Firestore.firestore()
        self.idsInDatabase.removeAll()
        db.collection("places").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let yelpId = document.data()["id"] as! String
                    self.idsInDatabase.append(yelpId)
                }
            }
        }
    }
    
    func loadResults(_ searchString:String) {
        let latitude = 36.0014
        let longitude = -78.9382
        let radius = 16093
        let search = searchString.split(separator: " ").joined(separator: "+")
        let apikey = "Q2DSCs_0MgIdnj4RLvlehFC7McfEGtAp8JZi8AYffmqMPCcS7vlpLRNoGixr_bGRKRG3XsOmjb1rlrX_0RpzIHdZG5Mdmom3GgCWyDZn8CJXHrIeQP9S3Q2AbAeTX3Yx"
        let baseURL = "https://api.yelp.com/v3/businesses/search?term=\(search)&latitude=\(latitude)&longitude=\(longitude)&radius=\(radius)"
        let url = URL(string: baseURL)
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(apikey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if (error != nil) {
                print("Error = \(error!)")
                return
            }
            let response = response as! HTTPURLResponse
            
            guard let content = data else {
                print("No results found")
                return
            }
            let decoder = JSONDecoder()
            do {
                let apiResult = try decoder.decode(apiResponse.self, from: content)
                let allPlaces = apiResult.businesses
                self.placeList.removeAll()
                for place in allPlaces {
                    if (!self.idsInDatabase.contains(place.id!)){
                        let c = Coordinates.init(latitude: place.coordinates?.latitude as! NSNumber, longitude: place.coordinates?.longitude as! NSNumber)!
                        let placeToAdd = Place.init(id: place.id!, name: place.name!, displayImg: place.image_url!, url: place.url!, phoneNum: place.display_phone!, address: place.location!, coords: c)!
                        self.placeList.append(placeToAdd);
                    }
                    if self.placeList.count > 0 {
                        DispatchQueue.main.async {[weak self] in
                            self?.tableView.reloadData()
                        }
                    }
                }
            } catch {
                print("JSON Decode error")
            }
        }
        dataTask.resume()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if (!searchBar.text!.isEmpty) {
            self.searchString = searchBar.text!.split(separator: " ").joined(separator: "+")
            loadResults(searchString)
        }
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addCell", for: indexPath) as! addPlaceTableViewCell
        cell.name.text = "\(indexPath.row + 1). \(placeList[indexPath.row].name)"
        return cell
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC = segue.destination as! addDetailViewController
        let myRow = tableView.indexPathForSelectedRow
        let place = placeList[myRow!.row]
        
        destVC.place = place
        destVC.nameText = place.name
        destVC.urlText = place.url
        destVC.phoneNumberText = place.phoneNum
        
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
    }
}
