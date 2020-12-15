//
//  guestLogInViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/23/20.
//

import UIKit
import Firebase
import FirebaseAuth

class guestLogInViewController: UIViewController {
    
    var validSignIn = false;
    var loggedInUserName = "";
    var uid = "";
    
    func showAlert(message:String) {
        let alert = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if !self.validSignIn  {
            return false
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let tabBarC : UITabBarController = segue.destination as! UITabBarController
        let mapView = tabBarC.viewControllers?.first as! guestMapViewController
        let profView = tabBarC.viewControllers?.last as! guestProfileViewController
        mapView.currentUserId = self.uid
        mapView.currentUsername = self.loggedInUserName
        profView.currentUserId = self.uid
        profView.currentUsername = self.loggedInUserName
        
    }
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    
    @IBAction func Email(_ sender: UITextField) {
    }
    
    @IBAction func Password(_ sender: UITextField) {
    }
    
    @IBAction func Login_guest(_ sender: Any) {
        if email.text?.isEmpty == true || password.text?.isEmpty == true {
            showAlert(message: "Please enter your email and password.")
            return
        } else {
            Auth.auth().signIn(withEmail: self.email.text!, password: self.password.text!) { (user, error) in
                    if let error = error {
                        self.showAlert(message: error.localizedDescription)
                        return
                    }
                    guard let user = user?.user, error == nil else {
                        self.showAlert(message: error!.localizedDescription)
                        return
                    }
                    let db = Firestore.firestore()
                    self.uid = user.uid
                    db.collection("guests").document(user.uid).getDocument { (document, error) in
                        if let document = document, document.exists {
                            self.loggedInUserName = document.data()?["name"] as! String
                            self.validSignIn = true;
                            self.performSegue(withIdentifier: "login", sender: nil)
                        } else {
                            self.showAlert(message: "There seemed to be an error retrieving your login information. Please try again.")
                            return
                        }
                    }
            }
        }
    }
}
