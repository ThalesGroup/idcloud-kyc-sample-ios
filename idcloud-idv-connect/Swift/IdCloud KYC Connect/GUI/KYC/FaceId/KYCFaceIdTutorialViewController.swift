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

import AcuantHGLiveness

class KYCFaceIdTutorialViewController: BaseViewController {
    
    // MARK: - Lifecycle
    
    @IBOutlet private weak var buttonNext: IdCloudButton!
    @IBOutlet private weak var imageExample: UIImageView!
    @IBOutlet private weak var imageGood: UIImageView!
    @IBOutlet private weak var imageBad: UIScrollView!
    @IBOutlet private weak var labelDescription: UILabel!
    @IBOutlet private weak var imageTutorialHand: UIImageView!
    
    internal var animateHand: Bool = false
    internal var shouldAnimate: Bool = true
    
    class func viewController() -> KYCFaceIdTutorialViewController {
        let storyboard = UIStoryboard(name: "KYCFace", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: String(describing: KYCFaceIdTutorialViewController.self)) as! KYCFaceIdTutorialViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageBad.delegate = self
        
        // Animate label
        if shouldAnimate {
            var delay: CGFloat = 0.0
            IdCloudHelper.animateView(labelDescription, inParent: view, withDelay: &delay)
            IdCloudHelper.animateView(imageGood, inParent: view, withDelay: &delay)
            IdCloudHelper.animateView(imageBad, inParent: view, withDelay: &delay)
            IdCloudHelper.animateView(imageExample, inParent: view, withDelay: &delay)
            IdCloudHelper.animateView(buttonNext, inParent: view)
            
            animateHand = true
            imageTutorialHand.alpha = 0.0
        }
        
        shouldAnimate = true
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if animateHand {
            // Animate hand move
            // First move it to 25% of table height
            let tableHeight = imageBad.bounds.size.height
            let originalPosition = imageBad.transform.translatedBy(x: 0, y: -tableHeight * 0.25)
            imageTutorialHand.transform = originalPosition
            
            animateShowMoveUpAndHide(delay: 1.0, handler: nil)
            
            animateHand = false
        }
    }
    
    // MARK: - Private Helpers
    
    private func animateShowMoveUpAndHide(delay: TimeInterval, handler: ((Bool)->Void)?) {
        let tableHeight = imageBad.bounds.size.height
        
        animateHandAlpha(alpha: 1.0, delay: delay, duration: 0.75, handler: { (finished:Bool) in
            if finished {
                self.animateHandMove(offset: tableHeight * 0.55, delay: 0.0, duration: 2.0, handler: { (finished:Bool) in
                    if finished {
                        self.animateHandAlpha(alpha: 0.0, delay:0.0, duration:1.5, handler: handler)
                    }
                })
            }
        })
    }
    
    private func animateHandAlpha(alpha: CGFloat, delay: TimeInterval, duration: TimeInterval, handler: ((Bool)->Void)?) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.5,
                       options: UIView.AnimationOptions.allowUserInteraction,
                       animations: {
                        self.imageTutorialHand.alpha = alpha
        }, completion: handler)
    }
    
    private func animateHandMove(offset: CGFloat, delay: TimeInterval, duration: TimeInterval, handler: ((Bool)->Void)?) {
        
        let transform = imageTutorialHand.transform.translatedBy(x: 0.0, y: -offset)
        
        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.5,
                       options: UIView.AnimationOptions.allowUserInteraction,
                       animations: {
                        //        self.imageBad.contentOffset = CGPointMake(0, offset);
                        self.imageTutorialHand.transform = transform
        }, completion: handler)
    }
        
    // MARK: - User Interface
    
    @IBAction private func onButtonPressedEnroll(_ sender: UIButton) {
        let faceCameraController = FaceLivenessCameraController()
        faceCameraController.delegate = self
        faceCameraController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        present(faceCameraController, animated: true, completion: nil)
    }
    
    @IBAction override func onButtonPressedBack(_ sender: UIButton) {
        // Make sure we will remove all stored images in order to make back button work properly.
        let manager:KYCManager! = KYCManager.sharedInstance
        manager.scannedDocFront = nil
        manager.scannedDocBack = nil
        
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIScrollViewDelegate

extension KYCFaceIdTutorialViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Disable horizontal scroll;
        scrollView.contentOffset =  CGPoint(x: 0.0, y: scrollView.contentOffset.y)
    }
}

// MARK: - AcuantHGLivenessDelegate

extension KYCFaceIdTutorialViewController: AcuantHGLivenessDelegate {
    func liveFaceCaptured(image: UIImage?) {
        if (image != nil) {
            let scaledImage = IdCloudHelper.imageScaleToWidth(sourceImage: image!, scaledToWidth: 640)
            KYCManager.sharedInstance.scannedPortrait = scaledImage.pngData()
        }
        
        shouldAnimate = false
        dismiss(animated: true, completion: nil)
        present(KYCOverviewViewController.viewController(), animated: true, completion: nil)
    }
}
