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
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var playlistsFoundLabel: UILabel!
    
    @IBOutlet weak var playlistsCreatedLabel: UILabel!
    
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
        
        updateUserInfoUIPicture()
    }
    override func viewWillAppear(_ animated: Bool) {
        updateUserInfoUIText()
    }

    private func updateUserInfoUIPicture(){
        //do this in view did load - if done in view will appear it glitches and sometimes
        //will present a blank profile pic
        //make porfile pic the users chosen picture
        if UserSingleton.sharedUserInfo.profilePicURL != ""{
            profilePictureImageView.sd_setImage(with: URL(string: UserSingleton.sharedUserInfo.profilePicURL))
        }else{
            profilePictureImageView.image = UIImage(named: "profilePicGeneric")
        }
    }
    
    private func updateUserInfoUIText(){
        //make username the current user
        usernameLabel.text = UserSingleton.sharedUserInfo.username
        
        playlistsCreatedLabel.text = String(UserSingleton.sharedUserInfo.totalPlaylistsCreated)
        playlistsFoundLabel.text = String(UserSingleton.sharedUserInfo.totalPlaylistsFound)
        
        
        //set number of likes to users total like
        //TODO - handle actual liking functionality
        //totalLikesLabel.text = String(UserSingleton.sharedUserInfo.numTotalLikes)
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
        picker.allowsEditing = true
        self.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        profilePictureImageView.image = info[.editedImage] as? UIImage
        
        storeProfilePic()
        self.dismiss(animated: true, completion: nil)
    }
    
    private func storeProfilePic(){
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
                                                        
                            
                            //if user has profile pic already - delete it from storage
                            if UserSingleton.sharedUserInfo.profilePicURL != "" {
                                //delete old profile picture from storage
                                let oldURL = UserSingleton.sharedUserInfo.profilePicURL
                                let oldUUID = oldURL.components(separatedBy: "media%2F")[1].components(separatedBy: "?alt")[0]
                                mediaFolder.child(oldUUID).delete { (error) in
                                    
                                    //TODO what do error handle here - potentially do nothing
                                    if error != nil {
                                        self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Failed to delete data from storage")
                                    }
                                }
                            }
                            
                            
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
    
    
    
    
    
   
    
    
    
    // usefule helper functions //////////
    func makeAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
}
