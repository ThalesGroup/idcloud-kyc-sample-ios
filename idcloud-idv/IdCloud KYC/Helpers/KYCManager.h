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

#define kZeroDelay nil

#import "IdCloudOption.h"
#import "KYCScannerStep.h"

#define kNotificationDataLayerChanged @"kNotificationDataLayerChanged"

typedef void (^FaceIdCompletion)(BOOL success, NSError *error);

typedef NSArray<NSArray <IdCloudOption *> *> OptionArray;

@interface KYCManager : NSObject

// KYC Generic values
@property (nonatomic, assign) BOOL      kycEnrolled;

// GeneralSettings
@property (nonatomic, assign) BOOL      facialRecognition;

// RiskManagement
@property (nonatomic, assign) BOOL      ignoreExpirationDate;

// DocumentScan
@property (nonatomic, assign) BOOL      manualScan;
@property (nonatomic, assign) BOOL      automaticTypeDetection;
@property (nonatomic, assign) BOOL      cameraOrientation;
@property (nonatomic, assign) BOOL      idCaptureDetectionZone;
@property (nonatomic, assign) BOOL      bwPhotoCopyQA;

// FaceId
@property (nonatomic, assign) NSInteger faceLivenessMode;
@property (nonatomic, assign) NSInteger faceLivenessThreshold;
@property (nonatomic, assign) NSInteger faceQualityThreshold;
@property (nonatomic, assign) NSInteger faceBlinkTimeout;

// Options
@property (nonatomic, strong, readonly) NSArray <NSString *>        *optionCaptions;
@property (nonatomic, strong, readonly) OptionArray                 *options;
@property (nonatomic, copy, readonly)   NSString                    *jsonWebToken;
// Scanned elements
@property (nonatomic, strong)           NSData *scannedDocFront;
@property (nonatomic, strong)           NSData *scannedDocBack;
@property (nonatomic, strong)           NSData *scannedPortrait;

/**
 Common method to get KYCManager singletone.

 @return Instance of KYCManager class.
 */
+ (instancetype)sharedInstance;

/**
 Release singletone together with all helper class inside.
 */
+ (void)end;

- (NSArray<KYCScannerStep *> *)scanningStepsWithType:(KYCDocumentType)type;

- (void)initializeFaceIdLicense:(FaceIdCompletion)completion;

/**
 Switch to proper View Controller based on SDK state.

 */
- (void)updateRootViewController;

+ (void)removeClassFromSubviews:(Class)cls parent:(UIView *)parent;

+ (NSArray<__kindof UIView *> *)getClassesFromSubviews:(Class)cls parent:(UIView *)parent;


@end

