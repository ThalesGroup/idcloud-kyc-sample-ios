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

class BaseViewController: IdCloudAutorotationVC {
    
    // MARK: - Life Cycle
    @IBOutlet private weak var labelDomain: UILabel!
    @IBOutlet private weak var labelTokenName: UILabel!
    
    private var loadingIndicator: IdCloudLoadingIndicator!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (loadingIndicator == nil) {
            loadingIndicator = IdCloudLoadingIndicator.loadingIndicator()
            view.addSubview(loadingIndicator)
        }
        
        // Realod common as well as inherited values.
        reloadGUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Loading Indicator
    
    func loadingIndicatorShowWithCaption(_ caption: String) {
        // Loading indicator is already present or not configured for view at all.
        if (loadingIndicator == nil) || loadingIndicator.isPresent {
            return
        }
        
        // Display loading indicator.
        loadingIndicator.setCaption(caption)
        loadingIndicator.loadingBarShow(true, animated: true)
        
        // We want to lock UI behind it.
        reloadGUI()
    }
    
    func loadingIndicatorHide() {
        // Loading indicator is already hidden or not configured for view at all.
        if (loadingIndicator == nil) || !loadingIndicator.isPresent {
            return
        }
        
        // Hide loading indicator.
        loadingIndicator.loadingBarShow(false, animated: true)
        
        // We want to un-lock UI behind it.
        reloadGUI()
    }
    
    func overlayViewVisible() -> Bool {
        return loadingIndicator.isPresent
    }
    
    // MARK: - Dialogs
    
    func displayOnCancelDialog(caption: String,
                               message: String,
                               okButton: String,
                               cancelButton: String,
                               completionHandler handler: @escaping (_ okButtonPressed: Bool)->Void) {
        // Main alert builder.
        let alert = UIAlertController.init(title: caption, message: message, preferredStyle: UIAlertController.Style.alert)
        
        // Add ok button with handler.
        alert.addAction(UIAlertAction.init(title: okButton, style: UIAlertAction.Style.destructive) { (UIAlertAction) in
            handler(true)
        })
        // Add cancel button with handler.
        alert.addAction(UIAlertAction.init(title: cancelButton, style: UIAlertAction.Style.cancel) { (UIAlertAction) in
            handler(false)
        })
        
        // Present dialog.
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Common Helpers
    
    func reloadGUI() {
        enableGUI(!overlayViewVisible())
    }
    
    func enableGUI(_ enabled: Bool) {
        // Override
    }
    
    // MARK: - User Interface
    @IBAction func onButtonPressedBack(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
