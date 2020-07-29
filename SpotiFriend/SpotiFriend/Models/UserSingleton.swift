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
    var numTotalLikes = 0
    var profilePicURL = ""
    
    private init(){
        
    }
    
    
}
