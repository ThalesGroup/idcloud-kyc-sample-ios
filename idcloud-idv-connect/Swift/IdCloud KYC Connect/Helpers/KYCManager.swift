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

import AcuantImagePreparation
import AcuantCommon
import JWTDecode

typealias OptionArray = [[IdCloudOption]]
typealias FaceIdCompletion = (Bool, String?) -> ()

// KYC Generic values
private let KEY_KYC_ENROLLED        = "KycPreferenceKeyEnrolled"

// GeneralSettings
private let KEY_FACIAL_RECOGNITION = "KycPreferenceKeyFacalRecognition"
private let KEY_JSON_WEB_TOKEN     = "JsonWebToken"

extension Notification.Name {
    static let DataLayerChanged = Notification.Name("DataLayerChanged")
}

class KYCManager : NSObject, InitializationDelegate {
    
    // MARK: - Static Helpers
    
    private (set) var optionCaptions: [String]
    private (set) var options: OptionArray
    var scannedDocFront: Data?
    var scannedDocBack: Data?
    var scannedPortrait: Data?
    
    // MARK: - Life cycle
    
    static let sharedInstance: KYCManager = {
        return KYCManager()
    }()
    
    override init() {
        // Default settings
        UserDefaults.standard.register(defaults: [
            // KYC Generic values
            KEY_KYC_ENROLLED             : NSNumber(booleanLiteral: false),
            
            // GeneralSettings
            KEY_FACIAL_RECOGNITION       : NSNumber(booleanLiteral: true),
            KEY_JSON_WEB_TOKEN           : CFG_JSON_WEB_TOKEN_DEFAULT,
        ])
        
        // Available options in settings menu.
        self.options =
            [
                // GeneralSettings
                [
                    IdCloudOption.checkbox(caption: TRANSLATE("STRING_KYC_OPTION_FACE_REC_CAP"),
                                           description:TRANSLATE("STRING_KYC_OPTION_FACE_REC_DES"),
                                           section:IdCloudOptionSection.general,
                                           methodGet: KYCManager.facialRecognition,
                                           methodSet: KYCManager.setFacialRecognition),
                ],
                
                // Version
                [
                    IdCloudOption.version(caption: TRANSLATE("STRING_KYC_OPTION_VERSION_APP"),
                                          description:Bundle.main.infoDictionary?["CFBundleVersion"] as? String),
                    
                    IdCloudOption.version(caption: TRANSLATE("STRING_KYC_OPTION_VERSION_ACUANT_SDK"),
                                          description:Utils.SDK_VERSION_CODE),
                    
                    IdCloudOption.text(caption: TRANSLATE("STRING_KYC_OPTION_WEB_TOKEN"),
                                       section:IdCloudOptionSection.version,
                                       methodGet:KYCManager.getStoredJWTExpiration),
                    
                    IdCloudOption.button(caption: TRANSLATE("STRING_KYC_OPTION_WEB_TOKEN"),
                                         section: IdCloudOptionSection.version,
                                         method: KYCManager.openJsonWebTokenUpdate),
                    
                    IdCloudOption.button(caption: TRANSLATE("STRING_KYC_OPTION_PRIVACY_POLICY"),
                                         section: IdCloudOptionSection.version,
                                         method: KYCManager.openPrivacyPolicy)
                ],
        ]
        
        // Name of sections in settings menu.
        self.optionCaptions = [
            TRANSLATE("STRING_KYC_OPTION_SECTION_GENERAL"),
            TRANSLATE("STRING_KYC_OPTION_SECTION_VERSION")
        ]
        
        // Initialize acuant. It can load values from plist, but we want o have all configurations on one place.
        let endpoints = Endpoints.newInstance()
        endpoints.frmEndpoint = CFG_ACUANT_FRM_ENDPOINT
        endpoints.idEndpoint = CFG_ACUANT_ASSURE_ID_ENDPOINT
        endpoints.healthInsuranceEndpoint = CFG_ACUANT_MEDISCAN_ENDPOINT
        Credential.setUsername(username: CFG_ACUANT_USERNAME)
        Credential.setPassword(password: CFG_ACUANT_PASSWORD)
        Credential.setSubscription(subscription: CFG_ACUANT_SUBSCRIPTION_ID)
        Credential.setEndpoints(endpoints: endpoints)
        
        super.init()
        
        AcuantImagePreparation.initialize(delegate: self)
    }
    
