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

#import "KYCFaceIdScannerViewController.h"
#import "KYCScannerNotification.h"

#define kImageOverlay_Red           @"KYC_Overlay_Red"
#define kImageOverlay_Orange        @"KYC_Overlay_Orange"
#define kImageOverlay_Green         @"KYC_Overlay_Green"
#define kImageOverlay_GreenLight    @"KYC_Overlay_GreenLight"
#define kImageOverlay_Gray          @"KYC_Overlay_Gray"

@interface KYCFaceIdScannerViewController () <FaceCaptureViewDelegate>

@property (nonatomic, weak)     IBOutlet FaceCaptureView    *captureView;
@property (nonatomic, weak)     IBOutlet UIImageView        *imageOverlay;
@property (nonatomic, weak)     IBOutlet UIImageView        *imageResult;
@property (nonatomic, weak)     IBOutlet IdCloudButton      *buttonOk;
@property (nonatomic, weak)     IBOutlet IdCloudButton      *buttonRetry;
@property (nonatomic, assign)   NSInteger                   lastLivenessAction;
@property (nonatomic, assign)   CGRect                      lastLivenessRect;
@property (nonatomic, weak)     IBOutlet UILabel            *labelLiveness;
@property (nonatomic, weak)     IBOutlet UIProgressView     *progressLiveness;
@property (nonatomic, strong)   KYCScannerNotification      *kycNotification;

@end

@implementation KYCFaceIdScannerViewController

// MARK: - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Hide action buttons.
    _buttonOk.hidden            = YES;
    _buttonRetry.hidden         = YES;
    _lastLivenessAction         = -1;
    _lastLivenessRect           = CGRectMake(-1.f, -1.f, -1.f, -1.f);

    // Custom notification bar.
    if (!_kycNotification) {
        CGFloat offset          = [KYCManager sharedInstance].cameraOrientation ? 96.f : 24.f;
        self.kycNotification    = [KYCScannerNotification notificationWithScreenOffset:offset];
        [self.view addSubview:_kycNotification];
    }
    
    [self loadLivenessProgressbar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Make sure, that SDK is properly initialized.
    [[KYCManager sharedInstance] initializeFaceIdLicense:^(BOOL success, NSError *error) {
        if (success) {
            // Once SDK is loaded. We can init capture view.
            [self.captureView initializeWithCompletion:^(BOOL success, NSError *error) {
                if(success) {
                    [self loadCaptureView];
                }
                [self.kycNotification displayErrorIfExists:error];
            }];
        }
        [self.kycNotification displayErrorIfExists:error];
    }];
    
    // MAsk capture view to fit with overlay
    [self maskLayer:_captureView.layer];
    [self maskLayer:_imageResult.layer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self unscheduleNotificationHide];
}

// MARK: - Notification View

- (void)notificationHide {
    _lastLivenessAction = FaceLivenessActionNone;
    
    [_kycNotification hide];
}

// MARK: - Private Helpers

- (void)loadLivenessProgressbar {
    // Prepare gradient layer with size of original progress bar.
    CGRect bounds = _progressLiveness.bounds;
    IdCloudBackground *gradient = [[IdCloudBackground alloc] initWithFrame:CGRectMake(bounds.origin.x,
                                                                                      bounds.origin.y,
                                                                                      bounds.size.height,
                                                                                      bounds.size.width)];
    gradient.gradientStart  = [UIColor redColor];
    gradient.gradientMiddle = [UIColor orangeColor];
    gradient.gradientEnd    = [UIColor greenColor];
    
    // Get image from prepared gradient.
    UIImage *gradientImage  = [gradient renderImage];
    CGSize  size            = gradientImage.size;
    
    // Rotate it to get horizontal gradient.
    UIGraphicsBeginImageContext(CGSizeMake(size.height, size.width));
    [[UIImage imageWithCGImage:[gradientImage CGImage]
                         scale:1.0
                   orientation:UIImageOrientationRight] drawInRect:CGRectMake(0,0,size.height ,size.width)];
    UIImage* gradientImageRotated = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Update progressbar with generated texture.
    _progressLiveness.trackImage        = gradientImageRotated;
    _progressLiveness.transform         = CGAffineTransformMakeScale(-1.0, 1.0);
    _progressLiveness.progressTintColor = [UIColor blackColor];
    _progressLiveness.progress          = .0f;
    
    // Hide by default
    [self livenessMeterVisible:NO];
}

- (void)maskLayer:(CALayer *)layer {
    UIImage *maskOverlay    = [UIImage imageNamed:@"KYC_Overlay_Mask"];
    CALayer *maskLayer      = [CALayer layer];
    CGRect  maskRect        = CGRectMake(.0f, _imageOverlay.bounds.size.height * .5f - _imageOverlay.bounds.size.width * .5f,
                                         _imageOverlay.bounds.size.width, _imageOverlay.bounds.size.width);
    
    [maskLayer setFrame:maskRect];
    [maskLayer setContents:(id)maskOverlay.CGImage];
    [layer setMask:maskLayer];
}

