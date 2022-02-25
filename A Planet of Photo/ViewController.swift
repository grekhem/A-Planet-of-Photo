//
//  ViewController.swift
//  A Planet of Photo
//
//  Created by Grekhem on 09.01.2022.
//

import UIKit
import Firebase
import FirebaseAuth
import MapKit


class ViewController: UIViewController, MKMapViewDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var myUser = User()
    var idSecondPlayer = ""
    var secondPlayer = ""
    let locationManager = CLLocationManager()
    var imageSend: UIImage?
    var countSearch = 0
    var countWaiting = 0
    var timer = Timer()
    var isIUpload = false
    var message = "" {
        willSet {
            if message != newValue {
                if newValue != "" {
                    playView.isHidden = false
                    self.view.addSubview(playView)
                    playViewText.text = newValue
                    playNoButton.isHidden = false
                    playYesButton.isHidden = false
                    playButton.isHidden = true
                } else {
                    playView.isHidden = false
                    self.view.addSubview(playView)
                    playViewText.text = "Start looking for a second player?"
                    playNoButton.isHidden = true
                    playYesButton.isHidden = true
                    playButton.isHidden = false
                }
            }
        }
    }
    
    var playerOnlineArray = [String]() {
        didSet {
            searchPlayer()
        }
    }
    
    var imageUrl = "" {
        didSet {
            switch imageUrl{
            case "":
                imageMessageView.isHidden = true
            default:
                DispatchQueue.global().async {
                    let image = self.loadImage()
                    DispatchQueue.main.async {
                        self.imageMessageView.image = image
                        if self.isIUpload {
                            self.imageMessageView.image = image
                            self.imageMessageView.isHidden = false
                            
                        }
                    }
                }
                    //imageMessageView.isHidden = false
            }
            
        }
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var secondPlayerLabel: UILabel! 
    @IBOutlet weak var myPlayerNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var playViewText: UITextView!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchLabel: UILabel!
    @IBOutlet weak var imageMessageView: UIImageView!
    @IBOutlet weak var playNoButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playYesButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    
    @IBAction func imagePickerBtnAction(_ sender: Any) {
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                    self.openCamera()
                }))

                alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
                    self.openGallery()
                }))

                alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

                self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        do{
            try Auth.auth().signOut()
        } catch {
            print(error)
        }
    }
    
    @IBAction func addPlayerAction(_ sender: UIButton) {
            getListOfPlayer()
    }
    
    @IBAction func playYes(_ sender: UIButton) {
        baseRef.child(myUser.uid).updateChildValues(["isWantPlay" : true])
        playView.isHidden = true
        photoButton.isHidden = false
    }
    
    @IBAction func playNoAction(_ sender: Any) {
        baseRef.child(myUser.uid).updateChildValues(["message" : ""])
        baseRef.child(myUser.uid).updateChildValues(["isOnline" : true])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user == nil {
                self.showModalAuth()
            } else {
                self.checkLocationEnable()
                self.updateMyUser()
                self.observeMessage()
            }
        }
    }
    
    func updateMyUser(){
        self.myUser.uid = Auth.auth().currentUser?.uid ?? ""
        baseRef.child(myUser.uid).updateChildValues(["isWantPlay" : false])
        baseRef.child(myUser.uid).updateChildValues(["message" : ""])
        baseRef.child(myUser.uid).updateChildValues(["isOnline" : true])
        baseRef.child(myUser.uid).updateChildValues(["imageUrl" : ""])
        baseRef.child(myUser.uid).updateChildValues(["secondPlayer" : ""])
        myUser.latitude = locationManager.location?.coordinate.latitude ?? 0
        myUser.longitude = locationManager.location?.coordinate.longitude ?? 0
        baseRef.child(myUser.uid).updateChildValues(["latitude" : myUser.latitude])
        baseRef.child(myUser.uid).updateChildValues(["longitude" : myUser.longitude])
        baseRef.child(self.myUser.uid).observeSingleEvent(of: .value, with:  { (snapshot) in
        let val = snapshot.value as? NSDictionary
        self.myUser.name = (val?["name"] ?? "") as! String
        })
    }
    
    func getListOfPlayer(){
            var array = [String]()
            var count = 0
            baseRef.observeSingleEvent(of: .value ) { snapshot in
                for i in snapshot.value as? [String : Any] ?? [:] {
                    count += 1
                    if let x = i.value as? NSDictionary {
                        if let y = x.value(forKey: "isOnline") {
                            if y as! Int == 1 {
                                i.key != self.myUser.uid ? array.append(i.key ) : nil
                                    }}
                        if count == snapshot.childrenCount {
                            self.playerOnlineArray = array
                            }
                            }
                   
                }
            }
    }
    
    func searchPlayer() {
        switch playerOnlineArray.count {
        case 0:
            searchLabel.text = "Search"
            searchView.isHidden = false
            playView.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                self.countSearch += 1
                if self.countSearch == 10 {
                    self.playView.isHidden = false
                    self.searchView.isHidden = true
                    self.countSearch = 0
                } else {
                    self.getListOfPlayer()
                }
            })
        default:
            //searchView.isHidden = true
            playView.isHidden = true
            self.countSearch = 0
            idSecondPlayer = playerOnlineArray[Int.random(in: 0...playerOnlineArray.count - 1)]
            baseRef.child(idSecondPlayer).updateChildValues(["isOnline" : false])
            baseRef.child(myUser.uid).updateChildValues(["isOnline" : false])
            baseRef.child(idSecondPlayer).updateChildValues(["message" : "Do you want play with \(myUser.name)?"])
            baseRef.child(idSecondPlayer).updateChildValues(["secondPlayer" : "\(myUser.uid)"])
            waitingAnswer()
        }
            
    }
    
    func waitingAnswer(){
        var count = 0
        self.searchLabel.text = "Waiting answer"
        self.searchView.isHidden = false
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            count += 1
            baseRef.child(self.idSecondPlayer).observeSingleEvent(of: .value, with:  { (snapshot) in
                let val = snapshot.value as? NSDictionary
                if let want = val?["isWantPlay"] as? Bool {
                    if want {
                        timer.invalidate()
                        self.searchView.isHidden = true
                        self.searchLabel.text = "Search"
                        baseRef.child(self.myUser.uid).updateChildValues(["secondPlayer" : "\(self.idSecondPlayer)"])
                        self.photoButton.isHidden = false
                    } else if count >= 10 {
                        timer.invalidate()
                        self.searchView.isHidden = true
                        self.playView.isHidden = false
                        baseRef.child(self.idSecondPlayer).updateChildValues(["isOnline" : true])
                        baseRef.child(self.myUser.uid).updateChildValues(["isOnline" : true])
                        baseRef.child(self.idSecondPlayer).updateChildValues(["message" : ""])
                        baseRef.child(self.idSecondPlayer).updateChildValues(["secondPlayer" : ""])
                        //self.getListOfPlayer()
                    }
                }
            })
        }
    }
    
    func loadImage() -> UIImage? {
        if let url = URL(string: imageUrl),
            let data = try? Data(contentsOf: url){
                return UIImage(data: data)
            }
         return nil
    }
    
    func showModalAuth() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as! AuthViewController
        present(newVC, animated: true, completion: nil)
        }
    
    func checkLocationEnable(){
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            }else{
            showAlertLocation(title: "You have disabled the geolocation service", message: "Want to turn it on?", url: URL(string: "App-Prefs:root=LOCATION_SERVICES"))
        }
    }
    
    func showAlertLocation(title: String, message: String?, url: URL? ){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { alert in
            if let url = url{
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func checkLocationAuthorization(){
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            //setupGame()
            break
        case .authorizedWhenInUse:
            //setupGame()
            break
        case .denied:
            showAlertLocation(title: "You have banned the use of the location", message: "Do you want to change this?", url: URL(string: UIApplication.openSettingsURLString))
            break
        case .restricted:
            showAlertLocation(title: "You have banned the use of the location", message: "Do you want to change this?", url: URL(string: UIApplication.openSettingsURLString))
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            checkLocationAuthorization()
        @unknown default:
            fatalError()
        }
    }
    
    func observeMessage(){
        baseRef.child(myUser.uid).observe(.value) { snapshot in
        let i = snapshot.value as? [String : Any]
        if let x = i {
            self.message = x["message"] as! String
            self.imageUrl = x["imageUrl"] as! String
            self.secondPlayer = x["secondPlayer"] as! String
            
            }
        }
    }
    
    func setupGame(){
        mapView.showsUserLocation = true
        let region = MKCoordinateRegion(center: self.locationManager.location!.coordinate, latitudinalMeters: 50000, longitudinalMeters: 50000)
        mapView.setRegion(region, animated: true)
        self.view.addSubview(playView)
        playView.center = self.view.center
        playViewText.layer.cornerRadius = 5
        view.addSubview(self.searchView)
        searchView.isHidden = true
        searchView.center = self.view.center
        locationManager.stopUpdatingLocation()
    }

    
    
    func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.startUpdatingLocation()
        checkLocationAuthorization()
        
    }
    
    func openGallery()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func openCamera()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func uploadImage(photoName: String, photo: UIImage, completion: @escaping (Result<URL, Error>) -> Void){
        let refStorage = Storage.storage().reference().child("uploadImage").child(photoName)
        guard let imageData = imageSend?.jpegData(compressionQuality: 0.4) else { return }
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        refStorage.putData(imageData, metadata: metadata) { metadata, error in
            guard let metadata = metadata else {
                completion(.failure(error!))
                return
                }
            refStorage.downloadURL { url, error in
                guard let url = url else {
                    completion(.failure(error!))
                    return
                }
                completion(.success(url))
                baseRef.child(self.secondPlayer).updateChildValues(["imageUrl" : url.absoluteString])
                self.isIUpload = true
                self.photoButton.isHidden = true
                if self.imageUrl != "" {
                    self.imageMessageView.isHidden = false
                }
            }
        }
    }
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else {
           fatalError()
        }
        imageSend = selectedImage
        uploadImage(photoName: myUser.uid, photo: imageSend!) { result in
            switch result{
            case .success(let url):
                print(url)
            case .failure(let error):
                print(error)
            }
        }
        dismiss(animated: true, completion: nil)
        }
    }
    
    /*
     
    @IBAction func addPlayerAction(_ sender: Any) {
        playView.isHidden = true
    //    updateBase(ref: &baseRef)
        getOnline()
    //  searchPlayer()
        updateUser(player: &myUser, id: idSecondPlayer ){ pl in
            self.secondUser = pl
            self.secondPlayerLabel.text = "\(self.secondUser.name) \(self.secondUser.latitude) \(self.secondUser.longitude)"
            self.getPlayer(){ locations in
                let distance = (CLLocation(latitude: locations.latitude, longitude: locations.longitude).distance(from: (self.locationManager.location)!) / 1000).rounded()
                self.distanceLabel.text = "\(distance)km"
                let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: (self.myUser.latitude + self.secondUser.latitude)/2, longitude: (self.myUser.longitude + self.secondUser.longitude)/2), latitudinalMeters: distance*1000 + 1000000, longitudinalMeters: distance*1000 + 1000000)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
         let polylineRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
         polylineRenderer.strokeColor = UIColor.black
         polylineRenderer.lineWidth = 4.0
         return polylineRenderer
       }
  
     */
     
extension ViewController: CLLocationManagerDelegate{
 
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("!!!!!!!!!!!!!\(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      setupGame()
        /*
        if let location = locations.last?.coordinate{
            let region = MKCoordinateRegion(center: location, latitudinalMeters: 50000, longitudinalMeters: 50000)
           mapView.setRegion(region, animated: true)
        }
         */
    }
    
}


