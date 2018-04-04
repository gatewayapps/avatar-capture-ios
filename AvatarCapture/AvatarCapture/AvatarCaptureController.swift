//
//  AvatarCaptureController.swift
//  AvatarCapture
//
//  Created by John Murphy on 3/28/18.
//  Copyright © 2018 John Murphy. All rights reserved.
//

import UIKit
import QuartzCore
import AVFoundation

public protocol AvatarCaptureControllerDelegate: NSObjectProtocol {
    func imageSelected(image: UIImage)
    func imageSelectionCancelled()
}

open class AvatarCaptureController: UIViewController {
    public var delegate: AvatarCaptureControllerDelegate?
    public var image: UIImage?
    var previousFrame: CGRect?
    var isCapturing: Bool?
    
    var avatarView: UIImageView?
    var captureView: UIView?
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var captureDevice: AVCaptureDevice?
    var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    var isCapturingImage: Bool?
    var capturedImageView: UIImageView?
    var picker: UIImagePickerController?
    var imageSelectedView: UIView?
    var selectedImage: UIImage?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        isCapturing = false
        
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(startCapture))
        view.addGestureRecognizer(singleTapGestureRecognizer)
        avatarView = UIImageView.init(frame: view.frame)
        avatarView?.image = image
        avatarView?.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.RawValue(UInt8(UIViewAutoresizing.flexibleHeight.rawValue) | UInt8(UIViewAutoresizing.flexibleWidth.rawValue)))
        avatarView?.contentMode = .scaleAspectFill
        avatarView?.layer.masksToBounds = true
        avatarView?.layer.cornerRadius = view.bounds.width / 2
        view.addSubview(avatarView!)
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        view.frame = (view.superview?.bounds)!
        view.layer.cornerRadius = view.bounds.width / 2
        avatarView?.layer.cornerRadius = view.bounds.width / 2
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc open func startCapture() {
        if isCapturing! {
            return
        }
        
        isCapturing = true
        for subView in view.subviews {
            subView.removeFromSuperview()
        }
        previousFrame = view.convert(view.frame, to: nil)
        
        captureView = UIView(frame: (view.window?.frame)!)
        view.window?.addSubview(captureView!)
        
        let shadeView = UIView(frame: (captureView?.frame)!)
        shadeView.alpha = 0.85
        shadeView.backgroundColor = UIColor.black
        captureView?.addSubview(shadeView)
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        capturedImageView = UIImageView()
        capturedImageView?.frame = previousFrame!
        capturedImageView?.layer.cornerRadius = (previousFrame?.width)! / 2
        capturedImageView?.layer.masksToBounds = true
        capturedImageView?.backgroundColor = UIColor.clear
        capturedImageView?.isUserInteractionEnabled = true
        capturedImageView?.contentMode = .scaleAspectFill
        
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        captureVideoPreviewLayer?.videoGravity = .resizeAspectFill
        captureVideoPreviewLayer?.frame = previousFrame!
        captureVideoPreviewLayer?.cornerRadius = (captureVideoPreviewLayer?.frame.width)! / 2
        captureView?.layer.addSublayer(captureVideoPreviewLayer!)
        
        let devices = AVCaptureDevice.devices(for: .video)
        if devices.count > 0 {
            captureDevice = devices[0]
            for device in devices {
                if device.position == .front {
                    captureDevice = device
                    break
                }
            }
            
            let input = try? AVCaptureDeviceInput.init(device: captureDevice!)
            
            if let input = input {
                captureSession?.addInput(input)
                
                stillImageOutput = AVCapturePhotoOutput()
                captureSession?.addOutput(stillImageOutput!)
                
                // shutter button
                let shutterButton = UIButton(frame: CGRect(x:(previousFrame?.origin.x)! + ((previousFrame?.width)! / 2)-50,
                                                           y: (view.window?.frame.height)! - 40 - 100,
                                                           width: 100,
                                                           height: 100))
                                
                shutterButton.setImage(UIImage(named: "take-snap.png", in:Bundle(for: self.classForCoder), compatibleWith: nil), for: .normal)
                shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
                shutterButton.tintColor = UIColor.blue
                shutterButton.layer.cornerRadius = 20
                captureView?.addSubview(shutterButton)
                
                // render swap camera
                let swapCamerasButton = UIButton(frame: CGRect(x:view.frame.origin.x + 20,
                                                               y: (view.window?.frame.height)! - 40 - 25,
                                                               width: 47,
                                                               height: 25))
                swapCamerasButton.setImage(UIImage.init(named: "front-camera.png"), for: .normal)
                swapCamerasButton.addTarget(self, action: #selector(swapCameras), for: .touchUpInside)
                captureView?.addSubview(swapCamerasButton)
            }
        }
        
        // library picker button
        let showImagePickerButton = UIButton(frame: CGRect(x:(view.window?.frame.width)! - 40,
                                                           y: (view.window?.frame.height)! - 40 - 27,
                                                           width: 27,
                                                           height: 27))
        showImagePickerButton.setImage(UIImage.init(named: "library.png"), for: .normal)
        showImagePickerButton.addTarget(self, action: #selector(showImagePicker), for: .touchUpInside)
        captureView?.addSubview(showImagePickerButton)
        
        // cancel button
        let cancelButton = UIButton(frame: CGRect(x:view.frame.origin.x + 20,
                                                  y: view.frame.origin.y + 40,
                                                  width: 32,
                                                  height: 32))
        cancelButton.setImage(UIImage.init(named: "cancel.png"), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        captureView?.addSubview(cancelButton)
        
        imageSelectedView = UIView.init(frame: (captureView?.frame)!)
        imageSelectedView?.backgroundColor = UIColor.clear
        imageSelectedView?.addSubview(capturedImageView!)
        
        let overlayView = UIView.init(frame: CGRect(x: 0,
                                                    y: (previousFrame?.origin.y)! + (previousFrame?.height)!,
                                                    width: (captureView?.frame.width)!,
                                                    height: 60))
        imageSelectedView?.addSubview(overlayView)
        
        let selectPhotoButton = UIButton(frame: CGRect(x:(previousFrame?.origin.x)!,
                                                       y: 0,
                                                       width: 32,
                                                       height: 32))
        selectPhotoButton.setImage(UIImage.init(named: "selected.png"), for: .normal)
        selectPhotoButton.addTarget(self, action: #selector(photoSelected), for: .touchUpInside)
        overlayView.addSubview(selectPhotoButton)
        
        let cancelSelectPhotoButton = UIButton(frame: CGRect(x:(previousFrame?.origin.x)! + (previousFrame?.width)! - 32,
                                                             y: 0,
                                                             width: 32,
                                                             height: 32))
        cancelSelectPhotoButton.setImage(UIImage.init(named: "cancel.png"), for: .normal)
        cancelSelectPhotoButton.addTarget(self, action: #selector(cancelSelectedPhoto), for: .touchUpInside)
        overlayView.addSubview(cancelSelectPhotoButton)
        
        captureSession?.startRunning()
        
        UIApplication.shared.setStatusBarHidden(true, with: .slide)
    }
    
    open func endCapture() {
        captureSession?.stopRunning()
        UIApplication.shared.setStatusBarHidden(false, with: .slide)
        captureVideoPreviewLayer?.removeFromSuperlayer()
        for subview in (captureView?.subviews)! {
            subview.removeFromSuperview()
        }
        avatarView = UIImageView.init(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: (previousFrame?.width)!,
                                                    height: (previousFrame?.height)!))
        avatarView?.image = image
        avatarView?.contentMode = .scaleAspectFill
        avatarView?.layer.masksToBounds = true
        avatarView?.layer.cornerRadius = (avatarView?.frame.width)! / 2
        view.addSubview(avatarView!)
        view.layer.cornerRadius = view.frame.width / 2
        captureView?.removeFromSuperview()
        isCapturing = false
    }
    
    @objc open func swapCameras() {
        if isCapturingImage != true {
            if captureDevice == AVCaptureDevice.devices(for: .video)[0] {
                // rear active, switch to front
                captureDevice = AVCaptureDevice.devices(for: .video)[1]
                
                captureSession?.beginConfiguration()
                let newInput = try? AVCaptureDeviceInput (device: captureDevice!)
                for oldInput in (captureSession?.inputs)! {
                    captureSession?.removeInput(oldInput)
                }
                captureSession?.addInput(newInput!)
                captureSession?.commitConfiguration()
            } else if captureDevice == AVCaptureDevice.devices(for: .video)[1] {
                // front active, switch to rear
                captureDevice = AVCaptureDevice.devices(for: .video)[0]
                
                captureSession?.beginConfiguration()
                let newInput = try? AVCaptureDeviceInput (device: captureDevice!)
                for oldInput in (captureSession?.inputs)! {
                    captureSession?.removeInput(oldInput)
                }
                captureSession?.addInput(newInput!)
                captureSession?.commitConfiguration()
            }
        }
    }
    
    @objc func capturePhoto() {
        isCapturingImage = true
        
        let outputSettings = AVCapturePhotoSettings()
        outputSettings.livePhotoVideoCodecType = .jpeg
        
        if let _ = stillImageOutput?.connection(with: .video){
            stillImageOutput?.capturePhoto(with: outputSettings, delegate: self)
        }
    }
    
    @objc open func showImagePicker() {
        picker = UIImagePickerController()
        picker?.sourceType = .photoLibrary
        picker?.delegate = self
        present(picker!, animated: true, completion: nil)
    }
    
    @objc func photoSelected() {
        image = selectedImage!
        endCapture()
        delegate?.imageSelected(image: image!)
    }
    
    @objc func cancelSelectedPhoto() {
        imageSelectedView?.removeFromSuperview()
        for view in (captureView?.subviews)! {
            if view.isKind(of: UIButton.self) {
                view.isHidden = false
            }
        }
    }
    
    @objc func cancel() {
        endCapture()
        delegate?.imageSelectionCancelled()
    }
}

extension AvatarCaptureController: UINavigationControllerDelegate {
    
}

extension AvatarCaptureController: UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.capturedImageView?.image = selectedImage
        
        dismiss(animated: true, completion: {() -> Void in
            for view in (self.captureView?.subviews)! {
                if view.isKind(of: UIButton.self) {
                    view.isHidden = true
                }
            }
            self.captureView?.addSubview(self.imageSelectedView!)
        })
    }
}

extension AvatarCaptureController: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var imageData = photo.fileDataRepresentation()
        let isFrontFacing = captureDevice == AVCaptureDevice.devices(for: .video)[1]
        
        var capturedImage = UIImage.init(data: imageData!, scale:1)
        
        if isFrontFacing {
            capturedImage = UIImage.init(cgImage: (capturedImage?.cgImage!)!, scale: (capturedImage?.scale)!, orientation: UIImageOrientation.leftMirrored)
        }
        
        isCapturingImage = false
        capturedImageView?.image = capturedImage
        for view in (captureView?.subviews)! {
            if view.isKind(of: UIButton.self) {
                view.isHidden = true
            }
        }
        
        captureView?.addSubview(imageSelectedView!)
        selectedImage = capturedImage
        imageData = nil
    }
}

