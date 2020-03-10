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

class IdCloudLoadingIndicator: IdCloudXibView {
    
    // MARK: - Defines
    
    private (set) var isPresent: Bool = false
        
    @IBOutlet weak var background: IdCloudBackground!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var labelCaption: UILabel!
    
    // MARK: - Life Cycle
    
    class func loadingIndicator() -> IdCloudLoadingIndicator {
        return IdCloudLoadingIndicator(frame: UIScreen.main.bounds)
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func initXIB() {
        super.initXIB()
        
        // Actual view will be added as child. Make self transparent.
        backgroundColor = UIColor.clear
        
        // Set visibility to true so internal check will not skip call
        isPresent = true
        
        // By default it shloud be hidden.
        loadingBarShow(false, animated: false)
        
        // Add shadow to content view.
        IDCloudDesignableHelpers.applyShadow(to: background)
    }
    
    // MARK: - Public API
    
    func loadingBarShow(_ show: Bool, animated: Bool) {
        // Avoid multiple call with same result.
        if isPresent == show {
            return
        }
        
        // Start / Stop iOS loading indicator animation.
        if show {
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
        }
        
        // Stop any possible previous animations since we are not waiting for result.
        layer.removeAllAnimations()
        
        // Animate transition.
        if animated {
            if show {
                isHidden = false
            }
            
            UIView.animate(withDuration: 0.5,
                           delay: 0.0,
                           options: UIView.AnimationOptions.curveEaseInOut,
                           animations: {
                            self.alpha = show ? 1.0 : 0.0
            } ) { (finished: Bool) in
                if finished && !show {
                    self.isHidden = true
                }
            }
        } else {
            alpha = show ? 1.0 : 0.0
            isHidden = !show
        }
        
        isPresent = show
        
        // Remove last label after hide.
        if !show {
            labelCaption.text = nil
        }
    }
    
    func setCaption(_ caption: String!) {
        labelCaption.text = caption
    }
}
