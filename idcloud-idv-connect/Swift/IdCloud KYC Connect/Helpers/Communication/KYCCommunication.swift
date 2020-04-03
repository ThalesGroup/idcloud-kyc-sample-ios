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

private let kStateWaiting   = "Waiting"  // Waiting for remaining images.
private let kStateFinished  = "Finished" // All images was uploaded and processed.

typealias RequestBuilder = ( _ request: URLRequest?, _ error: Error?) -> ()

class KYCCommunication : NSObject {
    
    // MARK: - Public API
    
    class func verifyDocumentFront(docFront: Data!,
                                   documentBack docBack: Data!,
                                   selfie: Data!,
                                   completionHandler handler: @escaping KYCResponseHandler) {
        
        // To make code cleaner simple call internal method in different name style
        KYCCommunication.initialRequestPrepareAndSend(docFront: docFront,
                                                      documentBack:docBack,
                                                      selfie: selfie,
                                                      completionHandler: handler)
        
    }
    
    // MARK: - Private Helpers - Initial request
    
    /**
     Starts the first verification step with the verification backend.
     
     @param docFront Front side of the document.
     @param docBack Back side of the document.
     @param selfie Selfie image.
     @param handler Callback.
     */
    private class func initialRequestPrepareAndSend(docFront: Data!,
                                                    documentBack docBack: Data!,
                                                    selfie: Data!,
                                                    completionHandler handler: @escaping KYCResponseHandler) {
        // Prepare session.
        let session = KYCSession(urlBase: CFG_IDCLOUD_BASE_URL, portrait: selfie, andHandler: handler)
        
        // Build and possible send initial request.
        KYCCommunication.initialRequestCreateJSON(docFront: docFront, documentBack: docBack, selfie: selfie) { (request: URLRequest?, error: Error?) in
            if error == nil {
                // Execute request.
                KYCCommunication.createUrlSession().dataTask(with: request!) { (data: Data?, response: URLResponse?, error: Error!) in
                    // Something went wrong during communication. Return error from SDK.
                    if (error != nil) {
                        session.handleError(error.localizedDescription)
                        return
                    }
                    
                    //Parse server response, update session id and check possible errors.
                    if (session.parseResultAndHandleErrors(data) != nil) {
                        // Continue with verify status. We can call it directly without delay. Acuant is fast.
                        DispatchQueue.main.async {
                            KYCCommunication.perform(#selector(KYCCommunication.verifyDocumentPrepareAndSend(session:)), with: session)
                        }
                    }
                }.resume()
            } else {
                // Failed to build initial request.
                session.handleError(error!.localizedDescription)
            }
        }
    }
    
    /**
     Creates the HTTP JSON body for the first verification step.
     
     @param docFront Front side of document.
     @param docBack Back side of document.
     @param selfie Selfie image.
     @param handler Callback.
     */
    private class func initialRequestCreateJSON(docFront: Data!, documentBack docBack: Data!, selfie: Data!, handler: RequestBuilder) {
        // Input is object containing document and optionaly face.
        var input = [String: Any]()
        input["captureMethod"] = "SDK"
        if (docFront != nil) {
            input["frontWhiteImage"] = docFront.base64EncodedString(options: [])
        }
        if (docBack != nil) {
            input["backWhiteImage"] = docBack.base64EncodedString(options: [])
        }
        
        // Optional values for faster evaluation.
        
        // Value: "type"
        // Description: Document type.
        // Possible values are: "Passport", "ID", "DL", "ResidencePermit", "HealthCard", "VISA", "Other"
        
        // Value: "size"
        // Description: Document size.
        // Possible values are: "TD1", "TD2", "TD3"
        
        // Build final JSON.
        
        var json = KYCCommunication.createMassageBase(selfie: (selfie != nil))
        json["input"] = input
        
        do {
            let requestData = try JSONSerialization.data(withJSONObject: json, options: [])
            // Build request.
            var request = URLRequest(url: URL(string: CFG_IDCLOUD_BASE_URL)!)
            request.httpMethod  = "POST"
            request.httpBody    = requestData
            
            // Return complete request
            handler(request, nil)
        } catch let error {
            // Something went wrong during JSON serialization.
            handler(nil, error)
        }
    }
    
    // MARK: - Private Helpers - Verify Document
    
    /**
     Starts the second verification step with the verification backend - document verification.
     
     @param session Session.
     */
    @objc private class func verifyDocumentPrepareAndSend(session: KYCSession) {
        do {
            var request = URLRequest(url: session.urlDocument())
            request.httpMethod = "PATCH"
            request.httpBody = try KYCCommunication.verifyDocumentCreateJSON(isPortraitIncluded: (session.portrait != nil))
            
            // Execute request.
            KYCCommunication.createUrlSession().dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                // Something went wrong during communication. Return error from SDK.
                if (error != nil) {
                    session.handleError(error!.localizedDescription)
                    return
                }
                
                // Parse server response, update session id and check possible errors.
                guard let res = session.parseResultAndHandleErrors(data) else {
                    return
                }
                
                let status = res["status"] as? String
                if (session.portrait != nil) && (status == kStateWaiting) {
                    // Face identification is included in next step.
                    DispatchQueue.main.async {
                        KYCCommunication.perform(#selector(KYCCommunication.verifySelfiePrepareAndSend(response:session:)), with: response, with: session)
                    }
                } else if (session.portrait == nil) && (status == kStateFinished) {
                    if let response = KYCResponse((res["state"] as? [String: Any])?["result"] as? [String: Any]) {
                        session.handleResult(response)
                    } else {
                        session.handleError("Failed to parse server response.")
                    }
                } else {
                    session.handleError("Unexpected server state.")
                }
            }.resume()
        } catch let error {
            // Failed to build verification JSON. No reason to continue.
            session.handleError(error.localizedDescription)
        }
        
    }
    
    /**
     Creates the JSON body for document verification.
     
     @param isPortraitIncluded {@code True} if selfie image is included, else {@code false}.
     */
    private class func verifyDocumentCreateJSON(isPortraitIncluded: Bool) throws -> Data? {
        let json = KYCCommunication.createMassageBase(selfie: isPortraitIncluded)
        return try JSONSerialization.data(withJSONObject: json, options: [])
    }
    
    // MARK: - Private Helpers - Verify selfie
    
    /**
     Starts the third verification step with the verification backend - selfie verification.
     
     @param session Session.
     */
    @objc private class func verifySelfiePrepareAndSend(response: KYCResponse!, session: KYCSession!) {
        do {
            // Build request.
            var request = URLRequest(url: session.urlSelfie())
            request.httpMethod = "PATCH"
            request.httpBody = try KYCCommunication.verifySlefieCreateJSON(portrait: session.portrait!)
            
            // Execute request.
            KYCCommunication.createUrlSession().dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
                // Something went wrong during communication. Return error from SDK.
                if (error != nil) {
                    session.handleError(error!.localizedDescription)
                    return
                }
                
                // Parse server response, update session id and check possible errors.
                guard let res = session.parseResultAndHandleErrors(data) else {
                    return
                }
                
                if res["status"] as? String == kStateFinished {
                    if let response = KYCResponse((res["state"] as? [String: Any])?["result"] as? [String: Any]) {
                        session.handleResult(response)
                    } else {
                        session.handleError("Failed to parse server response.")
                    }
                } else {
                    // Unknown state. Not handled response type.
                    session.handleError("Unexpected server response.")
                }
            }).resume()
        } catch let error {
            // Failed to build verification JSON. No reason to continue.
            session.handleError(error.localizedDescription)
        }
    }
    
    /**
     Creates the JSON body for document verification.
     
     @param portrait Selfie image.
     @param error Error object.
     */
    private class func verifySlefieCreateJSON(portrait: Data) throws -> Data? {
        var json = KYCCommunication.createMassageBase(selfie: true)
        
        var input = [String: Any]()
        input["face"] = portrait.base64EncodedString()
        json["input"] = input
        
        return try JSONSerialization.data(withJSONObject: json, options: [])
    }
    
    // MARK: - Private Helpers - Common
    
    /**
     Creates the url session for all verification steps.
     
     @return {@code NSURLSession} for the verification steps.
     */
    private class func createUrlSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "Accept"            : "application/json",
            "Content-Type"      : "application/json",
            "Authorization"     : String(format:"Bearer %@", KYCManager.jsonWebToken()!),
            "X-API-KEY"         : KYCManager.apiKey()
        ]
        return URLSession(configuration: configuration)
    }
    
    /**
     Creates the JSON body based on if the selfie image is included.
     
     @param selfie {@code True} if selfie image is included, else {@code false}.
     
     @return JSON body.
     */
    private class func createMassageBase(selfie:Bool) -> [String: Any] {
        return ["name": selfie ? "Connect_Verify_Document_Face" : "Connect_Verify_Document"]
    }
}
