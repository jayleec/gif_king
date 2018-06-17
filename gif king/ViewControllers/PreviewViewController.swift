//
//  LoadImages.swift
//  gif king
//
//  Created by Jae Kyung Lee on 21/05/2018.
//  Copyright © 2018 Jae Kyung Lee. All rights reserved.
//

import UIKit

protocol PreviewViewControllerDelegate: class {
    func getNewImage(image: UIImage?)
}

class PreviewViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage?
    var originalImage: UIImage? // TODO: This one is empty

    var path: UIBezierPath!
    var touchPoint: CGPoint!
    var startPoint: CGPoint!
    
//    var context: CGContext?
    weak var delegate: PreviewViewControllerDelegate?
    let caLayer = CAShapeLayer()
    
    // MARK : View Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = image
        
        caLayer.frame = imageView.frame
        caLayer.fillColor = UIColor.clear.cgColor
        caLayer.strokeColor = UIColor.yellow.cgColor
        caLayer.lineWidth = 10
        self.imageView.layer.addSublayer(caLayer)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("deleted current Image")
    }
    
    // MARK: Touch Event
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            
            startPoint = touch.location(in: view)
            path = UIBezierPath()
            
            path.move(to: startPoint)
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            touchPoint = touch.location(in: view)
        }
        
        path.addLine(to: touchPoint)
        caLayer.path = path.cgPath
        
        startPoint = touchPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchedsEnded")
//        self.context = nil
        caLayer.removeFromSuperlayer()
        cut()
    }
    
    // MARK: IBActions
    
    @IBAction func useButtonPressed(_ sender: Any) {
        self.delegate?.getNewImage(image: originalImage)
        performSegue(withIdentifier: "unwindSegue", sender: self)
    }
    
    // MARK: Helpers
    
    func cut() {
        guard let path = path else {
            return
        }
        imageView = imageView.getCut(with: path)
        self.originalImage = imageView.getCroppedImage(path: path)
    }
}

extension UIImageView {
    func getCut(with bezier: UIBezierPath) -> UIImageView {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bezier.cgPath
        
        self.layer.mask = shapeLayer
        
        return self
    }
    
    func getCroppedImage(path: UIBezierPath) -> UIImage? {
        UIGraphicsBeginImageContext(self.bounds.size)
        let context = UIGraphicsGetCurrentContext()!
        self.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage?.cropping(to: path.bounds) else {
            print("cropping found nil")
            return nil
        }
        let croppedImage = UIImage(cgImage: cgImage)
        return croppedImage
    }
}







