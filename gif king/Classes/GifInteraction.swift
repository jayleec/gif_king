//
//  GifInteraction.swift
//  gif king
//
//  Created by Jae Kyung Lee on 20/05/2018.
//  Copyright © 2018 Jae Kyung Lee. All rights reserved.
//

import UIKit
import SceneKit

class GifInteraction: NSObject, UIGestureRecognizerDelegate {
    
    private struct Constants {
        static let FrontDepth: Float = 0.95
        static let NormalDepth: Float = 0
        static let ButtonDepth: Float = 0.94
    }
    
    let sceneView: SCNView
    
    var isSelected: Bool {
        if selectedObject != nil {
            return true
        }else {
            return false
        }
    }

    var selectedObject: SCNNode?
    
    var zDepth: Float = 0
    
    private var nodeCount = 1
    
    /// The tracked screen position used to update the `trackedObject`'s position in `updateObjectToCurrentTrackingPosition()`.
    private var currentTrackingPosition: CGPoint?
    
    init(sceneView: SCNView) {
        self.sceneView = sceneView
        super.init()
        
        let panning = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panning.delegate = self
        sceneView.addGestureRecognizer(panning)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        sceneView.addGestureRecognizer(tap)
        
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        sceneView.addGestureRecognizer(rotate)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(pinch)
    }
    
    // MARK: - Gesture Actions
    
    @objc
    func didPan(_ gesture: UIPanGestureRecognizer) {
        
        let location = gesture.location(in: sceneView)
        if isSelected {
            
            guard let obj = selectedObject else {
                return
            }
            
            zDepth = sceneView.projectPoint(obj.position).z
            move(node: obj, location: location)
        }
        
    }

  
    @objc
    func didTap(_ gesture: UITapGestureRecognizer) {
        
        let location = gesture.location(in: sceneView)
        let result = sceneView.hitTest(location, options: [:])
        if !result.isEmpty {
            let hit = result.first!
    
            if isSelected && hit.node.name == "button" {
                
                hit.node.parent?.removeFromParentNode()
            }
            else {
                removeCurrentObj()
                
                guard let newObj = hit.node.parent else { return }
                chooseObj(obj: newObj)
            }
            
        }else {
            removeCurrentObj()
        }
    }
    
    @objc
    func didPinch(_ gesture: UIPinchGestureRecognizer) {
        
        let scale = gesture.scale
        
        if isSelected {

            guard let obj = selectedObject else {
                return
            }
            
            if gesture.state == .began {
                
            }
            
            if gesture.state == .changed {
                zDepth = sceneView.projectPoint(obj.position).z
                pinch(node: obj, scale: scale)
            }
            
            if gesture.state == .ended {
                gesture.scale = 1
            }
        }
    }
    
    @objc
    func didRotate(_ gesture: UIRotationGestureRecognizer) {
        
        let rotate = Float(gesture.rotation)
        
        if isSelected {
            guard let obj = selectedObject else { return }
            
            if gesture.state == .changed {
                //TODO: rotation pivot move to center???????
                obj.rotation = SCNVector4Make(0, 0, -1, rotate)
            }
        }
    }

    // MARK: Helpers
    
    func move(node: SCNNode, location: CGPoint) {
        node.position = sceneView.unprojectPoint(
            SCNVector3(x: Float(location.x),
                       y: Float(location.y),
                       z: zDepth))
    }
    
    func pinch(node: SCNNode, scale: CGFloat) {
        
        let updatedNode = node.childNode(withName: "gif", recursively: false)
        updatedNode?.scale = SCNVector3(x: Float(scale), y: Float(scale), z: zDepth)
    }
    
    
    func removeCurrentObj() {
        guard let obj = selectedObject else {
            return
        }
        
        let gif = obj.childNode(withName: "gif", recursively: false)
        let button = obj.childNode(withName: "button", recursively: false)
        
        if isSelected {
            
            selectedObject?.position.z = Constants.NormalDepth
        
            guard let geo = gif?.geometry else {
                return
            }
            
            let layer: CALayer = geo.firstMaterial?.diffuse.contents as! CALayer
            layer.masksToBounds = false
            layer.borderWidth = 0
            
            button?.isHidden = true
            
            selectedObject = nil
        }
    }
    
    // MARK: set selected gif border and show button
    func chooseObj(obj: SCNNode) {
        
        let gif = obj.childNode(withName: "gif", recursively: false)
        let button = obj.childNode(withName: "button", recursively: false)
        
        guard let geo = gif?.geometry else {
            return
        }
        
        if geo.name == "image" {
            // border
            let layer: CALayer = geo.firstMaterial?.diffuse.contents as! CALayer
            layer.masksToBounds = true
            layer.borderWidth = 20
            layer.borderColor = UIColor.orange.cgColor

            
            //bring the object front
            obj.position.z = Constants.FrontDepth
            
            // show button
            button?.isHidden = false
            
        } else {
            removeCurrentObj()
        }
        
        self.selectedObject = obj
    }
    
    
    func addGif(_ data: GIFData) -> SCNNode? {
        
        var gif: UIImage?
        
        switch data.type {
        case .image:
            
            guard let image = data.image else {
                return nil
            }
            gif = image
            break
            
        case .gif:
            guard let url = data.url else { return nil }
            gif = UIImage.gif(url: url)
            break
        }
        
        let parentNode = SCNNode()
        parentNode.name = String(data.id)
        
        let imageView = UIImageView(image: gif)
        
        var ratio: CGFloat = 1
        if let width = gif?.size.width, let height = gif?.size.height {
            ratio = width / height
        }
        
        let plainWidth: CGFloat = 3.0 * ratio
        let plainHeight: CGFloat = 3.0
        
        let plain = SCNPlane(width: plainWidth , height: plainHeight)
        
        plain.firstMaterial?.diffuse.contents = imageView.layer
        plain.name = "image"
        
        let geometry: SCNGeometry
        geometry = plain
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.name = "gif"
        
        // move Pivot point to the right corner
        geometryNode.pivot = SCNMatrix4MakeTranslation(Float(plainWidth/2), Float(plainHeight/2), 0)
        parentNode.addChildNode(geometryNode)
        
        let button = SCNPlane(width: 1.0, height: 1.0)
        button.firstMaterial?.diffuse.contents = UIColor.red
        
        let buttonGeometry: SCNGeometry
        buttonGeometry = button
        let buttonNode = SCNNode(geometry: buttonGeometry)
        buttonNode.name = "button"
        let parentPosition = parentNode.position
        buttonNode.position = buttonNode.convertPosition( SCNVector3(x: parentPosition.x + Float(plainWidth)/2, y: parentPosition.y + Float(plainHeight)/2, z: Constants.ButtonDepth), from: geometryNode)
        parentNode.addChildNode(buttonNode)
        
        removeCurrentSelectedObject()
        
        chooseObj(obj: parentNode)
        
        nodeCount += 1

        return parentNode
        
    }
    
    func deleteSingleNode() {
        
    }
    
    func getRandom() -> Float {
        let max: UInt32 = 2
        return Float(arc4random_uniform(max))
    }
    
    func removeCurrentSelectedObject() {
        // remove current selected object
        if selectedObject != nil {
            removeCurrentObj()
        }
    }
    
    func getCurrentNodeNumber() -> Int {
        return nodeCount
    }
    
}
