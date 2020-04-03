//  MIT License
//
//  Copyright (c) 2020 Thales DIS
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

// IMPORTANT: This source code is intended to serve training information purposes only.
//            Please make sure to review our IdCloud documentation, including security guidelines.

import AVFoundation

protocol IdCloudQrCodeReaderDelegate: class {
    /**
     Triggered once QR code is successfuly parsed.
     
     @param sender Instance of QR Code reader. So we can check custom tag etc.
     @param qrCode Parsed code data.
     */
    func onQRCodeProvided(sender: IdCloudQrCodeReader, qrCode: String)
}

class IdCloudQrCodeReader: BaseViewController {

    // MARK: - Defines
    
    private var captureSession: AVCaptureSession!
    private var capturePreview: AVCaptureVideoPreviewLayer!
    weak var delegate: IdCloudQrCodeReaderDelegate?
    private var wasProcessed: Bool = false
    
    @IBOutlet weak var cameraLayer: UIView!
    
    // MARK: - Life Cycle
    
    class func readerWithDelegate(delegate:IdCloudQrCodeReaderDelegate) -> IdCloudQrCodeReader {
        return IdCloudQrCodeReader(delegate: delegate)
    }
    
    init(delegate: IdCloudQrCodeReaderDelegate) {
        super.init(nibName: "IdCloudQrCodeReader",
                   bundle: Bundle(for: IdCloudQrCodeReader.self))
        
        modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.delegate = delegate
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        captureStart()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        captureStop()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // This is enough to have proper size, but orientation might not be handled.
        captureUpdateBounds()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // This way we might reload constraint multiple times, but it will solve issue with 180 degree landscape change.
        // And trigger viewDidLayoutSubviews even during such rotation.
        cameraLayer.setNeedsLayout()
        view.setNeedsLayout()
    }
    
    // MARK: - Helpers
    
    private func captureStart() {
        // We want to notify handler just once.
        wasProcessed = false
        
        // Try to prepare capture device. This is not going to work on emulator and devices without camera in general.
        // Also user might not give permissins for camera.
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            notifyDisplay("Failed to create capture device.", type: NotifyType.error)
            return
        }
        
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            // Setup capture session. Output must be added before setting metadata types.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession = AVCaptureSession()
            captureSession.addInput(input)
            captureSession.addOutput(captureMetadataOutput)
            
            // Define callback and detection type to QR.
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

            
            // Add preview layer to UI.
            capturePreview = AVCaptureVideoPreviewLayer(session: captureSession)
            capturePreview.videoGravity = AVLayerVideoGravity.resizeAspectFill
            cameraLayer.layer.addSublayer(capturePreview)
            
            // Update default bounds. But at this point it might not be loaded yet.
            captureUpdateBounds()
            
            // Run capturing
            captureSession.startRunning()
        } catch let error {
            notifyDisplayErrorIfExists(error)
        }
    }
    
    private func captureStop() {
        // Stop and release all reader related items.
        captureSession.stopRunning()
        captureSession = nil
        
        capturePreview.removeFromSuperlayer()
        capturePreview = nil
        
        delegate = nil
    }
    
    private func captureUpdateBounds() {
        // In case that something went wrong during init.
        if (capturePreview == nil) {
            return
        }
        
        // Fill up full view frame
        capturePreview.frame = view.layer.bounds
        capturePreview.position = CGPoint(x: capturePreview.frame.midX, y: capturePreview.frame.midY)
            
        // Update orientation
        if let connection = capturePreview.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = videoOrientation()
        }
    }
    
    // Return proper otientation for preview. Enum is different than statusbar one.
    private func videoOrientation() -> AVCaptureVideoOrientation {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portrait, .unknown:
            return AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        @unknown default:
            return AVCaptureVideoOrientation.portrait
        }
    }
        
    // MARK: - User Interface
    
    @IBAction private func onButtonPressedCancel(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension IdCloudQrCodeReader: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        // Continue only if there is just one item detected and nothing was processed yet.
        if metadataObjects.count != 1 || wasProcessed {
            return
        }
        
        // We are interested in QR only.
        guard let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject, metadataObj.type == AVMetadataObject.ObjectType.qr else {
            return
        }
        
        // Process only valid QR codes.
        if let qrCode = metadataObj.stringValue {
            // Mark as processed so we will not trigger handler multiple times.
            wasProcessed = true
                    
            // Notify listener
            delegate?.onQRCodeProvided(sender: self, qrCode: qrCode)
        }
    }
}
