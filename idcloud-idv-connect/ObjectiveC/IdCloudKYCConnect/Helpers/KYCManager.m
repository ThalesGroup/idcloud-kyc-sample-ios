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

#import "KYCManager.h"
#import <AcuantImagePreparation/AcuantImagePreparation.h>
#import <AcuantCommon/AcuantCommon-Swift.h>
#import "AppDelegate.h"
#import "KYCPrivacyPolicyViewController.h"
#import "SideMenuViewController.h"
#import "KYCCommunication.h"
#import <JWTDecode/JWTDecode-Swift.h>
#import "IdCloudQrCodeReader.h"

// KYC Generic values
#define KEY_KYC_ENROLLED            @"KycPreferenceKeyEnrolled"

// GeneralSettings
#define KEY_FACIAL_RECOGNITION      @"KycPreferenceKeyFacalRecognition"
#define KEY_MAX_PICTURE_WIDTH       @"MaxPictureWidth"
#define KEY_JSON_WEB_TOKEN          @"JsonWebTokenV2"
#define KEY_API_KEY                 @"ApiKeyV2"

// Acuant facial recognition endpoint url.
#define CFG_ACUANT_FRM_ENDPOINT @"https://frm.acuant.eu"

// Acuant Document Authentication & Identity Verification endpoint url.
#define CFG_ACUANT_ASSURE_ID_ENDPOINT @"https://services.assureid.eu"

// Acuant mediscan endpoint url.
#define CFG_ACUANT_MEDISCAN_ENDPOINT @"https://medicscan.acuant.eu"

static KYCManager *sInstance = nil;

@interface KYCManager() <InitializationDelegate, IdCloudQrCodeReaderDelegate>

@end

@implementation KYCManager

// MARK: - Static Helpers

+ (instancetype)sharedInstance
{
    if (!sInstance) {
        sInstance = [[KYCManager alloc] init];
    }
    
    return sInstance;
}

+ (void)end {
    sInstance = nil;
}

// MARK: - Life cycle

- (instancetype)init {
    if (self = [super init]) {
                
        // Default settings
        [[NSUserDefaults standardUserDefaults] registerDefaults:
         @{
             // KYC Generic values
             KEY_KYC_ENROLLED             : [NSNumber numberWithBool:NO],
             
             // GeneralSettings
             KEY_MAX_PICTURE_WIDTH        : [NSNumber numberWithInt:1024],
             KEY_FACIAL_RECOGNITION       : [NSNumber numberWithBool:YES],
         }];
        
        // Available options in settings menu.
        _options =
        @[
            // GeneralSettings
            @[
                [IdCloudOption checkbox:TRANSLATE(@"STRING_KYC_OPTION_FACE_REC_CAP")
                            description:TRANSLATE(@"STRING_KYC_OPTION_FACE_REC_DES")
                                section:IdCloudOptionSectionGeneral
                                 target:self
                            selectorGet:@selector(facialRecognition)
                            selectorSet:@selector(setFacialRecognition:)],
            ],
            
            // Version
            @[
                [IdCloudOption version:TRANSLATE(@"STRING_KYC_OPTION_VERSION_APP")
                           description:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]],
                
                [IdCloudOption version:TRANSLATE(@"STRING_KYC_OPTION_VERSION_ACUANT_SDK")
                           description:[Utils SDK_VERSION_CODE]],
                
                [IdCloudOption text:TRANSLATE(@"STRING_KYC_OPTION_WEB_TOKEN")
                            section:IdCloudOptionSectionVersion
                             target:self selectorGet:@selector(getStoredJWTExpiration)],
                
                [IdCloudOption button:TRANSLATE(@"STRING_KYC_OPTION_QR_CODE")
                              section:IdCloudOptionSectionVersion
                               target:self
                             selector:@selector(displayQRcodeScannerForInit)],
                
                [IdCloudOption button:TRANSLATE(@"STRING_KYC_OPTION_PRIVACY_POLICY")
                              section:IdCloudOptionSectionVersion
                               target:self
                             selector:@selector(openPrivacyPolicy)]
            ],
        ];        
        
        // Name of sections in settings menu.
        _optionCaptions = @[
            TRANSLATE(@"STRING_KYC_OPTION_SECTION_GENERAL"),
            TRANSLATE(@"STRING_KYC_OPTION_SECTION_VERSION")
        ];
    }
    
    // Initialize acuant. It can load values from plist, but we want o have all configurations on one place.
    Endpoints *endpoints =  [Endpoints newInstance];
    [endpoints setFrmEndpoint:CFG_ACUANT_FRM_ENDPOINT];
    [endpoints setIdEndpoint:CFG_ACUANT_ASSURE_ID_ENDPOINT];
    [endpoints setHealthInsuranceEndpoint:CFG_ACUANT_MEDISCAN_ENDPOINT];
    [Credential setUsernameWithUsername:CFG_ACUANT_USERNAME];
    [Credential setPasswordWithPassword:CFG_ACUANT_PASSWORD];
    [Credential setSubscriptionWithSubscription:CFG_ACUANT_SUBSCRIPTION_ID];
    [Credential setEndpointsWithEndpoints:endpoints];
    
    [AcuantImagePreparation initializeWithDelegate:self];
        
    return self;
}

