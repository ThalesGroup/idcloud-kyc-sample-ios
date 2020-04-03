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
#import "AppDelegate.h"
#import "SideMenuViewController.h"
#import "KYCPrivacyPolicyViewController.h"
#import <JWTDecode/JWTDecode-Swift.h>
#import "IdCloudQrCodeReader.h"


// KYC Generic values
#define KEY_KYC_ENROLLED            @"KycPreferenceKeyEnrolled"

// GeneralSettings
#define KEY_FACIAL_RECOGNITION      @"KycPreferenceKeyFacalRecognition"

// RiskManagement
#define KEY_EXPIRATION_DATE         @"KycPreferenceKeyExpirationDate"

// DocumentScan
#define KEY_MANUAL_SCAN             @"KycPreferenceKeyManualScan"
#define KEY_AUTOMATIC_TYPE          @"KycPreferenceKeyAutomaticType"
#define KEY_CAMERA_OTIENTATION      @"KycPreferenceKeyCameraOrientation"
#define KEY_DETECTION_ZONE          @"KycPreferenceKeyDetectionZone"
#define KEY_BW_PHOTO_COPY_QA        @"KycPreferenceKeyBwPhotoCopyQA"

// FaceId
#define KEY_FACE_LIVENESS_MODE      @"KycPreferenceKeyLivenessMode"
#define KEY_FACE_LIVENESS_THRESHOLD @"KycPreferenceKeyLivenessThreshold"
#define KEY_FACE_QUALITY_THRESHOLD  @"KycPreferenceKeyQualityThreshold"
#define KEY_FACE_BLINK_TIMEOUT      @"KycPreferenceKeyBlinkTimeout"

#define KEY_MAX_PICTURE_WIDTH       @"MaxPictureWidth"
#define KEY_JSON_WEB_TOKEN          @"JsonWebTokenV2"
#define KEY_API_KEY                 @"ApiKeyV2"


static KYCManager *sInstance = nil;

@interface KYCManager() <IdCloudQrCodeReaderDelegate>

@property (nonatomic, copy)     FaceIdCompletion    faceCompletion;
@property (nonatomic, strong)   NSError             *faceIdInitError;
@property (nonatomic, assign)   BOOL                faceIdInitSuccess;

@end

@implementation KYCManager

// MARK: - Static Helpers

