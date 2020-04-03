/*
 MIT License
 
 Copyright (c) 2020 Thales DIS
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 IMPORTANT: This source code is intended to serve training information purposes only.
 Please make sure to review our IdCloud documentation, including security guidelines.
 */

import AcuantCamera
import AcuantCommon
import AcuantImagePreparation
import AcuantIPLiveness
import AVFoundation

class KYCDocumentScannerViewController: BaseViewController {
    
    // MARK: - Life Cycle
    
    internal var shouldAnimate: Bool = true
    internal var documentType: KYCDocumentType?
    
    // MARK: - Public API
    
    func showDocumentScan(_ type: KYCDocumentType) {
        documentType = type
        showDocumentCaptureCamera()
    }
    
    // MARK: - Private Helpers
    
    private func nextStepAfterDocumentScanning() {
        if KYCManager.facialRecognition() {
            present(KYCFaceIdTutorialViewController.viewController(), animated: true, completion: nil)
        } else {
            present(KYCOverviewViewController.viewController(), animated: true, completion: nil)
        }
    }
    
    private func requestAccesSync(handler: @escaping ()->Void) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted:Bool) in
            DispatchQueue.main.async {
                if granted {
                    handler()
                } else {
                    notifyDisplay("Camera access is absolutely necessary to use this app", type: NotifyType.error)
                }
            }
        }
    }
    
    private func getCameraOptions() -> AcuantCameraOptions! {
        return AcuantCameraOptions(timeInMsPerDigit: 900,
                                   digitsToShow: 2,
                                   allowBox: true,
                                   autoCapture: true,
                                   hideNavigationBar: true,
                                   bracketLengthInHorizontal: 80,
                                   bracketLengthInVertical: 50,
                                   defaultBracketMarginWidth: 0.5,
                                   defaultBracketMarginHeight: 0.6,
                                   colorHold: UIColor.yellow.cgColor,
                                   colorCapturing: UIColor.green.cgColor,
                                   colorBracketAlign: UIColor.black.cgColor,
                                   colorBracketCloser: UIColor.red.cgColor,
                                   colorBracketHold: UIColor.yellow.cgColor,
                                   colorBracketCapture: UIColor.green.cgColor)
    }
    
    private func showDocumentCaptureCamera() {
        requestAccesSync {
            let documentCameraController = DocumentCameraController.getCameraController(delegate: self, cameraOptions: self.getCameraOptions())
            documentCameraController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            self.present(documentCameraController, animated: true, completion: nil)
        }
    }
    
    private func getCropedImage(_ image: Image) -> Image {
        let data:CroppingData! = CroppingData()
        data.image = image.image
                
        return AcuantImagePreparation.crop(data: data)
    }
    
    private func tryAgainWithMessage(message: String) {
        displayOnCancelDialog(caption: "Try Again",
                              message: message,
                              okButton: "Try Again",
                              cancelButton: "Cancel") { (result) in
                                if (result) {
                                    self.showDocumentCaptureCamera()
                                }
        }
        
    }
}

// MARK: - CameraCaptureDelegate

extension KYCDocumentScannerViewController: CameraCaptureDelegate {
    func setCapturedImage(image: Image, barcodeString: String?) {
        // Hide current scanner.
        shouldAnimate = false
        dismiss(animated: true, completion: nil)
        
        // Get manager and encode image.
        let manager = KYCManager.sharedInstance
        let croppedImage = getCropedImage(image)
        
        if (croppedImage.image == nil || (croppedImage.error != nil && croppedImage.error!.errorCode == AcuantErrorCodes.ERROR_LowResolutionImage)) {
            tryAgainWithMessage(message: croppedImage.error!.description)
        } else {
            var scaledImage = croppedImage.image!
            if Int(scaledImage.size.width) > KYCManager.maxImageWidth() {
                scaledImage = IdCloudHelper.imageScaleToWidth(sourceImage: scaledImage, scaledToWidth: KYCManager.maxImageWidth())
            }
                        
            // Check image sharpness, glare and minimum DPI.
            let sharpness = AcuantImagePreparation.sharpness(image: scaledImage)
            let glare = AcuantImagePreparation.glare(image: croppedImage.image!)
            if (sharpness < CaptureConstants.SHARPNESS_THRESHOLD || glare < CaptureConstants.GLARE_THRESHOLD ||
                croppedImage.dpi < CaptureConstants.MANDATORY_RESOLUTION_THRESHOLD_SMALL) {
                let message = "Image did not meet basic criteria.\nSharpness: \(sharpness)(\(CaptureConstants.SHARPNESS_THRESHOLD))\nGlare: \(glare)(\(CaptureConstants.GLARE_THRESHOLD))\nDPI: \(croppedImage.dpi)(\(CaptureConstants.MANDATORY_RESOLUTION_THRESHOLD_SMALL))"
                tryAgainWithMessage(message: message)
            } else {
                let coppedImageData = croppedImage.image!.jpegData(compressionQuality: 0.8)
                // Update current step.
                if documentType == KYCDocumentType.idCard && manager.scannedDocFront != nil {
                    manager.scannedDocBack = coppedImageData
                    nextStepAfterDocumentScanning()
                } else {
                    manager.scannedDocFront = coppedImageData
                    if documentType == KYCDocumentType.passport {
                        nextStepAfterDocumentScanning()
                    } else {
                        // First page is scanned continue with another one.
                        showDocumentCaptureCamera()
                    }
                }
            }
        }
    }
}
