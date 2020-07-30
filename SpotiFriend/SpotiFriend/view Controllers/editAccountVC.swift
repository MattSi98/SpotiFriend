//
//  editAccountVC.swift
//  SpotiFriend
//
//  Created by Matthew Simon on 7/30/20.
//  Copyright © 2020 Matthew Simon. All rights reserved.
//

import UIKit
import Firebase


class editAccountVC: UIViewController {

    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var desiredTextField: UITextField!
    
    
    var selectedEditID = ""
    let firestoreDatabase = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        instructionsLabel.text = "Please enter your desired \(selectedEditID) in the box below and press update."
    }
    

    
    @IBAction func updateClicked(_ sender: Any) {
        //must update correct auth and userInfo fields
        //must segue/dismiss this segue to return to the settings VC
        //update uerSingleton

        
        if selectedEditID == "email"{
            let oldEmail = Auth.auth().currentUser!.email!
            if desiredTextField.text != "" && desiredTextField.text!.isValidEmail{
                Auth.auth().currentUser?.updateEmail(to: desiredTextField.text!, completion: { (error) in
                    if error != nil {
                        self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error updating email.")
                    }else{
                        //update userInfo in database
                        self.firestoreDatabase.collection("userInfo").whereField("email", isEqualTo: oldEmail).getDocuments { (snapshot, error) in
                            if error != nil {
                                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error accessing database")
                            }else{
                                if snapshot?.isEmpty == false && snapshot != nil {
                                    if (snapshot?.documents.count)! > 1 {
                                        print("error")
                                    }else{
                                        for doc in snapshot!.documents{
                                            let docID = doc.documentID
                                            
                                            let updatedDict = ["email" : self.desiredTextField.text!] as [String : Any]
                                            self.firestoreDatabase.collection("userInfo").document(docID).setData(updatedDict, merge: true) { (error) in
                                                if error != nil {
                                                    self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error storing into database")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        //return to settingsVC and update userSingleton
                        UserSingleton.sharedUserInfo.email = self.desiredTextField.text!
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            }else{
                makeAlert(title: "Error", message: "please enter valid email address")
            }
            
            
        }else if selectedEditID == "password"{
            if desiredTextField.text != "" {
                Auth.auth().currentUser?.updatePassword(to: desiredTextField.text!, completion: { (error) in
                    if error != nil {
                        self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error updating password.")
                    }else{
                        //update userInfo in database
                        self.firestoreDatabase.collection("userInfo").whereField("email", isEqualTo: Auth.auth().currentUser!.email!).getDocuments { (snapshot, error) in
                            if error != nil {
                                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error accessing database")
                            }else{
                                if snapshot?.isEmpty == false && snapshot != nil {
                                    if (snapshot?.documents.count)! > 1 {
                                        print("error")
                                    }else{
                                        for doc in snapshot!.documents{
                                            let docID = doc.documentID
                                            
                                            let updatedDict = ["password" : self.desiredTextField.text!] as [String : Any]
                                            self.firestoreDatabase.collection("userInfo").document(docID).setData(updatedDict, merge: true) { (error) in
                                                if error != nil {
                                                    self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error storing into database")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        //return to settingsVC and update userSingleton
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            }else{
                makeAlert(title: "Error", message: "please enter valid password")
            }
            
        }else if selectedEditID == "username"{
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
                                
                                let updatedDict = ["username" : self.desiredTextField.text!] as [String : Any]
                                self.firestoreDatabase.collection("userInfo").document(docID).setData(updatedDict, merge: true) { (error) in
                                    if error != nil {
                                        self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error storing into database")
                                    }else{
                                        //return to settingsVC and update userSingleton
                                        UserSingleton.sharedUserInfo.username = self.desiredTextField.text!
                                        self.dismiss(animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            
        }else{
            makeAlert(title: "Error", message: "impossible state")
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


//validate user input
extension String {
   var isValidEmail: Bool {
      let regularExpressionForEmail = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
      let testEmail = NSPredicate(format:"SELF MATCHES %@", regularExpressionForEmail)
      return testEmail.evaluate(with: self)
   }
   var isValidPhone: Bool {
      let regularExpressionForPhone = "^\\d{3}-\\d{3}-\\d{4}$"
      let testPhone = NSPredicate(format:"SELF MATCHES %@", regularExpressionForPhone)
      return testPhone.evaluate(with: self)
   }
}
