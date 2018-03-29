//
//  MainViewController.swift
//  AvatarCapture
//
//  Created by John Murphy on 3/28/18.
//  Copyright © 2018 John Murphy. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet var avatarView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let avatarCaptureController = AvatarCaptureController()
        avatarCaptureController.delegate = self
        avatarCaptureController.image = UIImage.init(named: "chin.png")
        avatarView.addSubview((avatarCaptureController.view)!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MainViewController: AvatarCaptureControllerDelegate {
    func imageSelected(image: UIImage) {
        print("image Selected")
    }
    
    func imageSelectionCancelled() {
        print("image selection cancelled")
    }
}
