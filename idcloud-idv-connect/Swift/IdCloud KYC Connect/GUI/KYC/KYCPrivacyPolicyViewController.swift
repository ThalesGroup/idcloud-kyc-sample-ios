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

class KYCPrivacyPolicyViewController: BaseViewController {
    
    // MARK: - Life Cycle
    
    @IBOutlet private weak var labelCaption: UILabel!
    @IBOutlet private weak var labelDescription: UILabel!
    @IBOutlet private weak var imageLock: UIImageView!
    @IBOutlet private weak var buttonPrivacyPolicy: UIButton!
    @IBOutlet private weak var buttonTermsOfUse: UIButton!
    
    class func viewController() -> KYCPrivacyPolicyViewController {
        let storyboard = UIStoryboard(name: "KYC", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: String(describing: KYCPrivacyPolicyViewController.self)) as! KYCPrivacyPolicyViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Animate label
        var delay:CGFloat = 0.0
        IdCloudHelper.animateView(imageLock, inParent: view, withDelay: &delay)
        IdCloudHelper.animateView(labelDescription, inParent: view, withDelay: &delay)
        IdCloudHelper.animateView(buttonPrivacyPolicy, inParent: view, withDelay: &delay)
        IdCloudHelper.animateView(buttonTermsOfUse, inParent: view, withDelay: &delay)
    }
    
    // MARK: - User Interface
    
    @IBAction private func onButtonPressedPrivacyPolicy(_ sender: UIButton) {
        if (CFG_PRIVACY_POLICY_URL != nil) {
            UIApplication.shared.open(CFG_PRIVACY_POLICY_URL!, options: [:], completionHandler: nil)
        }
    }
}
