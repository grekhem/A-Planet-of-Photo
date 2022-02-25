//
//  User.swift
//  A Planet of Photo
//
//  Created by Grekhem on 12.01.2022.
//

import Foundation
import MapKit
import Firebase


struct User {
    var uid: String = ""
    var name: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var isOnline = false
    var imageName: String? = nil
    var imageUrl: String = ""
    var isWantPlay = true
    var message = ""
    }

let baseRef = Database.database(url: "https://a-planet-of-photo-default-rtdb.europe-west1.firebasedatabase.app").reference().child("users")

