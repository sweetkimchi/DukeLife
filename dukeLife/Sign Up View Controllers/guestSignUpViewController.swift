//
//  guestSignUpViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/23/20.
//

import UIKit
import Firebase
import FirebaseAuth

class guestSignUpViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {
    
    var validSignIn = false;
    var loggedInUserName = "";
    var uid = "";
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var Password_guest: UITextField!
    @IBOutlet weak var Confirm_Password_guest: UITextField!

    @IBAction func goToLogin(_ sender: Any) {
        self.performSegue(withIdentifier: "account", sender: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.Confirm_Password_guest.delegate = self
        self.Password_guest.delegate = self
        self.firstName.delegate = self
        self.lastName.delegate = self
        self.email.delegate = self
        NotificationCenter.default.addObserver(self,selector: #selector(self.keyboardDidShow(notification:)),
            name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(self.keyboardDidHide(notification:)),
            name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "login" {
            if !self.validSignIn  {
                return false
            }
            return true
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "login") {
            let tabBarC : UITabBarController = segue.destination as! UITabBarController
            let mapView = tabBarC.viewControllers?.first as! guestMapViewController
            let profView = tabBarC.viewControllers?.last as! guestProfileViewController
            mapView.currentUserId = self.uid
            mapView.currentUsername = self.loggedInUserName
            profView.currentUserId = self.uid
            profView.currentUsername = self.loggedInUserName
        }
    }
    
    @IBAction func SignUp_Button_guest(_ sender: Any) {
        if email.text?.isEmpty == true {
            showAlert(message: "Please enter a valid email.")
            return
        }
        if firstName.text?.isEmpty == true {
            showAlert(message: "Please enter your first name.")
            return
        }
        if lastName.text?.isEmpty == true {
            return
        }
        if Password_guest.text?.isEmpty == true {
            showAlert(message: "Please enter a password.")
            return
        }
        if Confirm_Password_guest.text?.isEmpty == true {
            showAlert(message: "Please confirm your password.")
            return
        }
        if Password_guest.text != Confirm_Password_guest.text {
            showAlert(message: "Your passwords do not match. Please re-enter it.")
            return
        }
        
        Auth.auth().createUser(withEmail: email.text!, password: Password_guest.text!) { authResult, error in
                guard let user = authResult?.user, error == nil else {
                    self.showAlert(message: error!.localizedDescription)
                    return
                }
                let db = Firestore.firestore()
                self.uid = user.uid
                self.loggedInUserName = self.firstName.text! + " " + self.lastName.text!
                let email = user.email!
                db.collection("guests").document(user.uid).setData([
                    "name": self.firstName.text! + " " + self.lastName.text!,
                    "email": email
                ]) { err in
                    if let err = err {
                        self.showAlert(message: "There seemed to be an error retrieving your login information. Please try again.")
                        return
                    } else {
                        self.validSignIn = true;
                        self.performSegue(withIdentifier: "login", sender: nil)
                    }
                }
            }
    }
    
    func showAlert(message: String){
        let alert = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    //MARK: Methods to manage keybaord
    @objc func keyboardDidShow(notification: NSNotification) {
        let info = notification.userInfo
        let keyBoardSize = info![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        scrollView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyBoardSize.height, right: 0.0)
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyBoardSize.height, right: 0.0)
    }

    @objc func keyboardDidHide(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
}
