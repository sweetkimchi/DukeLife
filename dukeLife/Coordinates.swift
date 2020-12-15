//
//  Coordinates.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/23/20.
//

import Foundation

class Coordinates {
    var latitude: NSNumber?
    var longitude: NSNumber?
    
    init?(latitude: NSNumber, longitude: NSNumber) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
