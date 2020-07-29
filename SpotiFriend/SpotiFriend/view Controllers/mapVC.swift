//
//  mapVC.swift
//  SpotiFriend
//
//  Created by Matthew Simon on 7/26/20.
//  Copyright © 2020 Matthew Simon. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class mapVC: UIViewController {
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    let firestoreDatabase = Firestore.firestore()
    
    //status bar color
    override var preferredStatusBarStyle: UIStatusBarStyle{
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //update user singleton for use throughout app
        getUserInfo()
    }
        
    
    func getUserInfo(){
        //clear data first
        UserSingleton.sharedUserInfo.email = ""
        UserSingleton.sharedUserInfo.username = ""
        UserSingleton.sharedUserInfo.numTotalLikes = 0
        UserSingleton.sharedUserInfo.profilePicURL = ""
        
        //get new data
        firestoreDatabase.collection("userInfo").whereField("email", isEqualTo: Auth.auth().currentUser!.email!).getDocuments { (snapshot, error) in
            if error != nil {
                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error accessing database.")
            }else{
                if snapshot?.isEmpty == false && snapshot != nil {
                    for doc in snapshot!.documents {
                        if let username = doc.get("username") as? String {
                            if let email = doc.get("email") as? String {
                                UserSingleton.sharedUserInfo.username = username
                                UserSingleton.sharedUserInfo.email  = email
                                
                                //these are not all nested because users will always have username and email
                                //but will nto always have a profile picture
                                if let profilePicURL = doc.get("profilePicURL") as? String {
                                    UserSingleton.sharedUserInfo.profilePicURL = profilePicURL
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }

   
    
    
    
    // usefule helper functions //////////
    func makeAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }

}
