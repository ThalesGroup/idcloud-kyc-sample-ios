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

class KYCTemplate: NSObject {

    private (set) var templateId: String?
    private (set) var issue: String?
    private (set) var issuerType: String?
    private (set) var issuerName: String?
    private (set) var keesingCode: String?
    
    init?(_ json: [String: Any]!) {
        guard json != nil else {
            return nil
        }
        
        templateId = json["id"] as? String
        issue = json["issue"] as? String
        issuerType = json["issuerType"] as? String
        issuerName = json["issuerName"] as? String
        keesingCode = json["keesingCode"] as? String
    }
    
    override var description: String {
        var retValue = "\(super.description)\n"
        retValue += "templateId: \(String(describing: templateId))\n"
        retValue += "issue: \(String(describing: issue))\n"
        retValue += "issuerType: \(String(describing: issuerType))\n"
        retValue += "issuerName: \(String(describing: issuerName))\n"
        retValue += "keesingCode: \(String(describing: keesingCode))\n"

        return retValue
    }
}
