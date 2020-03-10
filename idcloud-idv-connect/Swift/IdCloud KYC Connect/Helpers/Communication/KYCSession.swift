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


typealias KYCResponseHandler = ( _ kycResponse: KYCResponse?, _ errorMessage: String?) -> ()

private let kCommonStateFailed  = "Failed"   // Check state.result for more details.
private let kCommonStateError   = "Error"    // Configuration error. Contact Thales representative.

class KYCSession : NSObject {
    
    // MARK: - Life Cycle
    
    private (set) var portrait: Data?
    private var urlBase: String
    private var sessionId: String!
    private var handler: KYCResponseHandler
    
    
    init(urlBase:String, portrait: Data!, andHandler handler: @escaping KYCResponseHandler) {
        self.portrait = portrait
        self.urlBase = urlBase
        self.handler = handler
    }
    
    // MARK: - Public Methods
    
    func urlDocument() -> URL {
        if var retUrl = URL.init(string: urlBase) {
            retUrl.appendPathComponent(sessionId)
            retUrl.appendPathComponent("/state/steps/verifyResults")
            return retUrl
        } else {
            fatalError()
        }
    }
    
    func urlSelfie() -> URL {
        if var retUrl = URL.init(string: urlBase) {
            retUrl.appendPathComponent(sessionId)
            retUrl.appendPathComponent("/state/steps/faceMatch")
            return retUrl
        } else {
            fatalError()
        }
    }
    
    func parseResultAndHandleErrors(_ data: Data!) -> [String: Any]? {
        do {
            // Parse server response and check possible errors.
            let retValue = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            
            // Get and update session Id.
            sessionId = retValue["id"] as? String
            if (sessionId == nil || sessionId.isEmpty) {
                handleError("Failed to get valid session id.")
                return nil
            }
            
            // Check response status.
            let status = retValue["status"] as? String
            if (status == kCommonStateFailed) {
                let message = ((retValue["state"] as? [String: Any])?["result"] as? [String: Any])?["message"] as? String ?? "Unknown error"
                handleError(message)
                return nil
            } else if (status == kCommonStateError) {
                handleError("Configuration error. Contact Thales representative.")
                return nil
            }
            
            return retValue
        } catch let error {
            handleError(error.localizedDescription)
            return nil
        }
    }
    
    func handleError(_ error: String) {
        DispatchQueue.main.async {
            self.handler(nil, error)
        }
    }
    
    func handleResult(_ result: KYCResponse) {
        DispatchQueue.main.async {
            self.handler(result, nil)
        }
    }
}
