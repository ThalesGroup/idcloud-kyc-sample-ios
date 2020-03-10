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

class KYCVerificationResult: NSObject {
    
    private (set) var result: String?
    private (set) var firstName: String?
    private (set) var middleName: String?
    private (set) var surname: String?
    private (set) var gender: String?
    private (set) var nationality: String?
    private (set) var expirationDate: String?
    private (set) var birthDate: String?
    private (set) var documentNumber: String?
    private (set) var documentType: String?
    private (set) var totalVerificationsDone: Int?
    private (set) var fields: KYCFields?
    private (set) var docTemplate: KYCTemplate?
    private (set) var numberOfImagesProcessed: Int?
    private (set) var alerts = [KYCAlert]()
    
    init?(_ json: [String: Any]!) {
        guard json != nil else {
            return nil
        }
        
        result = json["result"] as? String
        firstName = json["firstName"] as? String
        middleName = json["middleName"] as? String
        surname = json["surname"] as? String
        gender = json["gender"] as? String
        nationality = json["nationality"] as? String
        expirationDate = json["expirationDate"] as? String
        birthDate = json["birthDate"] as? String
        documentNumber = json["documentNumber"] as? String
        documentType = json["documentType"] as? String
        totalVerificationsDone = json["totalVerificationsDone"] as? Int
        fields = KYCFields(json["fields"] as? [String: Any])
        docTemplate = KYCTemplate(json["template"] as? [String: Any])
        for loopAlert:[String: Any] in json["alerts"] as! [[String: Any]] {
            if let alertToAdd = KYCAlert(loopAlert) {
                alerts.append(alertToAdd)
            }
        }
        numberOfImagesProcessed = json["numberOfImagesProcessed"] as? Int
    }
    
    override var description: String {
        var retValue = "\(super.description)\n"
        retValue += "result: \(String(describing: result))\n"
        retValue += "firstName: \(String(describing: firstName))\n"
        retValue += "middleName: \(String(describing: middleName))\n"
        retValue += "surname: \(String(describing: surname))\n"
        retValue += "gender: \(String(describing: gender))\n"
        retValue += "nationality: \(String(describing: nationality))\n"
        retValue += "expirationDate: \(String(describing: expirationDate))\n"
        retValue += "birthDate: \(String(describing: birthDate))\n"
        retValue += "documentNumber: \(String(describing: documentNumber))\n"
        retValue += "documentType: \(String(describing: documentType))\n"
        retValue += "totalVerificationsDone: \(String(describing: totalVerificationsDone))\n"
        retValue += "docTemplate: \(String(describing: docTemplate))\n"
        retValue += "alerts: \(String(describing: alerts))\n"
        retValue += "numberOfImagesProcessed: \(String(describing: numberOfImagesProcessed))\n"
        
        return retValue
    }
    
}
