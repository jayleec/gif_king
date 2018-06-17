//
//  ViewController.swift
//  gif king
//
//  Created by Jae Kyung Lee on 19/05/2018.
//  Copyright © 2018 Jae Kyung Lee. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import ARVideoKit
import SwiftGifOrigin
import RxSwift
import GiphyCoreSDK

class MainViewController: UIViewController, ARSCNViewDelegate, RenderARDelegate, RecordARDelegate {
    
    // MARK: Constans
    
    private struct Constants {
        
        static let MaxGifNumber = 100
        static let GifBorder: CGFloat = 20
        static let Center = SCNVector3(x: 0, y: 0, z: 0)
        static let FirstPosition = SCNVector3(x: -1, y: 3, z: 0.95)
        static let SecondPositon = SCNVector3(x: 3, y: 3, z: 0.95)
        static let ThirdPosition = SCNVector3(x: 3, y: -1, z: 0.95)
        static let FourthPosition = SCNVector3(x: -1, y: -1, z: 0.95)
    }

    
    // MARK: IBOutlet
    
    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var recordingBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    // MARK: Properties
    
    let scene = SCNScene()
    let recordingQueue = DispatchQueue(label: "recording", attributes: .concurrent)
    
    var isRecording = false
    var recorder: RecordAR?

    ////////////////////////////////////////////////////////////////////////
    /*  26, May
     recorder buffer size 1000 * 1000 fixed  -> TODO: Test other iphones..
     */
    ////////////////////////////////////////////////////////////////////////
    
    var gifController: GifInteraction?
    
    let disposeBag = DisposeBag()
    
    var gifVariable = Variable<[GIFData]>([])
    
    var gifSubject = PublishSubject<GIFData>()
    var gifs: Observable<GIFData> {
        return gifSubject.asObserver()
    }
    
    var expanded = false
    var stickerViewOriginalFrame: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupCamera()
        initRecorder()
        updateGifNode()   
    }

    // MARK: Life Cycles
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if recorder?.status == .recording {
            recorder?.stopAndExport()
        }
        
        recorder?.onlyRenderWhileRecording = true
        recorder?.rest()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("memory warning")
    }
    
    // MARK: IBActions
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        gifController?.didPan(sender)
    }
    
    @IBAction func didPinch(_ sender: UIPinchGestureRecognizer) {
        gifController?.didPinch(sender)
    }
    
    @IBAction func recordBtnPressed(_ sender: Any) {
        
        if !isRecording {
            isRecording = true
            gifController?.removeCurrentSelectedObject()
            
            print("start Recording")
            self.recordingBtn.setTitle("Recording", for: .normal)
            if recorder?.status == .readyToRecord {
                recordingQueue.async {
                    self.recorder?.record()
                }
            }
        }
        else {
            isRecording = false
            self.recordingBtn.setTitle("Start", for: .normal)
            if recorder?.status == .recording {
                recorder?.stop() { path in
                    self.recorder?.export(video: path, { (saved, status) in
                        DispatchQueue.main.async {
                            print("SAVE finished")
                            // TODO: Show preview
                            let alert = UIAlertController(title: "Video Saved", message: "Your video saved", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alert, animated: true)
                        }
                    })
                    
                }
            }
            
        }
        
    }
    
    @IBAction func removeAllBtnPressed(_ sender: Any) {
        scnView.scene?.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        
    }
    
    @IBAction func unwindToVC1(segue:UIStoryboardSegue) { }

    
    // MARK: Settings
    
    func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    func initRecorder() {
        // Recorder
        recorder = RecordAR(SceneKit: scnView)
        recorder?.delegate = self
        recorder?.renderAR = self
        recorder?.onlyRenderWhileRecording = false
        // recorder mode - aspectFit
        recorder?.contentMode = .aspectFit
        recorder?.enableAdjsutEnvironmentLighting = true
        recorder?.inputViewOrientations = [.portrait]
        recorder?.deleteCacheWhenExported = false
    }
    
    func setupScene() {
        // init gif interaction
        gifController = GifInteraction(sceneView: scnView)
        scnView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height/2)
        containerView.frame = CGRect(x: 0.0, y: self.view.bounds.height/2, width: self.view.frame.width, height: self.view.frame.height/2)
        stickerViewOriginalFrame = containerView.frame
        
        
        // background color
        scene.background.contents = UIColor.yellow
        scnView.scene = scene
        scnView.isPlaying = true
    }
    
    // MARK: Helpers
    
    func updateGifNode() {
        gifs
        .subscribe(
                onNext: { [weak self] data in
                    
                    guard let gifController = self?.gifController
                        , let newNode = gifController.addGif(data)
                        , let randomPosition = self?.getRandomPosition(id: data.id)
                        else { return }

                    newNode.position = newNode.convertPosition(randomPosition, from: newNode)
                    
                    self?.scene.rootNode.addChildNode(newNode)
            }
        )
        .disposed(by: disposeBag)
    }
    
    func findRandomPoint(point: SCNVector3) -> SCNVector3 {

        var randomX = Float.random(min: 0, max: 3)
        var randomY = Float.random(min: 0, max: 1.5)
    
        if point.x > 0 {
            randomX *= -1
        }
        if point.y < 0 {
            randomY *= -1
        }
        return SCNVector3(x: point.x + randomX, y: point.y + randomY, z: point.z)
    }
    
    func getRandomPosition(id: Int) -> SCNVector3? {
        var randomPosition: SCNVector3?
        
        let section = id % 4
        
        switch section {
        case 0:
            randomPosition = findRandomPoint(point: Constants.FourthPosition)
            break
        case 1:
            randomPosition = findRandomPoint(point: Constants.FirstPosition)
            break
        case 2:
            randomPosition = findRandomPoint(point: Constants.SecondPositon)
            break
        case 3:
            randomPosition = findRandomPoint(point: Constants.ThirdPosition)
            break
        default:
            print("random position error")
            return nil
        }
        
        return randomPosition
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showModal" {
            let modalViewController = segue.destination as? ModalViewController
            modalViewController?.delegate = self
            
        }
        
    }
}


