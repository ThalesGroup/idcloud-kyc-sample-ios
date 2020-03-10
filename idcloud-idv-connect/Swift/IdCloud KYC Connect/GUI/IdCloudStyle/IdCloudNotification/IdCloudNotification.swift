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

private let kAnimationSpeed: TimeInterval = 0.3
private let kFramePadding: CGFloat = 16.0
private let kDisplayOffset: CGFloat = 32.0

// Make it easier to user with shorter text footprint.
func notifyDisplay(_ message: String, type: NotifyType) {
    IdCloudNotification.sharedInstance.display(message: message, type: type)
}
func notifyDisplayErrorIfExists(_ error: Error?) {
    IdCloudNotification.sharedInstance.displayErrorIfExists(error)
}

class IdCloudNotification: IdCloudBackground {
    
    // MARK: - Defines
    
    private var imageView: UIImageView!
    private var labelCaption: UILabel!
    private var runningAction: Bool = false
    private var scheduledActions: [NotifyAction]!
    private var frameHidden: CGRect = CGRect.zero
    private var frameVisible: CGRect = CGRect.zero
    
    // MARK: - Life Cycle
    
    static let sharedInstance: IdCloudNotification = {
        return IdCloudNotification(frame: UIScreen.main.bounds)
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initXIB()
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        
        initXIB()
    }
    
