//
//  ContentViewController.swift
//  RTRS
//
//  Created by Jonathan Chen on 7/18/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import UIKit
import CoreGraphics

class ContentViewController: UIViewController {
    
    @IBOutlet weak var podView: UIView!
    @IBOutlet weak var cornerView: UIView!
    @IBOutlet weak var explanationView: UIView!
    @IBOutlet weak var normalColumnContainer: UIView!
    
    fileprivate var normalColumnView: NormalColumnView!
    
    fileprivate let mocSegueId = "MOC"
    fileprivate let auCornerSegueId = "AU's Corner"
    fileprivate let podSegueId = "The Pod"
    fileprivate let normalColumnSegueId = "Normal Column"
    
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
        let podGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openPods))
        podGestureRecognizer.numberOfTapsRequired = 1
        self.podView.addGestureRecognizer(podGestureRecognizer)
        
        // NORMAL COLUMN:
        self.normalColumnView = NormalColumnView(frame: self.normalColumnContainer.frame)
        self.normalColumnContainer.addSubview(self.normalColumnView)
        
        self.normalColumnView.translatesAutoresizingMaskIntoConstraints = false
        self.normalColumnView.leftAnchor.constraint(equalTo: self.normalColumnContainer.leftAnchor).isActive = true
        self.normalColumnView.topAnchor.constraint(equalTo: self.normalColumnContainer.topAnchor).isActive = true
        self.normalColumnView.rightAnchor.constraint(equalTo: self.normalColumnContainer.rightAnchor).isActive = true
        self.normalColumnView.bottomAnchor.constraint(equalTo: self.normalColumnContainer.bottomAnchor).isActive = true
            
        // MOC:
        // TODO: apply gesture recognizer once content refresh page is applied
        let mocRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(openMOC))
        mocRecognizer.direction = .left
        self.podView.addGestureRecognizer(mocRecognizer)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self.normalColumnView), let shapeLayer = self.normalColumnView.shapeLayer {
            if let path = shapeLayer.path, path.contains(point) {
                openNormalColumn()
            }
        }
    }
    
    @objc fileprivate func openPods() {
        self.navigationController?.navigationBar.isHidden = false
        self.performSegue(withIdentifier: self.podSegueId, sender: nil)
    }
        
    @objc fileprivate func openMOC() {
        self.navigationController?.navigationBar.isHidden = false
        self.performSegue(withIdentifier: self.mocSegueId, sender: nil)
    }
    
    @objc fileprivate func openAuCorner() {
        self.navigationController?.navigationBar.isHidden = false
        self.performSegue(withIdentifier: self.auCornerSegueId, sender: nil)
    }
    
    @objc fileprivate func openNormalColumn() {
        self.navigationController?.navigationBar.isHidden = false
        self.performSegue(withIdentifier: self.normalColumnSegueId, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let id = segue.identifier {
            let vc = segue.destination as! ContentTableViewController
            if id == self.auCornerSegueId {
                vc.contentType = .au
            } else if id == self.normalColumnSegueId {
                vc.contentType = .normalColumn
            } else if id == self.mocSegueId {
                vc.contentType = .moc
            } else {
                vc.contentType = .podcasts
            }
        }
    }
}

fileprivate class NormalColumnView: UIView {
    
    var titleLabel: UILabel
    var shapeLayer: CAShapeLayer?
    var angle: CGFloat?
    
    override init(frame: CGRect) {
        self.titleLabel = UILabel()
        self.titleLabel.font = Utils.defaultFont.withSize(25.0)
        self.titleLabel.text = "SIXERS ADAM: NORMAL COLUMN"
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        self.titleLabel = UILabel()
        self.titleLabel.font = Utils.defaultFont.withSize(25.0)
        self.titleLabel.text = "SIXERS ADAM: NORMAL COLUMN"
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        self.shapeLayer = CAShapeLayer()

        self.shapeLayer?.path = self.createBezierPath(rect).cgPath

        self.shapeLayer?.strokeColor = UIColor.white.cgColor
        self.shapeLayer?.fillColor = UIColor.white.cgColor
        self.shapeLayer?.lineWidth = 1.0

        self.layer.addSublayer(shapeLayer!)
        
        self.addSubview(self.titleLabel)
        self.titleLabel.textColor = .black
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if let angle = self.angle {
            self.titleLabel.transform = CGAffineTransform(rotationAngle: angle)
        }
        
        self.titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    private func createBezierPath(_ frame: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: frame.size.height / 2))
        path.addLine(to: CGPoint(x: frame.size.width, y: 0))
        path.addLine(to: CGPoint(x: frame.size.width, y: frame.size.height / 2))
        path.addLine(to: CGPoint(x: 0, y: frame.size.height))
        path.addLine(to: CGPoint(x: 0, y: frame.size.height / 2))
        
        self.angle = atan2((0 - frame.size.height / 2), (frame.size.width - 0))
        
        path.close()
        
        return path
    }
    
}
