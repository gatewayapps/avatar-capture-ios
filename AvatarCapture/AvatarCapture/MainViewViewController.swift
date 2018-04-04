//
//  MainViewController.swift
//  AvatarCapture
//
//  Created by John Murphy on 3/28/18.
//  Copyright © 2018 John Murphy. All rights reserved.
//

import UIKit

class MainViewViewController: UIViewController {
    @IBOutlet weak var avatarView: UIView!
    
    var avatarCaptureController = AvatarCaptureController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        avatarCaptureController = AvatarCaptureController()
        avatarCaptureController.delegate = self
        avatarCaptureController.image = UIImage.init(named: "chin.png")
        avatarView.addSubview((avatarCaptureController.view)!)
    }
    
    @IBAction func pressed(_ sender: Any) {
        avatarCaptureController.startCapture()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MainViewViewController: AvatarCaptureControllerDelegate {
    func imageSelected(image: UIImage) {
        print("image Selected")
    }
    
    func imageSelectionCancelled() {
        print("image selection cancelled")
    }
}
