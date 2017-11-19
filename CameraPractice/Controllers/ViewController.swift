//
//  ViewController.swift
//  CameraPractice
//
//  Created by Christopher Smith on 11/18/17.
//  Copyright © 2017 Christopher Smith. All rights reserved.
//

import UIKit
import AVKit
// import CoreML
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: Properties
    
    var captureSession: AVCaptureSession?
    
    // MARK: IBOutlets
    
    @IBOutlet weak var displayLabel: UILabel!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCaptureSession()
        self.setupPreviewLayer()
    }
    
    // MARK: - Convenience Methods
    
    func setupCaptureSession() {
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard
            let captureDevice = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: captureDevice) else {
                return
        }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        self.captureSession = captureSession
    }
    
    func setupPreviewLayer() {
        
        guard let captureSession = self.captureSession else {
            fatalError("Could not retrieve capture session.")
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label:"videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    //    VNImageRequestHandler(cgImage: <#T##CGImage#>, options: [:]).perform(<#T##requests: [VNRequest]##[VNRequest]#>)
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //    print("Camera was able to capture a frame:", Date())
        
        guard
            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let model = try? VNCoreMLModel(for: Resnet50().model) else {
                return
        }
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            //      print(finishedReq.results)
            
            guard
                let results = finishedReq.results as? [VNClassificationObservation],
                let firstObservation = results.first else {
                    return
            }
            
            print(firstObservation.identifier,firstObservation.confidence)
            
            DispatchQueue.main.async { [weak self] in
                self?.displayLabel.text = "\(firstObservation.identifier)"
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
