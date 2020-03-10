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

class KYCResponse: NSObject {
    private (set) var message: String?
    private (set) var type: String?
    private (set) var code: Int?
    private (set) var document: KYCDocument?
    private (set) var face: KYCFace?
    
    init?(_ json: [String: Any]!) {
        guard json != nil else {
            return nil
        }
        
        code = json["code"] as? Int ?? 0
        message = json["message"] as? String
        type = json["type"] as? String
        document = KYCDocument((json["object"] as? [String: Any])?["document"] as? [String: Any])
        
        super.init()
    }
    
    func updateWithSelfieJSON(response:[String: Any]?) {
        face = KYCFace((response?["object"] as? [String: Any])?["face"] as? [String: Any])
    }
    
    override var description : String {
        var retValue = "\(super.description)\n"
        retValue += "code: \(String(describing: code))\n"
        retValue += "message: \(String(describing: message))\n"
        retValue += "type: \(String(describing: type))\n"
        retValue += "document: \(String(describing: document))\n"
        retValue += "face: \(String(describing: face))\n"

        return retValue
    }
}
