//
//  Address.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/23/20.
//

import Foundation

class Address: Codable {
    var address1: String?
    var address2: String?
    var address3: String?
    var city: String?
    var zip_code: String?
    var state: String?
    var display_address: [String]?
    
    init?(address1: String, address2: String, address3: String, city:String, zip_code:String, state:String, display_address: [String]) {
        if (address1.isEmpty && address2.isEmpty && address3.isEmpty && city.isEmpty && zip_code.isEmpty && state.isEmpty) {
            return nil;
        }
        self.address1 = address1
        self.address2 = address2
        self.address3 = address3
        self.city = city
        self.zip_code = zip_code
        self.state = state
        self.display_address = display_address;
    }
}
