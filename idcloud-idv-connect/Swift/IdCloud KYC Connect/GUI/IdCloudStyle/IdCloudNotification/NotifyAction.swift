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

let kIconInfoName = "IdCloudNotificationInfo"
let kIconInfoColor = UIColor(red: 0.035, green: 0.33, blue: 0.94, alpha: 1.0)

let kIconWarningName = "IdCloudNotificationWarning"
let kIconWarningColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)

let kIconErrorName = "IdCloudNotificationError"
let kIconErrorColor = UIColor(red: 0.93, green: 0.09, blue: 0.11, alpha: 1.0)

let kIconBlinkName = "IdCloudNotificationBlink"
let kIconCenterName = "IdCloudNotificationCenter"
let kIconDownName = "IdCloudNotificationDown"
let kIconLeftName = "IdCloudNotificationLeft"
let kIconRightName = "IdCloudNotificationRight"
let kIconRotateName = "IdCloudNotificationRotate"
let kIconStillName = "IdCloudNotificationStill"
let kIconUpName = "IdCloudNotificationUp"

enum NotifyType {
    case info
    case warning
    case error
    case kyc_left
    case kyc_right
    case kyc_up
    case kyc_down
    case kyc_center
    case kyc_rotate
    case kyc_keepStill
    case kyc_blink
}

class NotifyAction: NSObject {
    
    // MARK: - Life Cycle
    
    private (set) var scheduledDisplay: Bool
    private (set) var scheduledType: NotifyType
    private (set) var scheduledLabel: String!
    
    class func actionHide() -> NotifyAction {
        return NotifyAction(display: false, label: nil, type: NotifyType.info)
    }
    
    class func actionShow(label: String, type: NotifyType) -> NotifyAction {
        return NotifyAction(display: true, label: label, type: type)
    }
    
    private init(display: Bool, label: String!, type: NotifyType) {
        scheduledDisplay = display
        scheduledLabel = label
        scheduledType = type
    }
    
    
    // MARK: - Static Helpers
    
    class func NotifyTypeColor(_ type: NotifyType) -> UIColor! {
        var retValue: UIColor! = nil
        
        switch (type) { 
        case NotifyType.error:
            retValue = kIconErrorColor
            break
        case NotifyType.warning:
            retValue = kIconWarningColor
            break
        case NotifyType.info,
             NotifyType.kyc_left,
             NotifyType.kyc_right,
             NotifyType.kyc_up,
             NotifyType.kyc_down,
             NotifyType.kyc_center,
             NotifyType.kyc_rotate,
             NotifyType.kyc_keepStill,
             NotifyType.kyc_blink:
            retValue = kIconInfoColor
            break
        }
        
        return retValue
    }
    
    class func NotifyTypeImage(_ type: NotifyType) -> UIImage! {
        var iconName: String! = nil
        
        switch (type) { 
        case NotifyType.error:
            iconName = kIconErrorName
            break
        case NotifyType.info:
            iconName = kIconInfoName
            break
        case NotifyType.warning:
            iconName = kIconWarningName
            break
        case NotifyType.kyc_left:
            iconName = kIconLeftName
            break
        case NotifyType.kyc_right:
            iconName = kIconRightName
            break
        case NotifyType.kyc_up:
            iconName = kIconUpName
            break
        case NotifyType.kyc_down:
            iconName = kIconDownName
            break
        case NotifyType.kyc_center:
            iconName = kIconCenterName
            break
        case NotifyType.kyc_rotate:
            iconName = kIconRotateName
            break
        case NotifyType.kyc_keepStill:
            iconName = kIconStillName
            break
        case NotifyType.kyc_blink:
            iconName = kIconBlinkName
            break
        }
        
        return UIImage(named: iconName)
    }
}