// MARK: - Props - Generic values

- (void)setKycEnrolled:(BOOL)kycEnrolled {
    //[[NSUserDefaults standardUserDefaults] setBool:kycEnrolled forKey:KEY_KYC_ENROLLED];
}

- (BOOL)kycEnrolled {
    return NO;
    //    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_KYC_ENROLLED];
}

// MARK: - Props - GeneralSettings

- (void)setFacialRecognition:(BOOL)facialRecognition {
    [[NSUserDefaults standardUserDefaults] setBool:facialRecognition forKey:KEY_FACIAL_RECOGNITION];
}

- (BOOL)facialRecognition {
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_FACIAL_RECOGNITION];
}

// MARK: - Public API

- (void)displayQRcodeScannerForInit {
    // Display QR code reader with current view as delegate.
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.rootViewController presentViewController:[IdCloudQrCodeReader readerWithDelegate:self] animated:YES completion:nil];
}

- (void)updateRootViewController {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.rootViewController switchToViewController:[SideMenuViewController kycVC]];
}

// MARK: - Private Helpers

- (void)openPrivacyPolicy {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.rootViewController.currentVC  presentViewController:[KYCPrivacyPolicyViewController viewController] animated:YES completion:nil];
}

- (BOOL)setJsonWebToken:(NSString *)jsonWebToken {
    // Do not store invalid token
    BOOL retValue = [self getJWTExpiration:jsonWebToken];
    if (retValue) {
        [[NSUserDefaults standardUserDefaults] setObject:jsonWebToken forKey:KEY_JSON_WEB_TOKEN];
    }
    
    return retValue;
}

- (NSString *)getStoredJWTExpiration {
    return [self getJWTExpiration:[self jsonWebToken]];
}

- (NSString *)getJWTExpiration:(NSString *)token {
    NSError *error;
    A0JWT *jsonToken = [A0JWT decodeWithJwt:token error:&error];
    if (!error && jsonToken.expiresAt) {
        return [NSDateFormatter localizedStringFromDate:jsonToken.expiresAt
                                              dateStyle:NSDateFormatterShortStyle
                                              timeStyle:NSDateFormatterFullStyle];
    } else {
        return nil;
    }
}

- (NSString *)jsonWebToken {
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_JSON_WEB_TOKEN];
}

- (void)setApiKey:(NSString *)apiKey {
    [[NSUserDefaults standardUserDefaults] setObject:apiKey forKey:KEY_API_KEY];
}

- (NSString *)apiKey {
    return [[NSUserDefaults standardUserDefaults] stringForKey:KEY_API_KEY];
}

- (void)setMaxImageWidth:(NSInteger)value {
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:KEY_MAX_PICTURE_WIDTH];
}

- (NSInteger)maxImageWidth {
    return [[NSUserDefaults standardUserDefaults] integerForKey:KEY_MAX_PICTURE_WIDTH];
}

// MARK:  - InitializationDelegate 

- (void)initializationFinishedWithError:(AcuantError *)error {
    if (error) {
        notifyDisplay(error.errorDescription, NotifyTypeError);
    }
}

// MARK: - IdCloudQrCodeReaderDelegate

- (void)onQRCodeProvided:(IdCloudQrCodeReader *)sender qrCode:(NSString *)qrCode {
    // QR Code format is "kyc:<apikey>:<jwt>"
    NSArray<NSString *> *elements = [qrCode componentsSeparatedByString:@":"];
    if (elements.count == 3 && [elements[0] isEqualToString:@"kyc"]) {
        if (!elements[1].length || !elements[2].length) {
            notifyDisplay(TRANSLATE(@"STRING_QR_CODE_ERROR_INVALID_DATA"), NotifyTypeError);
        } else if (![self setJsonWebToken:elements[2]]) {
            notifyDisplay(TRANSLATE(@"STRING_QR_CODE_ERROR_INVALID_JWT"), NotifyTypeError);
        } else {
            // JWT is already set by previous IF case, now we have to store rest.
            [self setApiKey:elements[1]];
            // Notify UI to reload visuals.
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDataLayerChanged object:nil];
            // Hide scanner.
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.rootViewController dismissViewControllerAnimated:YES completion:nil];
            // Display status information.
            notifyDisplay(TRANSLATE(@"STRING_QR_CODE_INFO_DONE"), NotifyTypeInfo);
        }
    } else {
        notifyDisplay(TRANSLATE(@"STRING_QR_CODE_ERROR_FAILED"), NotifyTypeError);
    }
}

@end
