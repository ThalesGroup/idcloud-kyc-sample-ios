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

class KYCFields: NSObject {

    private (set) var ocr: [KYCNameValue]
    private (set) var mrz: [KYCNameValue]
    private (set) var magstripe: [KYCNameValue]
    private (set) var barcode2d: [KYCNameValue]
    private (set) var native: [KYCNameValue]
    
    init?(_ json: [String: Any]!) {
        guard json != nil else {
            return nil
        }
        
        ocr = KYCFields.parseNameValueArray(json, key: "OCR")
        mrz = KYCFields.parseNameValueArray(json, key: "MRZ")
        magstripe = KYCFields.parseNameValueArray(json, key: "MAGSTRIPE")
        barcode2d = KYCFields.parseNameValueArray(json, key: "BARCODE_2D")
        native = KYCFields.parseNameValueArray(json, key: "NATIVE")
        
    }
    
    class func parseNameValueArray(_ json: [String: Any], key: String) -> [KYCNameValue]! {
        var retValue = [KYCNameValue]()
        for loopNameValue:[String: Any] in json[key] as! [[String: Any]] {
            if let nameValueToAdd = KYCNameValue(loopNameValue) {
                retValue.append(nameValueToAdd)
            }
        }
        
        return retValue
    }

    override var description: String {
        var retValue = "\(super.description)\n"
        retValue += "ocr: \(String(describing: ocr))\n"
        retValue += "mrz: \(String(describing: mrz))\n"
        retValue += "magstripe: \(String(describing: magstripe))\n"
        retValue += "barcode2d: \(String(describing: barcode2d))\n"
        retValue += "native: \(String(describing: native))\n"
        
        return retValue
    }
}
