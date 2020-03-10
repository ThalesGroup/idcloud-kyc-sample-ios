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

class KYCFirstStepViewController: BaseViewController {
    
    // MARK: - Lifecycle
    
    @IBOutlet private weak var labelDescription: UILabel!
    @IBOutlet private weak var stackSteps: UIStackView!
    @IBOutlet private weak var buttonNext: IdCloudButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Remove current setup.
        for loopView in stackSteps.arrangedSubviews {
            stackSteps.removeArrangedSubview(loopView)
            loopView.removeFromSuperview()
        }
        
        // Animate label
        var delay: CGFloat = 0.0
        IdCloudHelper.animateView(labelDescription, inParent: view, withDelay: &delay)
        
        // Add new chevrons based on configuration.
        addChevronWithCaption(caption: TRANSLATE("STRING_KYC_FIRST_STEP_ID"),
                              imageName: "KYC_FirstStep_IdRed",
                              delay: &delay)
        if (KYCManager.facialRecognition()){
            addChevronWithCaption(caption: TRANSLATE("STRING_KYC_FIRST_STEP_FACE"),
                                  imageName: "KYC_FirstStep_PersonRed",
                                  delay: &delay)
        }
        addChevronWithCaption(caption: TRANSLATE("STRING_KYC_FIRST_STEP_REVIEW"),
                              imageName: "KYC_FirstStep_CheckRed",
                              delay: &delay)
        
        IdCloudHelper.animateView(buttonNext, inParent: view)
    }
    
    
    // MARK: - Private Helpers
    
    private func addChevronWithCaption(caption: String, imageName: String, delay: inout CGFloat) {
        let image = UIImage.init(named: imageName)!
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: image.size.width).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: image.size.height).isActive = true
        imageView.image = image
        
        let labelCaption:UILabel = UILabel(frame: CGRect.zero)
        labelCaption.font = UIFont.init(name: "HelveticaNeue-Light", size: 18.0)
        labelCaption.textColor = UIColor.init(named: "TextPrimary")
        labelCaption.textAlignment = NSTextAlignment.left
        labelCaption.text = caption
        
        let stackToAdd:UIStackView = UIStackView(arrangedSubviews:[imageView, labelCaption])
        stackToAdd.axis =  NSLayoutConstraint.Axis.horizontal
        stackToAdd.alignment = UIStackView.Alignment.fill
        stackToAdd.distribution = UIStackView.Distribution.fill
        stackToAdd.spacing = 8.0
        
        stackSteps.addArrangedSubview(stackToAdd)
        
        // Animate
        IdCloudHelper.animateView(stackToAdd, inParent: view, withDelay: &delay)
    }
}
