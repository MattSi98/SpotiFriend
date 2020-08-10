//
//  addPlaylistVC.swift
//  SpotiFriend
//
//  Created by Matthew Simon on 8/2/20.
//  Copyright © 2020 Matthew Simon. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import CoreLocation

class addPlaylistVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {
    
    
    @IBOutlet weak var addPlaylistMapView: MKMapView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var linkTextField: UITextField!
    
    private var chosenLat : Double = 0.0
    private var chosenLong : Double = 0.0
    
    private let firestoreDatabase = Firestore.firestore()
    
    private var locationManager = CLLocationManager()
    
    
    
    //status bar color
    override var preferredStatusBarStyle: UIStatusBarStyle{
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        titleTextField.attributedPlaceholder =  NSAttributedString(string: "playlist name",attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        linkTextField.attributedPlaceholder =  NSAttributedString(string: "link (from Spotify)",attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        
        
        addPlaylistMapView.delegate = self
        configureLocationServices()
        
        
        //add gr
        let gr = UILongPressGestureRecognizer(target: self, action: #selector(mapLongPressed(gestureRecognizer:)))
        gr.minimumPressDuration = 2
        addPlaylistMapView.addGestureRecognizer(gr)
        
        
        titleTextField.delegate = self
        linkTextField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()   
        return true
    }
    

    
    @IBAction func addPlaylistClicked(_ sender: Any) {
        //get username
        let author = UserSingleton.sharedUserInfo.username
        //get map location from gest rec
        if titleTextField.text != "" && linkTextField.text != "" {
            if linkTextField.text!.contains("https://open.spotify.com"){
                //check if valid link
                let addDict = ["title": titleTextField.text!, "author" : author, "latitude" : chosenLat, "longitude" : chosenLong, "spotifyLink": linkTextField.text!, "date" : FieldValue.serverTimestamp(), "hasFound" : [String]()] as [String : Any]
                //add new playlist to "userPlaylists" db collection
                firestoreDatabase.collection("userPlaylists").addDocument(data: addDict) { (error) in
                    if error != nil {
                        //error
                        self.makeAlert(title: "Error", message: "Could not store playlist in database")
                    }
                }
                
                //update playlist in user info
                let updateDict = ["totalPlaylistsCreated" : UserSingleton.sharedUserInfo.totalPlaylistsCreated + 1] as [String : Any]
                firestoreDatabase.collection("userInfo").whereField("email", isEqualTo: UserSingleton.sharedUserInfo.email).getDocuments { (snapshot, error) in
                    if error != nil {
                        
                    }else{
                        if snapshot?.isEmpty == false && snapshot != nil && snapshot?.count == 1{
                            for doc in snapshot!.documents{
                                let docId = doc.documentID
                                
                                self.firestoreDatabase.collection("userInfo").document(docId).setData(updateDict, merge: true) { (error) in
                                    if error != nil {
                                        self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error storing data in DB.")
                                    }else{
                                        //update user singleton
                                        UserSingleton.sharedUserInfo.totalPlaylistsCreated += 1
                                        self.performSegue(withIdentifier: "fromAddPlaylistVCtoTabBarVC", sender: nil)
                                    }
                                
                                }
                            }
                        }
                    }
                }
            }else{
                makeAlert(title: "Error", message: "Please enter valid Spotify Playlist Link.")
            }
        }
    }
    
    
    @objc func mapLongPressed(gestureRecognizer : UILongPressGestureRecognizer ){
        
        if gestureRecognizer.state == .began{
            let touch = gestureRecognizer.location(in: self.addPlaylistMapView)
            
            let coords = self.addPlaylistMapView.convert(touch, toCoordinateFrom: self.addPlaylistMapView)
            
            chosenLat = coords.latitude
            chosenLong = coords.longitude
            
            //add pin to map
            let annotation = MKPointAnnotation()
            annotation.title = "Playlist will be placed here!"
            annotation.subtitle = "tap again to replace"
            annotation.coordinate = coords
            addPlaylistMapView.addAnnotation(annotation)
            
            
        }
        
    }
    
    //-------------------MAPS--------------------------------------
    private func configureLocationServices(){
        
        locationManager.delegate = self
        let status = CLLocationManager.authorizationStatus()
           
        if status == .notDetermined{
            locationManager.requestWhenInUseAuthorization()

        }else if status == .authorizedAlways || status == .authorizedWhenInUse{
            beginLocationUpdates(locationManager : locationManager)
        }
    }
       
    private func beginLocationUpdates(locationManager : CLLocationManager){
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
           
        addPlaylistMapView.showsUserLocation = true
    }
    
    
    
    
    
    // usefule helper functions //////////
    func makeAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
}
