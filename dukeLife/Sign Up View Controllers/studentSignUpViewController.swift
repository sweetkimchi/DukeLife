//
//  studentSignUpViewController.swift
//  dukeLife
//
//  Created by Abby Mapes on 10/23/20.
//

import UIKit
import Firebase
import FirebaseAuth

class studentSignUpViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {
    var window: UIWindow?
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var Duke_Email: UITextField!
    @IBOutlet weak var netID: UITextField!
    @IBOutlet weak var Password_stud: UITextField!
    @IBOutlet weak var Confirm_Password_Stud: UITextField!
    
    var validSignIn = false;
    var loggedInUserName = "";
    var uid = "";
    
    @IBAction func goToLogin(_ sender: Any) {
        self.performSegue(withIdentifier: "account", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.Confirm_Password_Stud.delegate = self
        self.Password_stud.delegate = self
        self.netID.delegate = self
        self.Duke_Email.delegate = self

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
        if segue.identifier == "login" {
            let tabBarC : UITabBarController = segue.destination as! UITabBarController
            let mapView = tabBarC.viewControllers?.first as! studentMapViewController
            let profView = tabBarC.viewControllers?.last as! studentProfileViewController
            mapView.currentUserId = self.uid
            mapView.currentUsername = self.loggedInUserName
            
            profView.currentUserId = self.uid
            profView.currentUsername = self.loggedInUserName
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func SignUp_Button_stud(_ sender: Any) {
        if Duke_Email.text?.isEmpty == true{
            showAlert(message: "Please enter a valid Duke email, ending in 'duke.edu'.")
            return
        }
        if netID.text?.isEmpty == true{
            showAlert(message: "Please enter your NetID.")
            return
        }
        if Password_stud.text?.isEmpty == true{
            showAlert(message: "Please enter a password.")
            return
        }
        if Confirm_Password_Stud.text?.isEmpty == true {
            showAlert(message: "Please confirm your password.")
            return
        }
        if Password_stud.text != Confirm_Password_Stud.text {
            showAlert(message: "Your passwords do not match. Please re-enter them.")
            return
        }
        Auth.auth().createUser(withEmail: Duke_Email.text!, password: Password_stud.text!) { authResult, error in
                guard let user = authResult?.user, error == nil else {
                    self.showAlert(message: error!.localizedDescription)
                    return
                }
                let db = Firestore.firestore()
                self.uid = user.uid
                self.loggedInUserName = self.netID.text!
                let email = user.email!
                db.collection("students").document(user.uid).setData([
                    "netId": self.netID.text!,
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
    
    func showAlert(message:String) {
        let alert = UIAlertController(title: message, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }

}
