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
private let KEY_MAX_PICTURE_WIDTH  = "MaxPictureWidth"
private let KEY_JSON_WEB_TOKEN     = "JsonWebTokenV2"
private let KEY_API_KEY            = "ApiKeyV2"

// Acuant facial recognition endpoint url.
private let CFG_ACUANT_FRM_ENDPOINT = "https://frm.acuant.eu"

// Acuant Document Authentication & Identity Verification endpoint url.
private let CFG_ACUANT_ASSURE_ID_ENDPOINT = "https://services.assureid.eu"

// Acuant mediscan endpoint url.
private let CFG_ACUANT_MEDISCAN_ENDPOINT = "https://medicscan.acuant.eu"

extension Notification.Name {
    static let DataLayerChanged = Notification.Name("DataLayerChanged")
}

class KYCManager : NSObject, InitializationDelegate {
    
    // MARK: - Static Helpers
    
    private (set) var optionCaptions: [String]!
    private (set) var options: OptionArray!
    var scannedDocFront: Data?
    var scannedDocBack: Data?
    var scannedPortrait: Data?
    
    // MARK: - Life cycle
    
    static let sharedInstance: KYCManager = {
        return KYCManager()
    }()
    
    override init() {
        super.init()
        
        // Default settings
        UserDefaults.standard.register(defaults: [
            // KYC Generic values
            KEY_KYC_ENROLLED             : NSNumber(booleanLiteral: false),
            
            // GeneralSettings
            KEY_MAX_PICTURE_WIDTH        : NSNumber(integerLiteral: 1024),
            KEY_FACIAL_RECOGNITION       : NSNumber(booleanLiteral: true)
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
                    
                    IdCloudOption.button(caption: TRANSLATE("STRING_KYC_OPTION_QR_CODE"),
                                         section: IdCloudOptionSection.version,
                                         method: displayQRcodeScannerForInit),

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
    
    // MARK: - Public API
    
    func displayQRcodeScannerForInit() {
        // Display QR code reader with current view as delegate.
        let viewController = UIApplication.shared.windows.first!.rootViewController
        viewController?.present(IdCloudQrCodeReader.readerWithDelegate(delegate: self), animated: true, completion: nil)
    }
    
    // MARK: - Private Helpers
    
    class private func openPrivacyPolicy() {
        let viewController = UIApplication.shared.windows.first!.rootViewController
        viewController?.present(KYCPrivacyPolicyViewController.viewController(), animated: true, completion: nil)
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
        return KYCManager.getJWTExpiration(KYCManager.jsonWebToken()) ?? "JWT not set"
    }
    
    class private func getJWTExpiration(_ token: String?) -> String? {
        do {
            let jsonToken:_JWT? = try _JWT.decode(jwt: token ?? "")
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
    
    class func jsonWebToken() -> String? {
        return UserDefaults.standard.string(forKey: KEY_JSON_WEB_TOKEN)
    }
    
    class private func setApiKey(_ apiKey: String) {
        UserDefaults.standard.set(apiKey, forKey: KEY_API_KEY)
    }
    
    class func apiKey() -> String {
        return UserDefaults.standard.string(forKey: KEY_API_KEY)!
    }
    
    class private func setMaxImageWidth(_ value: Int) {
        UserDefaults.standard.set(value, forKey: KEY_MAX_PICTURE_WIDTH)
    }
    
    class func maxImageWidth() -> Int {
        return UserDefaults.standard.integer(forKey: KEY_MAX_PICTURE_WIDTH)
    }
    
    // MARK:  - InitializationDelegate
    
    func initializationFinished(error: AcuantError?) {
        if let errDest = error?.errorDescription {
            notifyDisplay(errDest, type: NotifyType.error)
        }
    }
}

// MARK: - IdCloudQrCodeReaderDelegate

extension KYCManager: IdCloudQrCodeReaderDelegate {
    func onQRCodeProvided(sender: IdCloudQrCodeReader, qrCode: String) {
        // QR Code format is "kyc:<apikey>:<jwt>"
        let elements = qrCode.components(separatedBy: ":")
        if elements.count == 3 && elements[0] == "kyc" {
            if elements[1].isEmpty || elements[2].isEmpty {
                notifyDisplay(TRANSLATE("STRING_QR_CODE_ERROR_INVALID_DATA"), type: NotifyType.error)
            } else if !KYCManager.setJsonWebToken(elements[2]) {
                notifyDisplay(TRANSLATE("STRING_QR_CODE_ERROR_INVALID_JWT"), type: NotifyType.error)
            } else {
                // JWT is already set by previous IF case, now we have to store rest.
                KYCManager.setApiKey(elements[1])
                // Notify UI to reload visuals.
                NotificationCenter.default.post(name: NSNotification.Name.DataLayerChanged, object: nil)
                // Hide scanner.
                let viewController = UIApplication.shared.windows.first!.rootViewController
                viewController?.dismiss(animated: true, completion: nil)
                // Display status information.
                notifyDisplay(TRANSLATE("STRING_QR_CODE_INFO_DONE"), type: NotifyType.info)
            }
        } else {
            notifyDisplay(TRANSLATE("STRING_QR_CODE_ERROR_FAILED"), type: NotifyType.error)
        }
    }
}
