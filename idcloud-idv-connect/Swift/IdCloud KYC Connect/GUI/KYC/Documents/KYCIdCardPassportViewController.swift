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

class KYCIdCardPassportViewController: KYCDocumentScannerViewController {
    
    // MARK: - Life Cycle
    
    var type: KYCDocumentType!
    
    @IBOutlet private weak var labelCaption: UILabel!
    @IBOutlet private weak var labelDescription01: UILabel!
    @IBOutlet private weak var imageDescription01: UIImageView!
    @IBOutlet private weak var labelDescription02: UILabel!
    @IBOutlet private weak var imageDescription02: UIImageView!
    @IBOutlet private weak var buttonNext: IdCloudButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Update screen based on configuration
        labelCaption.text = caption()
        labelDescription01.text = labelForIndex(1)
        labelDescription02.text = labelForIndex(2)
        imageDescription01.image = imageForIndex(1)
        imageDescription02.image = imageForIndex(2)
        
        // Skip animation during direct transition from doc scaner to face tutorial etc.
        if shouldAnimate {
            var delay:CGFloat = 0.0
            IdCloudHelper.animateView(labelDescription01, inParent: view, withDelay: &delay)
            IdCloudHelper.animateView(imageDescription01, inParent: view, withDelay: &delay)
            IdCloudHelper.animateView(labelDescription02, inParent: view, withDelay: &delay)
            IdCloudHelper.animateView(imageDescription02, inParent: view, withDelay: &delay)
            IdCloudHelper.animateView(buttonNext, inParent:view)
        }
        shouldAnimate = true
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Make sure that autoresized labels does have same size.
        IdCloudHelper.unifyLabelsToSmallestSize(labelDescription01, labelDescription02)
    }
    
    // MARK: - Private Helpers
    
    private func caption() -> String! {
        if type == KYCDocumentType.passport {
            return TRANSLATE("STRING_KYC_DOC_SCAN_CAPTION_PASSPORT")
        } else {
            return TRANSLATE("STRING_KYC_DOC_SCAN_CAPTION_IDCARD")
        }
    }
    
    private func labelForIndex(_ index: Int) -> String! {
        let stringKey = String(format: "STRING_KYC_DOC_SCAN_%02ld_AUTO", index)
        return TRANSLATE(stringKey)
    }
    
    private func imageForIndex(_ index:Int) -> UIImage! {
        let stringType = type == KYCDocumentType.passport ? "Passport" : "IdCard"
        let imageName = String(format: "KYC_ThirdStep_%@_%02ld_Auto", stringType, index)
        
        return UIImage.init(named: imageName)
    }
    
    // MARK: - User Interface

    @IBAction private func onButtonPressedNext(_ sender: UIButton) {
        showDocumentScan(type)
    }
}
