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

func TRANSLATE(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

class IdCloudHelper : NSObject {

    class func unifyLabelsToSmallestSize(_ labels: UILabel...) {
        var minSize: CGFloat = 10000.0
        for loopLabel in labels {
            let size = IdCloudHelper.getActualFontSize(loopLabel)
            minSize = min(minSize, size)
        }
        
        for loopLabel in labels {
            loopLabel.font = loopLabel.font.withSize(minSize)
        }
    }

    class func getActualFontSize(_ label: UILabel!) -> CGFloat {
        let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : label.font as Any]
        let attributedString = NSAttributedString(string: label.text ?? "", attributes: attributes)

        let context = NSStringDrawingContext()
        context.minimumScaleFactor = label.minimumScaleFactor

        attributedString.boundingRect(with: label.bounds.size,
                                      options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                      context: context)

        return label.font.pointSize * context.actualScaleFactor
    }

    // inout can't be optional, but we can overload that.
    
    class func animateView(_ view: UIView, inParent parent: UIView) {
        var zero:CGFloat = 0
        IdCloudHelper.animateView(view, inParent: parent, withDelay: &zero)
    }
    
    class func animateView(_ view: UIView, inParent parent: UIView, withDelay delay: inout CGFloat) {
        let transformTo = view.transform
        let transformFrom = transformTo.translatedBy(x: -parent.frame.size.width, y: 0)

        view.transform = transformFrom

        UIView.animate(withDuration: 1.5,
                       delay: TimeInterval(delay),
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 0.5,
                       options: UIView.AnimationOptions.allowUserInteraction,
                       animations: {
                        view.transform = transformTo
        }, completion: nil)

        delay += 0.2
    }

    class func imageFromBase64(_ base64: String!) -> Data! {
        if ((base64 != nil) && !base64.isEmpty) {
            return Data(base64Encoded: base64, options: [])
        } else {
            return nil
        }
    }

    class func imageScaleToWidth(sourceImage: UIImage, scaledToWidth width: Int) -> UIImage {
        let oldWidth = sourceImage.size.width
        let scaleFactor = CGFloat(width) / oldWidth

        let newHeight = sourceImage.size.height * scaleFactor
        let newWidth = oldWidth * scaleFactor

        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        sourceImage.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
