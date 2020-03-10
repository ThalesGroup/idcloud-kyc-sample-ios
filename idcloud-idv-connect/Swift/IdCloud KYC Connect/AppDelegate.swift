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

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let kWindowBlurViewTag = 326598

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if (window?.viewWithTag(kWindowBlurViewTag) != nil) {
            return
        }
        window?.addSubview(self.bgBlurView())
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if let blurView = window?.viewWithTag(kWindowBlurViewTag) {
            UIView.animate(withDuration: 0.25,
                           delay:0.0,
                           options:UIView.AnimationOptions.curveEaseOut,
                           animations:{
                            blurView.alpha = 0.0
            }, completion:{ (_) in
                blurView.removeFromSuperview()
            })
        }
    }

    // MARK: - Private Helpers
        
    func bgBlurView() -> UIView {
        let retValue = UIVisualEffectView(effect:UIBlurEffect(style: UIBlurEffect.Style.light))
        retValue.frame  = window?.frame ?? CGRect.zero
        retValue.tag    = kWindowBlurViewTag
        retValue.alpha  = 0.0
        
        UIView.animate(withDuration: 0.25,
                       delay:0.0,
                       options:UIView.AnimationOptions.curveEaseOut,
                       animations:{
                        retValue.alpha = 1.0
        }, completion:nil)
        
        
        return retValue
    }

}