    private func initXIB() {
        // There is no running action by default and state is hidden.
        runningAction = false
        scheduledActions = []
        
        // Hide view on user tap.
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onUserTap(recognizer:))))
        
        // Load all gui elements.
        initGUI()
    }
    
    // MARK: - Public API
    
    func display(message: String, timeout timeoutInSec: TimeInterval, type: NotifyType) {
        
        // First make sure that view is in correct state.
        scheduleHideIfNeeded()
        
        // Schedule new message show.
        scheduledActions.append(NotifyAction.actionShow(label: message, type: type))
        
        // Trigger queue processing.
        proccessQueue()
        
        // Hide after delay.
        cancelScheduledActions()
        perform(#selector(hide), with: nil, afterDelay: timeoutInSec)
    }
    
    func display(message: String, type: NotifyType) {
        display(message: message, timeout: 3, type: type)
    }
    
    func displayErrorIfExists(_ error: Error!) {
        if (error != nil) {
            display(message: error.localizedDescription, type: NotifyType.error)
        }
    }
    
    @objc func hide() {
        // Schedule hide if it's not already.
        scheduleHideIfNeeded()
        
        // Trigger queue processing.
        proccessQueue()
    }
    
    // MARK: - Private Helpers
    
    private func initGUI() {
        cornerRadius = 10.0
        borderWidth = 1.0
        borderColor = UIColor.lightGray
        if #available(iOS 13.0, *) {
            backgroundColor = UIColor.systemGroupedBackground
        } else {
            backgroundColor = UIColor.groupTableViewBackground
        }
        
        // Prepare UI
        guard let image = NotifyAction.NotifyTypeImage(NotifyType.warning) else {
            // Missing assets
            fatalError()
        }
        
        imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        addSubview(imageView)
        
        labelCaption = UILabel(frame: CGRect.zero)
        labelCaption.font = UIFont(name: "HelveticaNeue-Light", size: 18.0)
        labelCaption.translatesAutoresizingMaskIntoConstraints = false
        labelCaption.numberOfLines = 10
        labelCaption.textAlignment = NSTextAlignment.center
        addSubview(labelCaption)
        
        // Keep image size all the time
        imageView.widthAnchor.constraint(equalToConstant: image.size.width).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: image.size.height).isActive = true
        // Move image kFramePadding points from super view left side.
        imageView.leftAnchor.constraint(equalTo: leftAnchor, constant: kFramePadding).isActive = true
        // Center image vertically.
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        // Make space between image and label kFramePadding points.
        labelCaption.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: kFramePadding).isActive = true
        // Label should be kFramePadding points from right side.
        labelCaption.rightAnchor.constraint(equalTo: rightAnchor, constant: -kFramePadding).isActive = true
        // Center label vertically.
        labelCaption.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        // Hide view by default.
        isHidden = true
    }
    
    private func findParentVC() -> UIViewController {
        var lastVC = UIApplication.shared.windows.first!.rootViewController
        var loopVC = lastVC
        
        while loopVC != nil {
            lastVC = loopVC
            loopVC = loopVC?.presentedViewController
        }
        
        // Current VC is being dismissed. Use it's parent at new VC for notification.
        if (lastVC?.isBeingDismissed ?? false) {
            lastVC = lastVC!.presentingViewController
        }
        
        return lastVC!
    }
    
    private func scheduleHideIfNeeded() {
        // Schedule hide if last scheduled action is not that one already.
        // Or there is no action scheduled and view is not hidden.
        if (!scheduledActions.isEmpty && scheduledActions.last!.scheduledDisplay) ||
            (scheduledActions.isEmpty && !isHidden) {
            // In both cases add hide action first.
            scheduledActions.append(NotifyAction.actionHide())
        }
    }
    
    private func proccessQueue() {
        if runningAction || scheduledActions.isEmpty {
            return
        }
        
        let newAction = scheduledActions.first!
        if newAction.scheduledDisplay {
            actionShow(newAction)
        } else {
            actionHide(newAction)
        }
    }
    
    private func frameWidthWithString(_ string: String) -> CGSize {
        // We are going to fit notification to screen width.
        let bounds = UIScreen.main.bounds
        
        // First set maximum allowed text width.
        let fullOffset: CGFloat = 5.0 * kFramePadding + imageView.bounds.size.width
        let outerOffset: CGFloat = 3.0 * kFramePadding + imageView.bounds.size.width
        labelCaption.preferredMaxLayoutWidth = bounds.size.width - fullOffset
        
        // With prefered line width we can calculate actual size.
        let textSize = labelCaption.intrinsicContentSize
        var retWidth: CGFloat = outerOffset + textSize.width
        let retHeight: CGFloat = 2.0 * kFramePadding + max(imageView.bounds.size.height, textSize.height)
        
        // Fit to screen width - edge padding.
        retWidth = min(bounds.size.width - 2.0 * kFramePadding, retWidth)
        
        return CGSize(width: retWidth, height: retHeight)
    }
    
    private func actionShow(_ action: NotifyAction) {
        let bounds = UIScreen.main.bounds
        
        // Mark that we are running some action.
        runningAction = true
        
        // Change content before frame calculation
        labelCaption.text = action.scheduledLabel
        imageView.image = NotifyAction.NotifyTypeImage(action.scheduledType)
        imageView.tintColor = NotifyAction.NotifyTypeColor(action.scheduledType)
        
        // Update frame size based on new content.
        let size: CGSize = frameWidthWithString(action.scheduledLabel)
        frameHidden = CGRect(x: bounds.size.width * 0.5 - size.width * 0.5,
                             y: bounds.size.height + size.height + kDisplayOffset,
                             width: size.width, height: size.height)
        frameVisible = CGRect(x: bounds.size.width * 0.5 - size.width * 0.5,
                              y: bounds.size.height - size.height - kDisplayOffset,
                              width: size.width, height: size.height)
        
        // Move frame under screen and unhide it.
        frame = frameHidden
        isHidden = false
        
        // Add view to current top viewcontroller view.
        findParentVC().view.addSubview(self)
        
        // Animate display.
        UIView.animate(withDuration: kAnimationSpeed,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseInOut,
                       animations: {
                        self.frame = self.frameVisible
        }) { (finished: Bool) in
            // Remove current action from queue
            if let index = self.scheduledActions.firstIndex(of: action) {
                self.scheduledActions.remove(at: index)
            }
            
            // Mark action finished and process next one in queue.
            self.runningAction = false
            self.proccessQueue()
        }
    }
    
    private func actionHide(_ action: NotifyAction) {
        // Mark that we are running some action.
        runningAction = true
        
        // Move frame under screen and unhide it.
        frame = frameVisible
        superview?.layoutIfNeeded()
        
        // Animate hide action.
        UIView.animate(withDuration: kAnimationSpeed,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseInOut,
                       animations: {
                        self.frame = self.frameHidden
        }) { (finished: Bool) in
            // Remove current action from queue
            if let index = self.scheduledActions.firstIndex(of: action) {
                self.scheduledActions.remove(at: index)
            }
            
            // Hide view.
            self.isHidden = true
            self.removeFromSuperview()
            
            // Mark action finished and process next one in queue.
            self.runningAction = false
            self.proccessQueue()
        }
    }
    
    private func cancelScheduledActions() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hide), object: nil)
    }
    
    // MARK: - User Interface
    
    @objc private func onUserTap(recognizer: UITapGestureRecognizer!) {
        hide()
    }
}
