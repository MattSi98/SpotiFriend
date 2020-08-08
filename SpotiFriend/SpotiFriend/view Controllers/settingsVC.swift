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
    
    private let firestoreDatabase = Firestore.firestore()
    private var editIdentifier = ""
    
    //status bar color
    override var preferredStatusBarStyle: UIStatusBarStyle{
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        mapRadiusTextField.text = "\(UserSingleton.sharedUserInfo.mapRadius/1609)"
    }
    
    
    @IBAction func updateMapRadiusClicked(_ sender: Any) {
        firestoreDatabase.collection("userInfo").whereField("email", isEqualTo: Auth.auth().currentUser!.email!).getDocuments { (snapshot, error) in
            if error != nil {
                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error accessing database")
            }else{
                if snapshot?.isEmpty == false && snapshot != nil {
                    if (snapshot?.documents.count)! > 1 {
                        print("error")
                    }else{
                        for doc in snapshot!.documents{
                            let docID = doc.documentID
                            
                            let updatedDict = ["mapRadius" : Double(self.mapRadiusTextField.text!) ?? 25] as [String : Any]
                            self.firestoreDatabase.collection("userInfo").document(docID).setData(updatedDict, merge: true) { (error) in
                                if error != nil {
                                    self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error storing into database")
                                }else{
                                    UserSingleton.sharedUserInfo.mapRadius = (Double(self.mapRadiusTextField.text!) ?? 25) * 1609
                                }
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toEditAccountVCfromSettingsVC"{
            let destVC = segue.destination as! editAccountVC
            destVC.selectedEditID = editIdentifier
        }
    }
    
    @IBAction func changeEmailClicked(_ sender: Any) {
        editIdentifier = "email"
        performSegue(withIdentifier: "toEditAccountVCfromSettingsVC", sender: nil)
    }
    
    @IBAction func changeusernameClicked(_ sender: Any) {
        editIdentifier = "username"
        performSegue(withIdentifier: "toEditAccountVCfromSettingsVC", sender: nil)
    }
    
    @IBAction func changePasswordClicked(_ sender: Any) {
        editIdentifier = "password"
        performSegue(withIdentifier: "toEditAccountVCfromSettingsVC", sender: nil)
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
