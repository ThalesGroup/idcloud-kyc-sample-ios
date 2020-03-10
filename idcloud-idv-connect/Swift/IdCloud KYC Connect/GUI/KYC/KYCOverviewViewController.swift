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


class KYCOverviewViewController: BaseViewController {
    
    // MARK: - Life Cycle
    
    @IBOutlet private weak var imagePortrait: UIImageView!
    @IBOutlet private weak var imagePortraitExtracted: UIImageView!
    @IBOutlet private weak var imageDocumentFront: UIImageView!
    @IBOutlet private weak var imageDocumentBack: UIImageView!
    @IBOutlet private weak var imageStatus: UIImageView!
    @IBOutlet private weak var labelStatus: UILabel!
    @IBOutlet private weak var labelResultCaption: UILabel!
    @IBOutlet private weak var labelResultValue: UILabel!
    @IBOutlet private weak var buttonNext: IdCloudButton!
    @IBOutlet private weak var stackResults: UIStackView!
    @IBOutlet private weak var stackPortraits: UIStackView!
    @IBOutlet private weak var stackDocuments: UIStackView!
    
    private var finished = false
    
    class func viewController() -> KYCOverviewViewController {
        let storyboard = UIStoryboard(name: "KYC", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: String(describing: KYCOverviewViewController.self)) as! KYCOverviewViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load current data.
        let manager:KYCManager = KYCManager.sharedInstance
        loadOrHideImage(manager.scannedPortrait, view: imagePortrait)
        loadOrHideImage(nil, view: imagePortraitExtracted)
        loadOrHideImage(manager.scannedDocFront, view: imageDocumentFront)
        loadOrHideImage(manager.scannedDocBack, view: imageDocumentBack)
        
        // Hide result area since we don't have any values yet.
        showOrHideResultArea(show: false, animated: false)
        
        // This property switch button behaviour.
        self.finished = false
        
        var delay: CGFloat = 0.0
        IdCloudHelper.animateView(stackPortraits, inParent: view, withDelay: &delay)
        IdCloudHelper.animateView(stackDocuments, inParent: view, withDelay: &delay)
        IdCloudHelper.animateView(imageStatus, inParent: view, withDelay: &delay)
        IdCloudHelper.animateView(labelStatus, inParent: view, withDelay: &delay)
        IdCloudHelper.animateView(buttonNext, inParent: view)
    }
    
    // MARK: - MainViewController
    
    func enableGUI(enabled: Bool) {
        super.enableGUI(enabled)
        
        buttonNext.isEnabled = enabled
    }
    
    // MARK: - Private Helpers
    
