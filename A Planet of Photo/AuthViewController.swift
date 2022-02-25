//
//  AuthViewController.swift
//  A Planet of Photo
//
//  Created by Grekhem on 09.01.2022.
//

import UIKit
import Firebase
import AVFoundation
import FirebaseDatabase

class AuthViewController: UIViewController {
    
    var signUp: Bool = true {
        willSet {
            if newValue {
                titleLabel.text = "Registration"
                nameField.isHidden = false
                loginButton.setTitle("Signup", for: .normal)
            } else {
                titleLabel.text = "Signup"
                nameField.isHidden = true
                loginButton.setTitle("Registration", for: .normal)
            }
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        nameField.delegate = self
        passwordField.delegate = self
        emailField.delegate = self
     
    }
    
    @IBAction func switchLogin(_ sender: UIButton) {
        signUp = !signUp
    }
    
    func showAlert(){
        let alert = UIAlertController(title: "Error", message: "Not all data entered", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}

extension AuthViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let name = nameField.text!
        let password = passwordField.text!
        let email = emailField.text!
        
        if (signUp){
            if (!name.isEmpty && !password.isEmpty && !email.isEmpty){
                Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                    if error == nil {
                        if let result = result {
                            let ref = Database.database(url: "https://a-planet-of-photo-default-rtdb.europe-west1.firebasedatabase.app").reference().child("users")
                            ref.child(result.user.uid).updateChildValues(["name" : name, "email" : email, "latitude" : 0.0, "longitude" : 0.0, "isOnline" : true, "uid" : Auth.auth().currentUser?.uid, "imageUrl" : "", "isWantPlay" : false, "message" : "", "secondPlayer" : ""])
                            self.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        print(error!)
                    }
                }
            } else {
                showAlert()
            }
        } else {
            if (!password.isEmpty && !email.isEmpty){
                Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                    if error == nil {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            } else {
                showAlert()
            }
        }
        return true
    }
}