+ (instancetype)sharedInstance {
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
             
             // RiskManagement
             KEY_EXPIRATION_DATE          : [NSNumber numberWithBool:NO],
             
             // DocumentScan
             KEY_MANUAL_SCAN              : [NSNumber numberWithBool:NO],
             KEY_AUTOMATIC_TYPE           : [NSNumber numberWithBool:YES],
             KEY_CAMERA_OTIENTATION       : [NSNumber numberWithBool:YES],
             KEY_DETECTION_ZONE           : [NSNumber numberWithBool:NO],
             KEY_BW_PHOTO_COPY_QA         : [NSNumber numberWithBool:NO],
             
             // FaceId
             KEY_FACE_LIVENESS_MODE       : [NSNumber numberWithInteger:FaceLivenessModePassive],
             KEY_FACE_LIVENESS_THRESHOLD  : [NSNumber numberWithInteger:0],
             KEY_FACE_QUALITY_THRESHOLD   : [NSNumber numberWithInteger:50],
             KEY_FACE_BLINK_TIMEOUT       : [NSNumber numberWithInteger:15],
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
            
            // RiskManagement
            @[
                [IdCloudOption checkbox:TRANSLATE(@"STRING_KYC_OPTION_IGNORE_DATE_CAP")
                            description:TRANSLATE(@"STRING_KYC_OPTION_IGNORE_DATE_DES")
                                section:IdCloudOptionSectionGeneral
                                 target:self
                            selectorGet:@selector(ignoreExpirationDate)
                            selectorSet:@selector(setIgnoreExpirationDate:)],
            ],
            
            // DocumentScan
            @[
                [IdCloudOption checkbox:TRANSLATE(@"STRING_KYC_OPTION_MANUAL_MODE_CAP")
                            description:TRANSLATE(@"STRING_KYC_OPTION_MANUAL_MODE_DES")
                                section:IdCloudOptionSectionIdentityDocumentScan
                                 target:self
                            selectorGet:@selector(manualScan)
                            selectorSet:@selector(setManualScan:)],
                
                [IdCloudOption checkbox:TRANSLATE(@"STRING_KYC_OPTION_AUTO_DETECTION_CAP")
                            description:TRANSLATE(@"STRING_KYC_OPTION_AUTO_DETECTION_DES")
                                section:IdCloudOptionSectionIdentityDocumentScan
                                 target:self
                            selectorGet:@selector(automaticTypeDetection)
                            selectorSet:@selector(setAutomaticTypeDetection:)],
                
                [IdCloudOption checkbox:TRANSLATE(@"STRING_KYC_OPTION_CAMERA_ORIENT_CAP")
                            description:TRANSLATE(@"STRING_KYC_OPTION_CAMERA_ORIENT_DES")
                                section:IdCloudOptionSectionIdentityDocumentScan
                                 target:self
                            selectorGet:@selector(cameraOrientation)
                            selectorSet:@selector(setCameraOrientation:)],
                
                [IdCloudOption checkbox:TRANSLATE(@"STRING_KYC_OPTION_DETECTION_ZONE_CAP")
                            description:TRANSLATE(@"STRING_KYC_OPTION_DETECTION_ZONE_DES")
                                section:IdCloudOptionSectionIdentityDocumentScan
                                 target:self
                            selectorGet:@selector(idCaptureDetectionZone)
                            selectorSet:@selector(setIdCaptureDetectionZone:)],
                
                [IdCloudOption checkbox:TRANSLATE(@"STRING_KYC_OPTION_BW_PHOTO_COPY_CAP")
                            description:TRANSLATE(@"STRING_KYC_OPTION_BW_PHOTO_COPY_DES")
                                section:IdCloudOptionSectionIdentityDocumentScan
                                 target:self
                            selectorGet:@selector(bwPhotoCopyQA)
                            selectorSet:@selector(setBwPhotoCopyQA:)],
            ],
            // Face Id
            @[
                [IdCloudOption segment:TRANSLATE(@"STRING_KYC_OPTION_FACE_LIVENESS_MODE_CAP")
                               section:IdCloudOptionSectionFaceCapture
                               options:@{
                                   [NSNumber numberWithInteger:FaceLivenessModePassive]: TRANSLATE(@"STRING_KYC_OPTION_FACE_LIVENESS_MODE_PASSIVE"),
                                   [NSNumber numberWithInteger:FaceLivenessModeActive]: TRANSLATE(@"STRING_KYC_OPTION_FACE_LIVENESS_MODE_ACTIVE")
                               }
                                target:self
                           selectorGet:@selector(faceLivenessMode)
                           selectorSet:@selector(setFaceLivenessMode:)],
                [IdCloudOption number:TRANSLATE(@"STRING_KYC_OPTION_FACE_QUALITY_THRESHOLD_CAP")
                          description:TRANSLATE(@"STRING_KYC_OPTION_FACE_QUALITY_THRESHOLD_DES")
                              section:IdCloudOptionSectionFaceCapture
                               target:self
                          selectorGet:@selector(faceQualityThreshold)
                          selectorSet:@selector(setFaceQualityThreshold:)
                             minValue:0 maxValue:100],
                [IdCloudOption number:TRANSLATE(@"STRING_KYC_OPTION_FACE_LIVENESS_THRESHOLD_CAP")
                          description:TRANSLATE(@"STRING_KYC_OPTION_FACE_LIVENESS_THRESHOLD_DES")
                              section:IdCloudOptionSectionFaceCapture
                               target:self
                          selectorGet:@selector(faceLivenessThreshold)
                          selectorSet:@selector(setFaceLivenessThreshold:)
                             minValue:0 maxValue:100],
                [IdCloudOption number:TRANSLATE(@"STRING_KYC_OPTION_FACE_BLINK_TIMEOUT_CAP")
                          description:TRANSLATE(@"STRING_KYC_OPTION_FACE_BLINK_TIMEOUT_DES")
                              section:IdCloudOptionSectionFaceCapture
                               target:self
                          selectorGet:@selector(faceBlinkTimeout)
                          selectorSet:@selector(setFaceBlinkTimeout:)
                             minValue:0 maxValue:100],
            ],
            
            
            // Version
            @[
                [IdCloudOption version:TRANSLATE(@"STRING_KYC_OPTION_VERSION_APP")
                           description:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]],
                
                [IdCloudOption version:TRANSLATE(@"STRING_KYC_OPTION_VERSION_ID_SDK")
                           description:[[[NSBundle bundleForClass:Document.class] infoDictionary] objectForKey:@"CFBundleShortVersionString"]],
                
                [IdCloudOption version:TRANSLATE(@"STRING_KYC_OPTION_VERSION_LIVENESS")
                           description:[[[NSBundle bundleForClass:FaceCaptureManager.class] infoDictionary] objectForKey:@"CFBundleShortVersionString"]],
                
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
            TRANSLATE(@"STRING_KYC_OPTION_SECTION_RISK"),
            TRANSLATE(@"STRING_KYC_OPTION_SECTION_SCAN"),
            TRANSLATE(@"STRING_KYC_OPTION_SECTION_FACEID"),
            TRANSLATE(@"STRING_KYC_OPTION_SECTION_VERSION")
        ];
        
        // Do any additional setup after loading the view.
        [self initFaceId];
    }
    
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

