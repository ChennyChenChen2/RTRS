//
//  RTRSAboutViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 8/17/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit

class RTRSAboutViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    fileprivate var viewModel: RTRSAboutViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = RTRSNavigation.shared.viewModel(for: .about) as? RTRSAboutViewModel
        self.textView.attributedText = self.viewModel?.body ?? NSAttributedString(string: "")
        self.imageView.pin_setImage(from: viewModel?.imageUrl)
        
        self.textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
        
        self.navigationController?.navigationBar.tintColor = .white
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
