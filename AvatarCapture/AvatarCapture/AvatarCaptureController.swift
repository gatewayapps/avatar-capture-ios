//
//  AvatarCaptureController.swift
//  Tourre
//
//  Created by John Murphy on 3/28/18.
//  Copyright © 2018 Eye-Fi. All rights reserved.
//

import UIKit
import QuartzCore
import AVFoundation

protocol AvatarCaptureControllerDelegate: NSObjectProtocol {
    func imageSelected(image: UIImage)
    func imageSelectionCancelled()
}

class AvatarCaptureController: UIViewController {
    @IBOutlet weak var apertureView: UIView!
    
    var delegate: AvatarCaptureControllerDelegate?
    var presentPickerImmediately = false
    
    var image: UIImage?
    var isCapturing: Bool = false
    
    var captureView: UIView?
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var captureDevice: AVCaptureDevice?
    var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    var isCapturingImage: Bool?
    var capturedImageView: UIImageView?
    var picker: UIImagePickerController?
    var selectedImage: UIImage?
    var cancelButton: UIButton?
    var selectPhotoButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isCapturing {
            self.startCapture(presentPickerImmediately)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        apertureView.layer.cornerRadius = apertureView.bounds.width / 2
        capturedImageView?.layer.cornerRadius = apertureView.bounds.width / 2
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func startCapture(_ withLibraryPicker: Bool = false) {
        if isCapturing {
            return
        }
        
        isCapturing = true
        for subView in apertureView.subviews {
            subView.removeFromSuperview()
        }
        
        captureView = UIView()
        captureView?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureView!)
        captureView?.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        captureView?.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        captureView?.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        captureView?.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        
        let shadeView = UIView()
        shadeView.translatesAutoresizingMaskIntoConstraints = false
        shadeView.alpha = 0.85
        shadeView.backgroundColor = UIColor.black
        captureView?.addSubview(shadeView)
        shadeView.leadingAnchor.constraint(equalTo: captureView!.leadingAnchor, constant: 0).isActive = true
        shadeView.topAnchor.constraint(equalTo: captureView!.topAnchor, constant: 0).isActive = true
        shadeView.trailingAnchor.constraint(equalTo: captureView!.trailingAnchor, constant: 0).isActive = true
        shadeView.bottomAnchor.constraint(equalTo: captureView!.bottomAnchor, constant: 0).isActive = true
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        capturedImageView = UIImageView()
        capturedImageView?.translatesAutoresizingMaskIntoConstraints = false
        capturedImageView?.layer.masksToBounds = true
        capturedImageView?.backgroundColor = UIColor.clear
        capturedImageView?.isUserInteractionEnabled = true
        capturedImageView?.contentMode = .scaleAspectFill
        capturedImageView?.isHidden = true
        captureView?.addSubview(capturedImageView!)
        capturedImageView?.leadingAnchor.constraint(equalTo: apertureView.leadingAnchor).isActive = true
        capturedImageView?.topAnchor.constraint(equalTo: apertureView.topAnchor).isActive = true
        capturedImageView?.trailingAnchor.constraint(equalTo: apertureView.trailingAnchor).isActive = true
        capturedImageView?.bottomAnchor.constraint(equalTo: apertureView.bottomAnchor).isActive = true
        
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        captureVideoPreviewLayer?.videoGravity = .resizeAspectFill
        captureVideoPreviewLayer?.frame = apertureView.frame
        captureVideoPreviewLayer?.cornerRadius = (captureVideoPreviewLayer?.frame.width)! / 2
        
        if !withLibraryPicker {
            captureView?.layer.addSublayer(captureVideoPreviewLayer!)
        }
        else {
            DispatchQueue.main.async {
                self.showImagePicker()
            }
        }
        
        // shutter button
        let shutterButton = UIButton()
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.setImage(UIImage.init(named: "take-snap.png"), for: .normal)
        shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        shutterButton.tintColor = UIColor.blue
        shutterButton.layer.cornerRadius = 20
        captureView?.addSubview(shutterButton)
        shutterButton.widthAnchor.constraint(equalToConstant: 100)
        shutterButton.heightAnchor.constraint(equalToConstant: 100)
        shutterButton.centerXAnchor.constraint(equalTo: captureView!.centerXAnchor, constant: 0).isActive = true
        shutterButton.bottomAnchor.constraint(equalTo: captureView!.bottomAnchor, constant: -40).isActive = true
        
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
                
                // render swap camera
                let swapCamerasButton = UIButton()
                swapCamerasButton.translatesAutoresizingMaskIntoConstraints = false
                swapCamerasButton.setImage(UIImage.init(named: "front-camera.png"), for: .normal)
                swapCamerasButton.addTarget(self, action: #selector(swapCameras), for: .touchUpInside)
                captureView?.addSubview(swapCamerasButton)
                swapCamerasButton.widthAnchor.constraint(equalToConstant: 47).isActive = true
                swapCamerasButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
                swapCamerasButton.centerXAnchor.constraint(equalTo: captureView!.leadingAnchor, constant: 40).isActive = true
                swapCamerasButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor, constant: 0).isActive = true
            }
            else {
                shutterButton.isHidden = true;
            }
        }
        
        // library picker button
        let showImagePickerButton = UIButton()
        showImagePickerButton.translatesAutoresizingMaskIntoConstraints = false
        showImagePickerButton.setImage(UIImage.init(named: "library.png"), for: .normal)
        showImagePickerButton.addTarget(self, action: #selector(showImagePicker), for: .touchUpInside)
        captureView?.addSubview(showImagePickerButton)
        showImagePickerButton.widthAnchor.constraint(equalToConstant: 27).isActive = true
        showImagePickerButton.heightAnchor.constraint(equalToConstant: 27).isActive = true
        showImagePickerButton.centerXAnchor.constraint(equalTo: captureView!.trailingAnchor, constant: -40).isActive = true
        showImagePickerButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor, constant: 0).isActive = true
        
        // cancel button
        cancelButton = UIButton()
        cancelButton?.translatesAutoresizingMaskIntoConstraints = false
        cancelButton?.setImage(UIImage.init(named: "cancel.png"), for: .normal)
        cancelButton?.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        cancelButton?.isHidden = withLibraryPicker
        captureView?.addSubview(cancelButton!)
        cancelButton?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        cancelButton?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        cancelButton?.trailingAnchor.constraint(equalTo: apertureView.trailingAnchor).isActive = true
        cancelButton?.topAnchor.constraint(equalTo: apertureView.bottomAnchor).isActive = true
        
        selectPhotoButton = UIButton()
        selectPhotoButton?.translatesAutoresizingMaskIntoConstraints = false
        selectPhotoButton?.setImage(UIImage.init(named: "selected.png"), for: .normal)
        selectPhotoButton?.addTarget(self, action: #selector(photoSelected), for: .touchUpInside)
        selectPhotoButton?.isHidden = true
        captureView?.addSubview(selectPhotoButton!)
        selectPhotoButton?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        selectPhotoButton?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        selectPhotoButton?.leadingAnchor.constraint(equalTo: apertureView.leadingAnchor).isActive = true
        selectPhotoButton?.centerYAnchor.constraint(equalTo: cancelButton!.centerYAnchor).isActive = true
        
        captureSession?.startRunning()
        
        UIApplication.shared.setStatusBarHidden(true, with: .slide)
    }
    
    func endCapture() {
        captureSession?.stopRunning()
        UIApplication.shared.setStatusBarHidden(false, with: .slide)
        captureVideoPreviewLayer?.removeFromSuperlayer()
        for subview in (captureView?.subviews)! {
            subview.removeFromSuperview()
        }
        captureView?.removeFromSuperview()
        isCapturing = false
    }
    
    @objc func swapCameras() {
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
    
    @objc func showImagePicker() {
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
    
    @objc func cancel() {
        if capturedImageView?.isHidden ?? true {
            endCapture()
            delegate?.imageSelectionCancelled()
        }
        else {
            for view in (captureView?.subviews)! {
                if let button = view as? UIButton {
                    button.isHidden = false
                }
            }
            captureView?.layer.addSublayer(captureVideoPreviewLayer!)
            capturedImageView?.isHidden = true
            selectPhotoButton?.isHidden = true
        }
    }
}

extension AvatarCaptureController: UINavigationControllerDelegate {
    
}

extension AvatarCaptureController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if captureVideoPreviewLayer?.superlayer == nil {
            captureView?.layer.addSublayer(captureVideoPreviewLayer!)
            cancelButton?.isHidden = false
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.capturedImageView?.image = selectedImage
        dismiss(animated: true, completion: {() -> Void in
            for view in (self.captureView?.subviews)! {
                if let button = view as? UIButton {
                    if button != self.cancelButton {
                        button.isHidden = true
                    }
                }
            }
            
            self.captureVideoPreviewLayer?.removeFromSuperlayer()
            self.capturedImageView?.isHidden = false
            self.selectPhotoButton?.isHidden = false
        })
    }
}

extension AvatarCaptureController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var imageData = photo.fileDataRepresentation()
        let isFrontFacing = captureDevice == AVCaptureDevice.devices(for: .video)[1]
        
        var capturedImage = UIImage.init(data: imageData!, scale:1)
        
        if isFrontFacing {
            capturedImage = UIImage.init(cgImage: (capturedImage?.cgImage!)!, scale: (capturedImage?.scale)!, orientation: UIImageOrientation.leftMirrored)
        }
        
        isCapturingImage = false
        capturedImageView?.image = capturedImage
        for view in (captureView?.subviews)! {
            if let button = view as? UIButton {
                if button != self.cancelButton {
                    button.isHidden = true
                }
            }
        }
        
        captureVideoPreviewLayer?.removeFromSuperlayer()
        capturedImageView?.isHidden = false
        selectPhotoButton?.isHidden = false
        
        selectedImage = capturedImage
        imageData = nil
    }
}