// MARK: - Props - RiskManagement

- (void)setIgnoreExpirationDate:(BOOL)ignoreExpirationDate {
    [[NSUserDefaults standardUserDefaults] setBool:ignoreExpirationDate forKey:KEY_EXPIRATION_DATE];
}

- (BOOL)ignoreExpirationDate {
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_EXPIRATION_DATE];
}

// MARK: - Props - DocumentScan

- (void)setManualScan:(BOOL)manualScan {
    [[NSUserDefaults standardUserDefaults] setBool:manualScan forKey:KEY_MANUAL_SCAN];
}

- (BOOL)manualScan {
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_MANUAL_SCAN];
}

- (void)setAutomaticTypeDetection:(BOOL)automaticTypeDetection {
    [[NSUserDefaults standardUserDefaults] setBool:automaticTypeDetection forKey:KEY_AUTOMATIC_TYPE];
}

- (BOOL)automaticTypeDetection {
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_AUTOMATIC_TYPE];
}

- (void)setCameraOrientation:(BOOL)cameraOrientation {
    [[NSUserDefaults standardUserDefaults] setBool:cameraOrientation forKey:KEY_CAMERA_OTIENTATION];
}

- (BOOL)cameraOrientation {
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_CAMERA_OTIENTATION];
}

- (void)setIdCaptureDetectionZone:(BOOL)idCaptureDetectionZone {
    [[NSUserDefaults standardUserDefaults] setBool:idCaptureDetectionZone forKey:KEY_DETECTION_ZONE];
}

- (BOOL)idCaptureDetectionZone {
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_DETECTION_ZONE];
}

- (void)setBwPhotoCopyQA:(BOOL)bwPhotoCopyQA {
    [[NSUserDefaults standardUserDefaults] setBool:bwPhotoCopyQA forKey:KEY_BW_PHOTO_COPY_QA];
}

- (BOOL)bwPhotoCopyQA {
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_BW_PHOTO_COPY_QA];
}


// MARK: - Props - FaceId

- (void)setFaceLivenessMode:(NSInteger)faceLivenessMode {
    [[NSUserDefaults standardUserDefaults] setInteger:faceLivenessMode forKey:KEY_FACE_LIVENESS_MODE];
}

