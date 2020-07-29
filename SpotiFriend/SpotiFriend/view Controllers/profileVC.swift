//
//  profileVC.swift
//  SpotiFriend
//
//  Created by Matthew Simon on 7/26/20.
//  Copyright © 2020 Matthew Simon. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class profileVC: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
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
        
        updateUserInfoUI()
    }

    
    func updateUserInfoUI(){
        //make username the current user
        usernameLabel.text = UserSingleton.sharedUserInfo.username
        //make porfile pic the users chosen picture
        if UserSingleton.sharedUserInfo.profilePicURL != ""{
            profilePictureImageView.sd_setImage(with: URL(string: UserSingleton.sharedUserInfo.profilePicURL))
        }else{
            profilePictureImageView.image = UIImage(named: "profilePicGeneric")
        }
        
        //set number of likes to users total like
        //TODO - handle actual liking functionality
        totalLikesLabel.text = String(UserSingleton.sharedUserInfo.numTotalLikes)
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
        //segue to picker vc then dismiss that vc when picking done
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        profilePictureImageView.image = info[.originalImage] as? UIImage
        
        storeProfilePic()
        self.dismiss(animated: true, completion: nil)
    }
    
    func storeProfilePic(){
        //Storage
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let mediaFolder = storageRef.child("media")
        
        if let data = profilePictureImageView.image?.jpegData(compressionQuality: 0.5){
            let uuid = UUID().uuidString
            let imageRef = mediaFolder.child("\(uuid).jpg")
            imageRef.putData(data, metadata: nil) { (metadata, error) in
                if error != nil {
                    self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error putting img data in storage")
                }else{
                    imageRef.downloadURL { (URL, error) in
                        if error == nil {
                            let imgURL = URL?.absoluteString
                            
                            
                            //Firestore
                            //must store profile picture in firebase storage
                            let firestoreDatabase = Firestore.firestore()
                            firestoreDatabase.collection("userInfo").whereField("email", isEqualTo: UserSingleton.sharedUserInfo.email).getDocuments { (snapshot, error) in
                                if error != nil {
                                    self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error accessing current userinfo in database")
                                }else{
                                    if snapshot?.isEmpty == false && snapshot != nil {
                                        for doc in snapshot!.documents {
                                            let docID = doc.documentID
                                            
                                            let additionDict = ["profilePicURL" : imgURL!] as [String : Any]
                                            
                                            firestoreDatabase.collection("userInfo").document(docID).setData(additionDict, merge: true) { (error) in
                                                if error != nil {
                                                    self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error storing imgURL in userInfo")
                                                }else{
                                                    //must add pic url to usersingleton
                                                    UserSingleton.sharedUserInfo.profilePicURL = imgURL!
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        
    }
    
    
    
    
    
    
    @IBAction func followersClicked(_ sender: Any) {
        //TODO
        makeAlert(title: "TODO", message: "Coming soon!")
    }
    
    @IBAction func followingClicked(_ sender: Any) {
        //TODO
        makeAlert(title: "TODO", message: "Coming soon!")

    }
    
    
    
    // usefule helper functions //////////
    func makeAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
}
