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
import CoreLocation

class mapVC: UIViewController, MKMapViewDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    //db vars
    private let firestoreDatabase = Firestore.firestore()
    //map vars
    private let locationManager = CLLocationManager()
    private var currentCoord : CLLocationCoordinate2D?
    
    
    
    //status bar color
    override var preferredStatusBarStyle: UIStatusBarStyle{
        .lightContent
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        mapView.delegate = self
        
        //add static annotation
        addStaticAnnotations()
        //set up location services
        configureLocationServices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //update user singleton for use throughout app
        getUserInfo()
        
        //add User annotation
        addUserAnnotations()
    }
    
    
    
    @IBAction func addPlaylistCLicked(_ sender: Any) {
        performSegue(withIdentifier: "fromMapVCtoAddPlaylistVC", sender: nil)
    }
    
        
    //-------------------------DATABASE---------------------------------------
    private func getUserInfo(){
        //clear data first
        UserSingleton.sharedUserInfo.email = ""
        UserSingleton.sharedUserInfo.username = ""
        UserSingleton.sharedUserInfo.profilePicURL = ""
        UserSingleton.sharedUserInfo.mapRadius = 40225
        
        UserSingleton.sharedUserInfo.totalPlaylistsCreated = 0
        UserSingleton.sharedUserInfo.totalPlaylistsFound = 0
        
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
                                //but will nto always have a profile picture/map rad
                                if let profilePicURL = doc.get("profilePicURL") as? String {
                                    UserSingleton.sharedUserInfo.profilePicURL = profilePicURL
                                }
                                if let radius = doc.get("mapRadius") as? Double {
                                    UserSingleton.sharedUserInfo.mapRadius = (radius * 1609) //convert miles to meters
                                }
                                if let playlistsCreated = doc.get("totalPlaylistsCreated") as? Int {
                                    UserSingleton.sharedUserInfo.totalPlaylistsCreated = playlistsCreated
                                }
                                if let playlistsFound = doc.get("totalPlaylistsFound") as? Int {
                                    UserSingleton.sharedUserInfo.totalPlaylistsFound = playlistsFound
                                }
                                
                            }
                        }
                    }
                }
                
            }
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
           
        mapView.showsUserLocation = true
    }
       
    private func zoomToLatestLoc(coord : CLLocationCoordinate2D){
        //add map rad to usersingleton
        //convert miles to meters
        //use that as span
        let region = MKCoordinateRegion.init(center: coord, latitudinalMeters: UserSingleton.sharedUserInfo.mapRadius, longitudinalMeters: UserSingleton.sharedUserInfo.mapRadius)
        mapView.setRegion(region, animated: true)
    }
    
    
    
    
    private func addStaticAnnotations(){
        firestoreDatabase.collection("masterPlaylists").getDocuments { (snapshot, error) in
            if error != nil {
                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error accessing database.")
            }else{
                if snapshot?.isEmpty == false && snapshot != nil {
                    for doc in snapshot!.documents{
                        
                        let annotation = MKPointAnnotation()
                        
                        if let title = doc.get("title") as? String{
                            if let author = doc.get("author") as? String{
                                if let lat = doc.get("latitude") as? Double{
                                    if let long = doc.get("longitude") as? Double{
                                        
                                        annotation.title = title
                                        annotation.subtitle = author
                                        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                                        //add distance check here - dont add to map if not within map raius
                                        self.mapView.addAnnotation(annotation)
                                    }
                                }
                            }
                        }
                        
                        
                    }
                }
            }
        }
    }
    
    
    private func addUserAnnotations(){
        firestoreDatabase.collection("userPlaylists").getDocuments { (snapshot, error) in
            if error != nil {
                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error accessing database.")
            }else{
                if snapshot?.isEmpty == false && snapshot != nil {
                    for doc in snapshot!.documents{
                        
                        if let dateUploaded = doc.get("date") as? Timestamp {
                            if let timeDelta = Calendar.current.dateComponents([.day], from: dateUploaded.dateValue(), to: Date()).day{
                                
                                if timeDelta > 7 {
                                    self.firestoreDatabase.collection("userPlaylists").document(doc.documentID).delete { (error) in
                                        if error != nil {
                                            self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error deleting old playlist")
                                        }
                                    }
                                }else{
                                    let annotation = MKPointAnnotation()
                                    
                                    if let title = doc.get("title") as? String{
                                        if let author = doc.get("author") as? String{
                                            if let lat = doc.get("latitude") as? Double{
                                                if let long = doc.get("longitude") as? Double{
                                                    
                                                    annotation.title = title
                                                    annotation.subtitle = author
                                                    annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                                                    //add distance check here - dont add to map if not within map raius
                                                    self.mapView.addAnnotation(annotation)
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
    
    
    
    
    
    //edit pins to have button for navigation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //dont put pin on user location
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil{
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.green
            
            pinView?.image = UIImage(named: "playlistIcon")
            
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
            
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let lat = Double((view.annotation?.coordinate.latitude)!)
        let long = Double((view.annotation?.coordinate.longitude)!)
        
        checkMasterPlaylists(latitude: lat, longitude: long)
        checkUserPlaylists(latitude: lat, longitude: long)
        
    }
    
    
    func checkMasterPlaylists(latitude : Double , longitude : Double){
        firestoreDatabase.collection("masterPlaylists").whereField("latitude", isEqualTo: latitude).whereField("longitude", isEqualTo: longitude).getDocuments { (snapshot, error) in
            if error != nil {
                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error")
            }else{
                if snapshot?.isEmpty == false && snapshot != nil {
                    for doc in snapshot!.documents{
                        let docID = doc.documentID
                        let link = doc.get("spotifyLink") ?? "https://open.spotify.com/playlist/4GLAacEIQe2N4Wa3p1jGFU?si=ElxTEduuSiiuPc_niVpKUQ"
                        
                        //update number of playlists found
                        if var hasFound = doc.get("hasFound") as? [String]{
                            let currUserEmail = UserSingleton.sharedUserInfo.email
                            if !(hasFound.contains(currUserEmail)){
                                //add emial to list
                                hasFound.append(currUserEmail)
                                let updateDict = ["hasFound" : hasFound] as [String : Any]
                                
                                self.firestoreDatabase.collection("masterPlaylists").document(docID).setData( updateDict, merge: true) { (error) in
                                    if error != nil {
                                        self.makeAlert(title: "Error", message: error?.localizedDescription ?? "error in DB")
                                    }else{
                                        //add 1 to userinfo playlists found
                                        self.firestoreDatabase.collection("userInfo").whereField("email", isEqualTo: currUserEmail).getDocuments { (snapshot, error) in
                                            if error != nil {
                                                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error in DB")
                                            }else{
                                                if snapshot?.isEmpty == false && snapshot != nil {
                                                    for doc in snapshot!.documents {
                                                        let docID = doc.documentID
                                                        
                                                        let updateDict = ["totalPlaylistsFound" : UserSingleton.sharedUserInfo.totalPlaylistsFound + 1] as [String : Any]
                                                        self.firestoreDatabase.collection("userInfo").document(docID).setData(updateDict, merge: true) { (error) in
                                                            if error != nil {
                                                                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error in DB")
                                                            }else{
                                                                //update user singleton
                                                                UserSingleton.sharedUserInfo.totalPlaylistsFound += 1
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
                        
                        
                        func schemeAvailable(scheme: String) -> Bool {
                          if let url = URL(string: scheme) {
                            return UIApplication.shared.canOpenURL(url)
                          }
                          return false
                        }
                        
                        let spotifyInstalled = schemeAvailable(scheme: "spotify://")
                        
                        if spotifyInstalled == true {
                            //open link in spotify
                            let url = URL(string: link as! String)
                            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                        }else{
                            //TODO
                            self.makeAlert(title: "Spotify Required", message: "Please download and install Spotify from the AppStore!")
                        }
                        
                    }
                }
            }
        }
    }
    
    
    func checkUserPlaylists(latitude : Double , longitude : Double){
        firestoreDatabase.collection("userPlaylists").whereField("latitude", isEqualTo: latitude).whereField("longitude", isEqualTo: longitude).getDocuments { (snapshot, error) in
            if error != nil {
                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error")
            }else{
                if snapshot?.isEmpty == false && snapshot != nil {
                    for doc in snapshot!.documents{
                        let docID = doc.documentID
                        let link = doc.get("spotifyLink") ?? "https://open.spotify.com/playlist/4GLAacEIQe2N4Wa3p1jGFU?si=ElxTEduuSiiuPc_niVpKUQ"
                        
                        //update number of playlists found
                        if var hasFound = doc.get("hasFound") as? [String]{
                            let currUserEmail = UserSingleton.sharedUserInfo.email
                            if !(hasFound.contains(currUserEmail)){
                                //add emial to list
                                hasFound.append(currUserEmail)
                                let updateDict = ["hasFound" : hasFound] as [String : Any]
                                
                                self.firestoreDatabase.collection("userPlaylists").document(docID).setData( updateDict, merge: true) { (error) in
                                    if error != nil {
                                        self.makeAlert(title: "Error", message: error?.localizedDescription ?? "error in DB")
                                    }else{
                                        //add 1 to userinfo playlists found
                                        self.firestoreDatabase.collection("userInfo").whereField("email", isEqualTo: currUserEmail).getDocuments { (snapshot, error) in
                                            if error != nil {
                                                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error in DB")
                                            }else{
                                                if snapshot?.isEmpty == false && snapshot != nil {
                                                    for doc in snapshot!.documents {
                                                        let docID = doc.documentID
                                                        
                                                        let updateDict = ["totalPlaylistsFound" : UserSingleton.sharedUserInfo.totalPlaylistsFound + 1] as [String : Any]
                                                        self.firestoreDatabase.collection("userInfo").document(docID).setData(updateDict, merge: true) { (error) in
                                                            if error != nil {
                                                                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error in DB")
                                                            }else{
                                                                //update user singleton
                                                                UserSingleton.sharedUserInfo.totalPlaylistsFound += 1
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
                        
                        
                        func schemeAvailable(scheme: String) -> Bool {
                          if let url = URL(string: scheme) {
                            return UIApplication.shared.canOpenURL(url)
                          }
                          return false
                        }
                        
                        let spotifyInstalled = schemeAvailable(scheme: "spotify://")
                        
                        if spotifyInstalled == true {
                            //open link in spotify
                            let url = URL(string: link as! String)
                            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                        }else{
                            //TODO - guide user to install spotify
                            self.makeAlert(title: "Spotify Required", message: "Please download and install Spotify from the AppStore!")
                        }
                        
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    
    
    //----------------------usefule helper functions---------------------------------------
    private func makeAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }

}




extension mapVC : CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLoc = locations.first else { return }
        currentCoord = latestLoc.coordinate
        zoomToLatestLoc(coord: latestLoc.coordinate)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse{
            beginLocationUpdates(locationManager: manager)
        }
    }
    
}


