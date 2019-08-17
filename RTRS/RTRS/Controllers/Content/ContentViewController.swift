//
//  ContentViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/18/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController {
    
    @IBOutlet weak var podView: UIView!
    @IBOutlet weak var cornerView: UIView!
    @IBOutlet weak var explanationView: UIView!
    
    fileprivate let auCornerSegueId = "AU's Corner"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let transitionCoordinator = RTRSTransittionCoordinator()
        self.navigationController?.delegate = transitionCoordinator
        
        // Draw borders for "THE POD" and "AU'S CORNER"
        
        //AU'S CORNER:
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openAuCorner))
        gestureRecognizer.numberOfTapsRequired = 1
        self.cornerView.addGestureRecognizer(gestureRecognizer)
        
        
        // THE POD:
        
        
    }
    
    @objc fileprivate func openAuCorner() {
        self.navigationController?.navigationBar.isHidden = false
        self.performSegue(withIdentifier: self.auCornerSegueId, sender: nil)
    }

}