- (NSInteger)faceLivenessMode {
    return [[NSUserDefaults standardUserDefaults] integerForKey:KEY_FACE_LIVENESS_MODE];
}

- (void)setFaceLivenessThreshold:(NSInteger)faceLivenessThreshold {
    [[NSUserDefaults standardUserDefaults] setInteger:faceLivenessThreshold forKey:KEY_FACE_LIVENESS_THRESHOLD];
}

- (NSInteger)faceLivenessThreshold {
    return [[NSUserDefaults standardUserDefaults] integerForKey:KEY_FACE_LIVENESS_THRESHOLD];
}

- (void)setFaceQualityThreshold:(NSInteger)faceQualityThreshold {
    [[NSUserDefaults standardUserDefaults] setInteger:faceQualityThreshold forKey:KEY_FACE_QUALITY_THRESHOLD];
}

- (NSInteger)faceQualityThreshold {
    return [[NSUserDefaults standardUserDefaults] integerForKey:KEY_FACE_QUALITY_THRESHOLD];
}

- (void)setFaceBlinkTimeout:(NSInteger)faceBlinkTimeout {
    [[NSUserDefaults standardUserDefaults] setInteger:faceBlinkTimeout forKey:KEY_FACE_BLINK_TIMEOUT];
}

- (NSInteger)faceBlinkTimeout {
    return [[NSUserDefaults standardUserDefaults] integerForKey:KEY_FACE_BLINK_TIMEOUT];
}

// MARK: - Public API

- (void)displayQRcodeScannerForInit {
    // Display QR code reader with current view as delegate.
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.rootViewController presentViewController:[IdCloudQrCodeReader readerWithDelegate:self] animated:YES completion:nil];
}

- (NSArray<KYCScannerStep *> *)scanningStepsWithType:(KYCDocumentType)type {
    switch (type) {
        case KYCDocumentTypeIdCard:
            return [self scanningStepsIdCard];
        case KYCDocumentTypePassport:
        case KYCDocumentTypePassportBiometric:
            return [self scanningStepsPassport];
    }
    
    // Unknown document type.
    assert(false);
    return nil;
}

- (void)initializeFaceIdLicense:(FaceIdCompletion)completion {
    if (_faceIdInitSuccess) {
        // Successfull init already done.
        completion(YES, nil);
    } else {
        // If it's not yet inited. Wait for initializeWithProductKey.
        self.faceCompletion = completion;
        
        // Something went wrong during init. Try it again.
        if (!_faceIdInitSuccess && _faceIdInitError) {
            [self initFaceId];
        }
    }
}

- (void)updateRootViewController {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.rootViewController switchToViewController:[SideMenuViewController kycVC]];
}

// MARK: - Private Helpers

- (void)initFaceId {
    _faceIdInitSuccess  = NO;
    _faceIdInitError    = nil;
    [[LicenseManager sharedInstance] initializeWithProductKey:CFG_PRODUCT_KEY andServerUrl:CFG_SERVER_URL
                                               andCompletion :^(BOOL success, NSError *error) {
        // Someone is waiting for init process. Notify it.
        if (self.faceCompletion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.faceCompletion(success, error);
                self.faceCompletion = nil;
            });
            
        }
        // Save init response for later use.
        self.faceIdInitSuccess   = success;
        self.faceIdInitError     = error;
    }]; // Important: init the face capture before using it
}

