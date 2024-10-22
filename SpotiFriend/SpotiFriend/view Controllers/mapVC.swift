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
import SDWebImage

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
        
        //add static annotations
        addStaticAnnotations()
        
        //add User annotations
        addUserAnnotations()
        
        //set up location services
        configureLocationServices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //update user singleton for use throughout app
        getUserInfo()
    }

    
    @IBAction func reloadMapClicked(_ sender: Any) {
        updateAnnotations()
    }
    
    func updateAnnotations(){
        mapView.removeAnnotations(mapView.annotations)
        
        addStaticAnnotations()

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
        locationManager.distanceFilter = 400.0
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
           
        mapView.showsUserLocation = true
    }
       
    private func zoomToLatestLoc(coord : CLLocationCoordinate2D){
        //add map rad to usersingleton
        //convert miles to meters
        //use that as span
        
        updateAnnotations()
        
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
                                                    
                                                    
                                                    //distance check here - dont add to map if not within map raius
                                                    if let delta = self.mapView.userLocation.location?.distance(from: CLLocation(latitude: lat, longitude: long)){
                                                        if delta.magnitude <= UserSingleton.sharedUserInfo.mapRadius {
                                                            self.mapView.addAnnotation(annotation)
                                                        }
                                                    }else{
                                                        self.makeAlert(title: "Error", message: "Error in displaying map annotations within radius")
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
    }
    
    
    
    
    
    //edit pins to have button for navigation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //dont put pin on user location
        if annotation is MKUserLocation {
            return nil
        }
        let pinView2 = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
        pinView2.image = UIImage(named: "playlistIcon")
        
        
        pinView2.canShowCallout = true
        pinView2.tintColor = UIColor.green
        
        //custom annotation picture
        let lat = (pinView2.annotation?.coordinate.latitude)!
        let long = (pinView2.annotation?.coordinate.longitude)!
        var url = ""
        firestoreDatabase.collection("userPlaylists").whereField("latitude", isEqualTo: lat).whereField("longitude", isEqualTo: long).getDocuments { (snapshot, error) in
            if error != nil {
                self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error accessign DB.")
            }else{
                if snapshot?.isEmpty == false && snapshot != nil {
                    for doc in snapshot!.documents {
                        if let email = doc.get("email") as? String {
                            self.firestoreDatabase.collection("userInfo").whereField("email", isEqualTo: email).getDocuments { (snapshot, error) in
                                if error != nil {
                                    self.makeAlert(title: "Error", message: error?.localizedDescription ?? "Error accessing DB")
                                }else{
                                    if snapshot?.isEmpty == false && snapshot != nil {
                                        for doc in snapshot!.documents {
                                            if let profilePicURL = doc.get("profilePicURL") as? String {
                                                url = profilePicURL
                                                let newURL = URL(string: url)!
                                                let data = try? Data(contentsOf: newURL)
                                                
                                                if let imageData = data {
                                                    let profilePic = UIImage(data: imageData)
                                                    let scaledImage = profilePic!.scalePreservingAspectRatio(targetSize: CGSize(width: 35, height: 35))
                                                        .sd_roundedCornerImage(withRadius: 25, corners: .allCorners, borderWidth: 2, borderColor: .green)
                                                    pinView2.image = scaledImage
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
        
        if url == "" {
            pinView2.image = UIImage(named: "playlistIcon")
        }
        
        let button = UIButton(type: .detailDisclosure)
        pinView2.rightCalloutAccessoryView = button
        
        
        return pinView2
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



extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}


