//
//  ResetPasswordViewController.swift
//  A Planet of Photo
//
//  Created by Grekhem on 11.01.2022.
//

import UIKit
import FirebaseAuth

class ResetPasswordViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    

    @IBAction func resetButtonAction(_ sender: Any) {
        let email = emailTextField.text!
        if (!email.isEmpty) {
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if error == nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}
