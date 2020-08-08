//
//  UserSingleton.swift
//  SpotiFriend
//
//  Created by Matthew Simon on 7/29/20.
//  Copyright © 2020 Matthew Simon. All rights reserved.
//

import Foundation


class UserSingleton {
    static var sharedUserInfo = UserSingleton()
    
    var email = ""
    var username = ""
    var profilePicURL = ""
    var mapRadius : Double = 40225.0
    
    var totalPlaylistsCreated = 0
    var totalPlaylistsFound = 0
    
    private init(){
        
    }
    
    
}
