//
//  logInVC.swift
//  SpotiFriend
//
//  Created by Matthew Simon on 7/26/20.
//  Copyright © 2020 Matthew Simon. All rights reserved.
//

import UIKit
import Firebase

class logInVC: UIViewController {
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!


    //status bar color
    override var preferredStatusBarStyle: UIStatusBarStyle{
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        emailTextField.attributedPlaceholder =  NSAttributedString(string: "email",attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        passwordTextField.attributedPlaceholder =  NSAttributedString(string: "password",attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
    
    
    
    @IBAction func logInClicked(_ sender: Any) {
        if emailTextField.text != "" && passwordTextField.text != ""{
            Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (authResult, error) in
                if error != nil {
                    self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error while signing user in")
                }else{
                    self.performSegue(withIdentifier: "toMapVCfromLogInVC", sender: nil)
                }
            }
        }else{
            makeAlert(title: "Error", message: "Please enter valid credentials")
        }
        
        
    }
    

    @IBAction func signUpClicked(_ sender: Any) {
        performSegue(withIdentifier: "toSignUpVC", sender: nil)
    }
    
    @IBAction func forgotPasswordClicked(_ sender: Any) {
        //TODO
        makeAlert(title: "TODO", message: "this is just a test to see what happens when you add a lot of writting in these alerts.")
    }
    
    
    
    
    // usefule helper functions //////////
    func makeAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}