- (void)loadCaptureView {
    KYCManager *manager = [KYCManager sharedInstance];
    
    // Configure face id SDK based on current settings and start capturing.
    [_captureView setDelegate:self];
    [_captureView setLivenessMode:manager.faceLivenessMode];
    [_captureView setLivenessBlinkTimeout:manager.faceBlinkTimeout * 1000];
    [_captureView setQualityThreshold:manager.faceQualityThreshold];
    [_captureView setLivenessThreshold:manager.faceLivenessThreshold];
    [_captureView startCapture];
    
    _captureView.hidden = NO;
    _imageResult.image  = nil;
}

- (void)scheduleNotificationHide {
    [self performSelector:@selector(notificationHide) withObject:nil afterDelay:3.f];
    
}

- (void)unscheduleNotificationHide {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notificationHide) object:nil];
}

- (void)livenessMeterVisible:(BOOL)visible {
    _progressLiveness.hidden    = !visible || [KYCManager sharedInstance].faceLivenessMode == FaceLivenessModeActive;
    _labelLiveness.hidden       = !visible || [KYCManager sharedInstance].faceLivenessMode == FaceLivenessModeActive;
}

// MARK: - FaceCaptureViewDelegate

- (void)onFaceVerificationSuccess:(UIImage *)image yaw:(float)yaw pitch:(float)pitch rect:(CGRect)boundingRect {
    
    // Store image.
    KYCManager *manager = [KYCManager sharedInstance];
    [manager setScannedPortrait:UIImagePNGRepresentation(image)];
    
    _imageResult.image          = image;
    _buttonOk.hidden            = NO;
    _buttonRetry.hidden         = NO;
    _captureView.hidden         = YES;
    
    [self livenessMeterVisible:NO];
}

- (void)onFaceVerificationFailed:(NSError *)error {
    [_kycNotification displayErrorIfExists:error];
    [self livenessMeterVisible:NO];

    _imageOverlay.image = [UIImage imageNamed:kImageOverlay_Red];
    _buttonRetry.hidden = NO;
}

- (void)onFaceCaptureInfo:(FaceCaptureInfo)info {
    
    _progressLiveness.progress = 1.f - (CGFloat)info.mLivenessScore / 100.f;
    
    BOOL detected = !CGRectEqualToRect(info.mBoundingRect, CGRectZero);
    if (!CGRectEqualToRect(info.mBoundingRect, _lastLivenessRect)) {
        [self livenessMeterVisible:detected];
        _imageOverlay.image = [UIImage imageNamed:detected ? kImageOverlay_Green : kImageOverlay_Gray];
        _lastLivenessRect = info.mBoundingRect;
    }
    
    if (info.mLivenessAction == _lastLivenessAction) {
        return;
    }
    
    NSString *translation;
    NotifyType icon = NotifyTypeInfo;
    switch (info.mLivenessAction) {
        case FaceLivenessActionNone:
            // Hide notificaiton
            translation = nil; // TRANSLATE(@"STRING_KYC_FACE_ACTION_NONE");
            break;
        case FaceLivenessActionKeepStill:
            translation = TRANSLATE(@"STRING_KYC_FACE_ACTION_KEEP_STILL");
            icon        = NotifyType_KYCKeepStill;
            break;
        case FaceLivenessActionBlink:
            translation = TRANSLATE(@"STRING_KYC_FACE_ACTION_BLINK");
            icon        = NotifyType_KYCBlink;
            break;
        case FaceLivenessActionMoveUp:
            translation = TRANSLATE(@"STRING_KYC_FACE_ACTION_MOVE_UP");
            icon        = NotifyType_KYCUp;
            break;
        case FaceLivenessActionMoveDown:
            translation = TRANSLATE(@"STRING_KYC_FACE_ACTION_MOVE_DOWN");
            icon        = NotifyType_KYCDown;
            break;
        case FaceLivenessActionMoveLeft:
            translation = TRANSLATE(@"STRING_KYC_FACE_ACTION_MOVE_LEFT");
            icon        = NotifyType_KYCLeft;
            break;
        case FaceLivenessActionMoveRight:
            translation = TRANSLATE(@"STRING_KYC_FACE_ACTION_MOVE_RIGHT");
            icon        = NotifyType_KYCRight;
            break;
        case FaceLivenessActionMoveToCenter:
            translation = TRANSLATE(@"STRING_KYC_FACE_ACTION_MOVE_TO_CENTER");
            icon        = NotifyType_KYCCenter;
            break;
        case FaceLivenessActionTurnSideToSide:
            translation = TRANSLATE(@"STRING_KYC_FACE_ACTION_SIDE_TO_SIDE");
            icon        = NotifyType_KYCRotate;
            break;
        case FaceLivenessActionRotateYaw:
            translation = TRANSLATE(@"STRING_KYC_FACE_ACTION_ROTATE_YAW");
            icon        = NotifyType_KYCRotate;
            break;
    }
    
    if (translation) {
        [self unscheduleNotificationHide];
        [_kycNotification display:translation type:icon];
        _lastLivenessAction = info.mLivenessAction;
    } else {
        [self scheduleNotificationHide];
    }
    
}

// MARK: - User Interface

- (IBAction)onButtonPressedBack:(UIButton *)sender {
    // Stop capture view before dismiss to prevent any strange autorotation.
    [self.captureView cancelCapture];
    self.captureView = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onButtonPressedRetry:(IdCloudButton *)sender {
    // Hide action buttons.
    _buttonOk.hidden    = YES;
    _buttonRetry.hidden = YES;
    
    [self livenessMeterVisible:YES];
    [self loadCaptureView];
}

@end