    private func showOrHideResultArea(show: Bool, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.5 : 0.0,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseInOut,
                       animations: {
                        self.stackResults.isHidden = !show
                        self.stackResults.alpha = show ? 1.0 : 0.0
        }, completion: nil)
    }
    
    private func loadOrHideImage(_ image: Data!, view: UIImageView) {
        if (image != nil) {
            view.image = UIImage.init(data: image)
        }
        view.isHidden = (image == nil)
    }
    
    private func displayResult(_ response: KYCResponse) {
        // Check if response was successfull.
        if response.document?.vericitaionResult?.result != "Passed" {
            displayError(response.message ?? "Unknown error", response:response)
            return
        }
        
        // Build user information strings.
        var caption = String()
        var value = String()
        
        if let firstName = response.document?.vericitaionResult?.firstName,
            let surname = response.document?.vericitaionResult?.surname {
            caption += "\(TRANSLATE("STRING_KYC_RESULT_NAME_SURNAME"))\n"
            value += "\(firstName) \(surname)\n"
        }
        appendResultString(retCaption: &caption, retValue: &value,
                           caption: TRANSLATE("STRING_KYC_RESULT_GENDER"),
                           value: response.document?.vericitaionResult?.gender)
        appendResultString(retCaption: &caption, retValue: &value,
                           caption: TRANSLATE("STRING_KYC_RESULT_NATIONALITY"),
                           value: response.document?.vericitaionResult?.nationality)
        appendResultString(retCaption: &caption, retValue: &value,
                           caption: TRANSLATE("STRING_KYC_RESULT_EXOIRY_DATE"),
                           value: response.document?.vericitaionResult?.expirationDate)
        appendResultString(retCaption: &caption, retValue: &value,
                           caption: TRANSLATE("STRING_KYC_RESULT_BIRTH_DATE"),
                           value: response.document?.vericitaionResult?.birthDate)
        appendResultString(retCaption: &caption, retValue: &value,
                           caption: TRANSLATE("STRING_KYC_RESULT_DOC_NUMBER"),
                           value: response.document?.vericitaionResult?.documentNumber)
        appendResultString(retCaption: &caption, retValue: &value,
                           caption: TRANSLATE("STRING_KYC_RESULT_DOC_TYPE"),
                           value: response.document?.vericitaionResult?.documentType)
        appendResultInt(retCaption: &caption, retValue: &value,
                        caption: TRANSLATE("STRING_KYC_RESULT_TOTAL_VERIFICATIONS"),
                        value: response.document?.vericitaionResult?.totalVerificationsDone ?? 0)
        
        
        
        labelResultCaption.text = caption
        labelResultValue.text = value
        
        // Update status message.
        labelStatus.text = response.document?.vericitaionResult?.result
        imageStatus.image = UIImage(named: "KYC_Overview_Passed")
        imageStatus.tintColor = UIColor.green
        
        // Update extracted portrait.
        loadOrHideImage(response.document?.portrait, view: imagePortraitExtracted)
        
        // Animate result part.
        showOrHideResultArea(show: true, animated: true)
        
        // Update button function
        buttonNext.setTitle(TRANSLATE("STRING_COMMON_DONE"), for: UIControl.State.normal)
        finished = true
    }
    
    private func displayError(_ error: String, response: KYCResponse?) {
        
        // Append detail information about failed check if available.
        var fullErr = String(error)
        
        if let alerts = response?.document?.vericitaionResult?.alerts {
            if (response != nil) && !alerts.isEmpty {
                fullErr += "\n"
                for loopAlert in alerts {
                    fullErr += "\(String(describing: loopAlert.name)), "
                }
                fullErr.removeLast(2)
            }
        }
        
        labelStatus.text = fullErr
        imageStatus.image = UIImage.init(named: "KYC_Overview_Error")
        imageStatus.tintColor = UIColor.red
    }
    
    private func appendResultString(retCaption: inout String,
                                    retValue: inout String,
                                    caption: String, value: String!) {
        if (value != nil) && !(value == "null") && !value.isEmpty {
            retCaption += "\(caption)\n"
            retValue += "\(value!)\n"
        }
    }
    
    private func appendResultInt(retCaption: inout String,
                                 retValue: inout String,
                                 caption: String, value: Int) {
        retCaption += "\(caption)\n"
        retValue += "\(value)\n"
    }
    
    // MARK: - User Interface
    
    @IBAction override func onButtonPressedBack(_ sender: UIButton) {
        // Make sure we will remove all stored images in order to make back button work properly.
        let manager:KYCManager = KYCManager.sharedInstance
        if KYCManager.facialRecognition() {
            manager.scannedPortrait = nil
        } else {
            manager.scannedDocFront = nil
            manager.scannedDocBack = nil
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func onButtonPressed(_ sender: UIButton) {
        if finished {
            onButtonPressedDone()
        } else {
            onButtonPressedSubmit()
        }
    }
    
    private func onButtonPressedDone() {
        // Mark document enrollment as finished and switch scene.
        let manager:KYCManager! = KYCManager.sharedInstance
        KYCManager.setKycEnrolled(true)
        manager.scannedDocBack = nil
        manager.scannedDocFront = nil
        manager.scannedPortrait = nil
        
        // Dismiss all view controllers on top of root one.
        view.window!.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    private func onButtonPressedSubmit() {
        let manager = KYCManager.sharedInstance
        
        // Display loading status and block UI.
        loadingIndicatorShowWithCaption(TRANSLATE("STRING_LOADING_SUBMITTING"))
        
        // Send data to server and wait for response.
        KYCCommunication.verifyDocumentFront(
            docFront: manager.scannedDocFront,
            documentBack: manager.scannedDocBack,
            selfie: manager.scannedPortrait) { (response: KYCResponse!, error: String!) in
                
                // Hide loading indicator and unblock UI.
                self.loadingIndicatorHide()
                
                if response != nil {
                    self.displayResult(response)
                } else if error != nil {
                    // No response? Display error if we have one, otherwise some generict err message.
                    self.displayError(error.description, response:nil)
                } else {
                    self.displayError("Failed to get valid response from server.", response:nil)
                }
        }
    }
}
