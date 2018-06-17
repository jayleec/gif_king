//
//  MainViewControllerDelegates.swift
//  gif king
//
//  Created by Jae Kyung Lee on 30/05/2018.
//  Copyright © 2018 Jae Kyung Lee. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARVideoKit
import ARKit

// MARK: ARVideoKit Delegates

extension MainViewController {
    func frame(didRender buffer: CVPixelBuffer, with time: CMTime, using rawBuffer: CVPixelBuffer) {
        // Do some image/video processing.
    }
    
    func recorder(didEndRecording path: URL, with noError: Bool) {
        if noError {
            // Do something with the video path.
        }
    }
    
    func recorder(didFailRecording error: Error?, and status: String) {
        // Inform user an error occurred while recording.
    }
    
    func recorder(willEnterBackground status: RecordARStatus) {
        // Use this method to pause or stop video recording. Check [applicationWillResignActive(_:)](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622950-applicationwillresignactive) for more information.
        if status == .recording {
            recorder?.stopAndExport()
        }
    }
}
 

// MARK: ImagePickerController Delegate

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func usePicture() {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a source", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action: UIAlertAction) in
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (action: UIAlertAction) in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let previewContoller = self.storyboard!.instantiateViewController(withIdentifier: "preview") as! PreviewViewController
        previewContoller.image = image
        previewContoller.delegate = self
        
        navigationController?.pushViewController(previewContoller, animated: true)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


// MARK: PreviewController Delegate

extension MainViewController: PreviewViewControllerDelegate {
    func getNewImage(image: UIImage?) {
        
        guard let image = image
            , let id = gifController?.getCurrentNodeNumber()
            , let gif = gifController?.addGif(GIFData(image: image, id: id)) else { return }
        
        scene.rootNode.addChildNode(gif)
    }
}

extension MainViewController: ModalViewControllerDelegate {
    
    func addGif(url: String) {
        guard let id = gifController?.getCurrentNodeNumber() else {
            print("cannot get current node number")
            return
        }
        gifSubject.onNext(GIFData(url: url, id: id ))
    }
    
    func pickPicture() {
        usePicture()
    }
    
    func expandContainerView() {
        
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: { () -> Void in
            
            self.containerView.frame = self.view.frame
            
        }, completion: { (isFinished) in
            
        })
    }
    
    func closeExpandedView() {
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: { () -> Void in
            
            guard let originalSize = self.stickerViewOriginalFrame else {
                print("cannot call sticker view original size")
                return
            }
            self.containerView.frame = originalSize
            
        }, completion: { (isFinished) in
            
        })
        
    }
    
}

