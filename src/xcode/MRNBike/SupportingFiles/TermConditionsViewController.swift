//
//  TermConditionsViewController.swift
//  MRNBike
//
//  Created by 1 on 24.05.17.
//  Copyright © 2017 Marc Bormeth. All rights reserved.
//

import UIKit

class TermConditionsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func closeTerm(_ sender: Any) {
        
        let termAlert = UIAlertController(title: "Alert", message: "Message", preferredStyle: .alert)
        termAlert.title = "Dismiss conformation"
        termAlert.message = "If you disagree with term conditions, you can't continue work with the App and your current progress will be lost. Are you sure about this?"
        termAlert.addAction(UIAlertAction(title: "No", style: .default, handler: {action in
            return
        }))
        termAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: {action in
            let storyboard = UIStoryboard(name: "StartPage", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "StartPage")
            self.present(controller, animated: true, completion: nil)
        }))
        self.present(termAlert, animated: true, completion: nil)
        return
      
    }


    @IBAction func AgreeButton(_ sender: Any) {
    self.close()
    }


}