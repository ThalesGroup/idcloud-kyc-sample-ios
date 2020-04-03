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

class KYCIntroViewController: BaseViewController {
    
    private let SequeNextPage = "sequeOpenNextPage"
    
    @IBOutlet weak var labelInit: UILabel!
    @IBOutlet weak var buttonNext: IdCloudButton!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Notifications about data layer change to reload table.
        // Unregistration is done in base class.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(KYCIntroViewController.reloadData),
                                               name: Notification.Name.DataLayerChanged,
                                               object: nil)
        
        reloadData()
    }
    
    // MARK: - Private Helpers
    
    @objc private func reloadData() {
        // Web token is set.
        if KYCManager.jsonWebToken() != nil {
            labelInit.isHidden = true
            buttonNext.setTitle(TRANSLATE("STRING_KYC_INTRO_BUTTON_NEXT"), for: UIControl.State.normal)
        } else {
            labelInit.isHidden = false
            buttonNext.setTitle(TRANSLATE("STRING_KYC_INTRO_BUTTON_SCANN"), for: UIControl.State.normal)
        }
    }
    
    // MARK: - User Interface
    
    @IBAction private func onButtonPressedSettings(_ sender: UIButton) {
        if let sideMenu = parent as? SideMenuViewController {
            sideMenu.menuDisplay()
        }
    }
    
    @IBAction func onButtonPressedNext(_ sender: IdCloudButton) {
        if (KYCManager.jsonWebToken() != nil) {
            performSegue(withIdentifier: SequeNextPage, sender: nil)
        } else {
            KYCManager.sharedInstance.displayQRcodeScannerForInit()
        }
    }
}
