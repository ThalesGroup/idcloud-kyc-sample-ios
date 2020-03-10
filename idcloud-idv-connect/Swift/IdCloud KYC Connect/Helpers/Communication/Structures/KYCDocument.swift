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

class KYCDocument: NSObject {
    
    private (set) var vericitaionResult: KYCVerificationResult?
    private (set) var portrait: Data?
    private (set) var imageWhiteBack: Data?
    private (set) var imageWhiteFront: Data?
    
    init?(_ json: [String: Any]!) {
        guard json != nil else {
            return nil
        }
        
        vericitaionResult = KYCVerificationResult(json["verificationResults"] as? [String: Any])
        portrait = IdCloudHelper.imageFromBase64(json["portrait"] as? String)
        imageWhiteBack = IdCloudHelper.imageFromBase64(json["backWhiteImage"] as? String)
        imageWhiteFront = IdCloudHelper.imageFromBase64(json["frontWhiteImage"] as? String)
    }
    
    override var description: String {
        var retValue = "\(super.description)\n"
        retValue += "vericitaionResult: \(String(describing: vericitaionResult))\n"
        
        return retValue
    }
}