- (NSArray<KYCScannerStep *> *)scanningStepsIdCard {
    NSMutableArray<KYCScannerStep *> *retValue = [NSMutableArray array];
    
    NSString *baseKey = @"STRING_KYC_DOC_SCAN_STEP_";
    
    [retValue addObject:({
        KYCScannerStep *stepToAdd       = [KYCScannerStep stepWithType:KYCStepTypeCapture];
        stepToAdd.sideBarIcon           = @"KYC_DocStep_IdCardFront";
        stepToAdd.overlayIcon           = @"KYC_DocStep_IdCardFront";
        stepToAdd.sideBarCaption        = TRANSLATE(([baseKey stringByAppendingString:@"01"]));
        stepToAdd.overlayCaptionTop     = TRANSLATE(@"STRING_KYC_DOC_SCAN_DETAIL_TOP");
        stepToAdd.overlayCaptionBottom  = TRANSLATE(@"STRING_KYC_DOC_SCAN_DETAIL_BOTTOM");
        stepToAdd;
    })];
    
    [retValue addObject:({
        KYCScannerStep *stepToAdd       = [KYCScannerStep stepWithType:KYCStepTypeTurnOver];
        stepToAdd.sideBarIcon           = nil;
        stepToAdd.overlayIcon           = @"KYC_DocStep_IdCardFront";
        stepToAdd.overlayAnimation      = KYCStepAnimationFlipHorizontally;
        stepToAdd.overlayAnimationImage = @"KYC_DocStep_IdCardBack";
        stepToAdd.sideBarCaption        = TRANSLATE(([baseKey stringByAppendingString:@"02"]));
        stepToAdd.overlayCaptionTop     = TRANSLATE(@"STRING_KYC_DOC_TURN_DETAIL_TOP");
        stepToAdd.overlayCaptionBottom  = TRANSLATE(@"STRING_KYC_DOC_TURN_DETAIL_BOTTOM");
        stepToAdd;
    })];
    
    [retValue addObject:({
        KYCScannerStep *stepToAdd       = [KYCScannerStep stepWithType:KYCStepTypeCapture];
        stepToAdd.sideBarIcon           = @"KYC_DocStep_IdCardBack";
        stepToAdd.overlayIcon           = @"KYC_DocStep_IdCardBack";
        stepToAdd.sideBarCaption        = TRANSLATE(([baseKey stringByAppendingString:@"03"]));
        stepToAdd.overlayCaptionTop     = TRANSLATE(@"STRING_KYC_DOC_SCAN_DETAIL_TOP");
        stepToAdd.overlayCaptionBottom  = TRANSLATE(@"STRING_KYC_DOC_SCAN_DETAIL_BOTTOM");
        stepToAdd;
    })];
    
    return retValue;
}

- (NSArray<KYCScannerStep *> *)scanningStepsPassport {
    NSMutableArray<KYCScannerStep *> *retValue = [NSMutableArray array];
    
    [retValue addObject:({
        KYCScannerStep *stepToAdd       = [KYCScannerStep stepWithType:KYCStepTypeCapture];
        stepToAdd.sideBarIcon           = @"KYC_DocStep_Passport";
        stepToAdd.overlayIcon           = @"KYC_DocStep_Passport";
        stepToAdd.sideBarCaption        = TRANSLATE(@"STRING_KYC_DOC_SCAN_STEP_01");
        stepToAdd.overlayCaptionTop     = TRANSLATE(@"STRING_KYC_DOC_SCAN_DETAIL_TOP");
        stepToAdd.overlayCaptionBottom  = TRANSLATE(@"STRING_KYC_DOC_SCAN_DETAIL_BOTTOM");
        stepToAdd;
    })];
    
    return retValue;
}

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

// MARK: - Static Helpers

+ (void)removeClassFromSubviews:(Class)cls parent:(UIView *)parent {
    for (UIView *loopView in parent.subviews) {
        if ([loopView isKindOfClass:cls]) {
            [loopView removeFromSuperview];
        } else {
            [KYCManager removeClassFromSubviews:cls parent:loopView];
        }
    }
}

+ (NSArray<__kindof UIView *> *)getClassesFromSubviews:(Class)cls parent:(UIView *)parent {
    NSMutableArray<__kindof UIView *> *retValue = [NSMutableArray array];
    
    for (UIView *loopView in parent.subviews) {
        if ([loopView isKindOfClass:cls]) {
            [retValue addObject:loopView];
        }
        
        [retValue addObjectsFromArray:[KYCManager getClassesFromSubviews:cls parent:loopView]];
    }
    
    return retValue;
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
