//
//  settingsVC.swift
//  SpotiFriend
//
//  Created by Matthew Simon on 7/26/20.
//  Copyright © 2020 Matthew Simon. All rights reserved.
//

import UIKit
import Firebase

class settingsVC: UIViewController {
    
    
    @IBOutlet weak var mapRadiusTextField: UITextField!
    
    let firestoreDatabase = Firestore.firestore()
    
    //status bar color
    override var preferredStatusBarStyle: UIStatusBarStyle{
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func changeEmailClicked(_ sender: Any) {
    }
    
    @IBAction func changeusernameClicked(_ sender: Any) {
    }
    
    @IBAction func changePasswordClicked(_ sender: Any) {
    }
    
    @IBAction func deleteAccountClicked(_ sender: Any) {
        //todo make sure this takes multiple steps to prevent accidents
        
        let currUser = Auth.auth().currentUser
        let currUserEmail = currUser!.email!
        print(currUserEmail)
        //update database of users
        firestoreDatabase.collection("userInfo").whereField("email", isEqualTo: currUserEmail).getDocuments { (snapshot, error) in
            if error != nil {
                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error getting user from DataBase.")
            }else{
                if snapshot?.isEmpty == false && snapshot != nil {
                    for doc in snapshot!.documents{
                        let docID = doc.documentID
                        self.firestoreDatabase.collection("userInfo").document(docID).delete(completion: { (error) in
                          if error != nil {
                                self.makeAlert(title: "Error", message: "Error deleting user from DataBase.")
                            }
                        })
                    }
                }
            }
        }
        //delete user auth profile
        currUser?.delete(completion: { (error) in
            if error != nil {
                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error deleting user.s")
            }else{
                self.performSegue(withIdentifier: "toLogInVCfromSettingsVC", sender: nil)
            }
        })
        
    }
    
    
    
    
    
    // usefule helper functions //////////
    func makeAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}
