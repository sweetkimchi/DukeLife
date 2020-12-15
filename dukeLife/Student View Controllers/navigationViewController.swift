//
//  navigationViewController.swift
//  dukeLife
//
//  Created by Isabella Geraci on 11/9/20.
//

import UIKit

class navigationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let myViewController = self.storyboard?.instantiateViewController(withIdentifier: "studentImageCollectionViewController") as? studentImageCollectionViewController{
            self.navigationController?.pushViewController(myViewController, animated: true)
            }
    }
}