    // MARK: - Props - Generic values
    
    class func setKycEnrolled(_ kycEnrolled: Bool) {
        //        UserDefaults.standard.set(kycEnrolled, forKey: KEY_KYC_ENROLLED)
    }
    
    class func kycEnrolled() -> Bool {
        return false
        //        UserDefaults.standard.bool(forKey: KEY_KYC_ENROLLED)
    }
    
    // MARK: - Props - GeneralSettings
    
    class func setFacialRecognition(_ facialRecognition: Bool) {
        UserDefaults.standard.set(facialRecognition, forKey: KEY_FACIAL_RECOGNITION)
    }
    
    class func facialRecognition() -> Bool {
        return UserDefaults.standard.bool(forKey: KEY_FACIAL_RECOGNITION)
    }
    
    // MARK: - Private Helpers
    
    class private func openPrivacyPolicy() {
        let viewController = UIApplication.shared.windows.first!.rootViewController
        viewController?.present(KYCPrivacyPolicyViewController.viewController(), animated: true, completion: nil)
    }
    
    class private func openJsonWebTokenUpdate() {
        // Main alert builder.
        let alert = UIAlertController(title: TRANSLATE("STRING_JSON_WEB_TOKEN_CAP"),
                                      message: TRANSLATE("STRING_JSON_WEB_TOKEN_DES"),
                                      preferredStyle: UIAlertController.Style.alert)
        
        alert.addTextField { (textfield: UITextField) in
            textfield.placeholder = TRANSLATE("STRING_JSON_WEB_TOKEN_PLACEHOLDER")
        }
        
        // Add ok button with handler.
        alert.addAction(UIAlertAction(title: TRANSLATE("STRING_COMMON_OK"), style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) in
            if (self.setJsonWebToken(alert.textFields?.first?.text ?? "")) {
                NotificationCenter.default.post(name: NSNotification.Name.DataLayerChanged, object: nil)
            } else {
                notifyDisplay(TRANSLATE("STRING_JSON_WEB_TOKEN_INVALID"), type: NotifyType.error)
            }
        }))
        
        // Add cancel button.
        alert.addAction(UIAlertAction(title: TRANSLATE("STRING_COMMON_CANCEL"), style: UIAlertAction.Style.cancel, handler: nil))
        
        // Present dialog.
        let viewController = UIApplication.shared.windows.first!.rootViewController
        viewController?.present(alert, animated: true, completion: nil)
    }
    
    class private func setJsonWebToken(_ jsonWebToken: String) -> Bool {
        // Do not store invalid token
        let retValue = KYCManager.getJWTExpiration(jsonWebToken) != nil
        if retValue {
            UserDefaults.standard.set(jsonWebToken, forKey: KEY_JSON_WEB_TOKEN)
        }
        
        return retValue
    }
    
    class private func getStoredJWTExpiration() -> String {
        return KYCManager.getJWTExpiration(KYCManager.jsonWebToken())
    }
    
    class private func getJWTExpiration(_ token: String) -> String! {
        do {
            let jsonToken:_JWT? = try _JWT.decode(jwt: token)
            if let expires = jsonToken?.expiresAt {
                return DateFormatter.localizedString(from: expires,
                                                     dateStyle: DateFormatter.Style.short,
                                                     timeStyle: DateFormatter.Style.full)
            } else {
                return nil
            }
        } catch _ {
            return nil
        }
    }
    
    class func jsonWebToken() -> String {
        return UserDefaults.standard.string(forKey: KEY_JSON_WEB_TOKEN)!
    }
    
    // MARK:  - InitializationDelegate 
    func initializationFinished(error: AcuantError?) {
        if let errDest = error?.errorDescription {
            notifyDisplay(errDest, type: NotifyType.error)
        }
    }
}
