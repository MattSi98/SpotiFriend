//
//  profileVC.swift
//  SpotiFriend
//
//  Created by Matthew Simon on 7/26/20.
//  Copyright © 2020 Matthew Simon. All rights reserved.
//

import UIKit
import Firebase

class profileVC: UIViewController {
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var totalLikesLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    
    //status bar color
    override var preferredStatusBarStyle: UIStatusBarStyle{
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //profile pic border and color
        profilePictureImageView.layer.cornerRadius = 15
        profilePictureImageView.layer.borderWidth = 5
        profilePictureImageView.layer.borderColor = UIColor.systemGreen.cgColor

        
    }
    
    @IBAction func logOutClicked(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: "toLogInVCfromProfileVC", sender: nil)

        }catch {
            makeAlert(title: "Error", message: "Unable to log out, try again later.")
        }
    }
    
    @IBAction func editProfileClicked(_ sender: Any) {
    }
    
    @IBAction func followersClicked(_ sender: Any) {
    }
    
    @IBAction func followingClicked(_ sender: Any) {
    }
    
    
    
    // usefule helper functions //////////
    func makeAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
}
