//
//  signUpVC.swift
//  SpotiFriend
//
//  Created by Matthew Simon on 7/26/20.
//  Copyright © 2020 Matthew Simon. All rights reserved.
//

import UIKit
import Firebase

class signUpVC: UIViewController {
    
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    //status bar color
    override var preferredStatusBarStyle: UIStatusBarStyle{
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        usernameTextField.attributedPlaceholder =  NSAttributedString(string: "username",attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        emailTextField.attributedPlaceholder =  NSAttributedString(string: "email address",attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        passwordTextField.attributedPlaceholder =  NSAttributedString(string: "password",attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
    

    @IBAction func signUpClicked(_ sender: Any) {
        if usernameTextField.text != "" && emailTextField.text != "" && passwordTextField.text != "" {
            Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (authResult, error) in
                if error != nil {
                    //error handle
                    self.makeAlert(title: "Error", message: error?.localizedDescription ?? "error in creating user")
                }else {
                    //save user to firebase
                    let firestore = Firestore.firestore()
                    let userDict = ["username" : self.usernameTextField.text!, "email" : self.emailTextField.text!, "password" : self.passwordTextField.text!] as [String : Any]
                    firestore.collection("userInfo").addDocument(data: userDict) { (error) in
                        if error != nil {
                            self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error storing user data")
                        }
                    }
                    self.performSegue(withIdentifier: "toMapVCfromSignUpVC", sender: nil)
                }
            }
            
        }else{
            makeAlert(title: "Error", message: "Please enter valid credentials")
        }
        
        
    }
    
    @IBAction func needhelpClicked(_ sender: Any) {
        //TODO
        makeAlert(title: "TODO", message: "coming soon!")
        
    }
    
    
    
    // usefule helper functions //////////
    func makeAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}
