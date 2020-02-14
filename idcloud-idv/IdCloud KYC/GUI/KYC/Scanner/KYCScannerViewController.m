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

#import "KYCScannerViewController.h"
#import "KYCScannerStepView.h"
#import "KYCScannerStepDetailView.h"

#define kZonePercentage     .8f
#define kZoneAspect         1.4204
#define kSegueFaceScanner   @"sequeScannerFaceId"
#define kSegueKYCOverview   @"sequeKYCOverview"

@interface AVCameraDetectedLineView : UIView

@end

@interface AVCameraPreviewView : UIView

@end

@interface KYCScannerViewController() <CaptureDelegate, DetectionWarningDelegate, KYCScannerStepProtocol>

@property (nonatomic, strong)   IBOutlet CaptureInterface   *captureView;
@property (nonatomic, strong)   UIView                      *captureZoneOverlay;

@property (nonatomic, weak)     IBOutlet UIButton           *buttonBack;
@property (nonatomic, weak)     IBOutlet UIView             *viewTutorialSteps;
@property (nonatomic, weak)     IBOutlet UIStackView        *stackTutorialSteps;
@property (nonatomic, weak)     IBOutlet UIImageView        *imageOverlayStatus;
@property (nonatomic, weak)     IBOutlet UIButton           *buttonShutter;
@property (nonatomic, strong)   UIVisualEffectView          *blurOverlay;

// Mark VC that it's reused so some initial step to UI should be skipped.
@property (nonatomic, assign) BOOL                          reused;
// Current step
@property (nonatomic, assign) NSInteger                     step;
// Steps from data layer.
@property (nonatomic, strong) NSArray<KYCScannerStep *>     *steps;
// Used to wait for SDK and camera to fully load.
@property (nonatomic, assign) BOOL                          initialStep;
// Used to disable overlays during explanation process etc.
@property (nonatomic, assign) BOOL                          disableCustomOverlays;
// Used to disable SDK buttons during explanation process etc.
@property (nonatomic, assign) BOOL                          disableSDKButtons;
// Last warning so we can update state right after step change
@property (nonatomic, assign) DetectionWarning              lastWarning;
// Custom notification bar for face scanning.
@property (nonatomic, strong) KYCScannerNotification        *kycNotification;


@end

@implementation KYCScannerViewController

// MARK: - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Make view controller appear in landscape and allow both orientations.
    if (![KYCManager sharedInstance].cameraOrientation) {
        self.viewAutorotation       = YES;
        self.viewRotationMask       = UIInterfaceOrientationMaskLandscape;
        self.viewPreferedRotation   = UIInterfaceOrientationLandscapeRight;
    }
    
    if (!_kycNotification) {
        self.kycNotification = [KYCScannerNotification notificationWithScreenOffset:78.f];
        [self.view addSubview:_kycNotification];
    }
    
    // Camera view is automatically turned off when you put application to background.
    // We want to re-start camera once app become active again.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationIsActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)applicationIsActive:(NSNotification *)notification {
    [self startScanning];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Get manager
    KYCManager *manager = [KYCManager sharedInstance];
    
    // Delegate is used to display custom status overlay.
    [_captureView setDetectionWarningsDelegate:self];
    
    // Automatic detection
    [_captureView setAutoCropping:manager.automaticTypeDetection];
    
    // BW Photo copy
    [_captureView setBWPhotocopyQAEnabled:manager.bwPhotoCopyQA];
    
    // Remove strange overlay which does not work with rest of the UI.
    // TODO: Make sure, that 640x480 is always just that overlay and it works on all devices.
    if (!_reused) {
        for (UIImageView *loopImage in [KYCManager getClassesFromSubviews:[UIImageView class] parent:_captureView]) {
            // Check size and subview position to make sure we have the right one.
            if (CGSizeEqualToSize(loopImage.image.size, CGSizeMake(640, 480)) && loopImage.superview.superview == _captureView) {
                [loopImage setAlpha:.0f];
                break;
            }
        }
    }
    
    // Capture zone
    if (manager.idCaptureDetectionZone) {
        // Limit detection zone and display white rectangle.
        [_captureView setDetectionZoneSpace:kZonePercentage * 100.f andAspectRatio:kZoneAspect];
        
        // With setDetectionZoneSpace SDK display some broken lines.
        if (!_reused) {
            [KYCManager removeClassFromSubviews:[AVCameraDetectedLineView class] parent:_captureView];
        }
    }
    
    // Detection zone + Biometric passport MRZ code overlay.
    if (!_reused && (manager.idCaptureDetectionZone || _type == KYCDocumentTypePassportBiometric)) {
        self.captureZoneOverlay                 = [[UIView alloc] initWithFrame:CGRectZero];
        _captureZoneOverlay.backgroundColor     = [UIColor clearColor];
        _captureZoneOverlay.layer.borderColor   = [UIColor whiteColor].CGColor;
        _captureZoneOverlay.layer.borderWidth   = 2.f;
        [_captureView addSubview:_captureZoneOverlay];
    }
    
    // Load configuration and tutorial steps.
    [self loadScannerConfig];
    
    // Stard SDK.
    [self startScanning];
    
    // Make sure, that next time we will not update same UI part as now.
    self.reused = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Release capture view ONLY if this VC will be destroyed otherwise we might still need it.
    if (!self.presentedViewController) {
        [self.captureView releaseMemory];
        self.captureView = nil;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    BOOL portrait = [KYCManager sharedInstance].cameraOrientation;
    
    // Visual is different in both orientations. We can't solve that with static constraints.
    CGFloat offset = .0f;
    if (portrait) {
        offset = [self layoutForPortrait];
    } else {
        offset = [self layoutForLandscape];
    }
    
    if (_captureZoneOverlay) {
        // TODO: Do we want to use offset for overlays based on stripe with steps?
        // In case we do, remove this code and update even the rest.
        offset = .0f;
        
        Document *docSize = _type == KYCDocumentTypePassportBiometric ? DOCUMENT_TD2 : DOCUMENT_TD1;
        CGRect frame;
        if (portrait) {
            CGFloat width   = self.view.bounds.size.width * kZonePercentage;
            CGFloat height  = width / docSize->aspectRatio;
            frame = CGRectMake(self.view.bounds.size.width * .5f - width * .5f,
                               self.view.bounds.size.height * .5f - height * .5f,
                               width, height);
        } else {
            CGFloat height  = self.view.bounds.size.height * kZonePercentage;
            CGFloat width   = height * docSize->aspectRatio;
            frame = CGRectMake(offset + (self.view.bounds.size.width - offset) * .5f - width * .5f,
                               self.view.bounds.size.height * .5f - height * .5f,
                               width, height);
        }
        _captureZoneOverlay.frame = frame;
    }
    
    // Fix issues on bigger screens like iPhone 11.
    [self fixBeggierScreenPreview:portrait];
}

// MARK: - Public API

- (void)startScanning {
    // Init the SDK with success completion
    [_captureView initWithCompletion:^(BOOL isCompleted, int errorCode) {
        if(isCompleted) {
            [self.captureView start:self];
        } else {
            switch (errorCode) {
                case RootedDevice:
                    [self.kycNotification display:TRANSLATE(@"STRING_KYC_DOC_SCAN_ERROR_ROOT") type:NotifyTypeWarning];
                    break;
                case InvalidArchitecture:
                    [self.kycNotification display:TRANSLATE(@"STRING_KYC_DOC_SCAN_ERROR_ARCHITECTURE") type:NotifyTypeWarning];
                    break;
                case AppInBackground:
                    [self.kycNotification display:TRANSLATE(@"STRING_KYC_DOC_SCAN_ERROR_BACKGROUND") type:NotifyTypeWarning];
                    break;
            }
        }
    }];
}

// MARK: - Private Helpers

- (CGFloat)layoutForLandscape {
    CGFloat safeAreaHeight = self.view.safeAreaInsets.left ? 32.f : .0f;
    
    _viewTutorialSteps.translatesAutoresizingMaskIntoConstraints = NO;
    [_viewTutorialSteps.widthAnchor constraintEqualToConstant:96.f + safeAreaHeight].active = YES;
    [_viewTutorialSteps.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [_viewTutorialSteps.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [_viewTutorialSteps.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    
    _stackTutorialSteps.axis = UILayoutConstraintAxisVertical;
    _stackTutorialSteps.translatesAutoresizingMaskIntoConstraints = NO;
    [_stackTutorialSteps.leftAnchor constraintEqualToAnchor:_viewTutorialSteps.leftAnchor constant:safeAreaHeight].active = YES;
    [_stackTutorialSteps.rightAnchor constraintEqualToAnchor:_viewTutorialSteps.rightAnchor].active = YES;
    [_stackTutorialSteps.topAnchor constraintEqualToAnchor:_buttonBack.bottomAnchor].active = YES;
    [_stackTutorialSteps.bottomAnchor constraintEqualToAnchor:_viewTutorialSteps.bottomAnchor].active = YES;
    
    _buttonShutter.translatesAutoresizingMaskIntoConstraints = NO;
    [_buttonShutter.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    [_buttonShutter.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-24.f].active = YES;
    
    return safeAreaHeight + 96.f;
}

- (CGFloat)layoutForPortrait {
    CGFloat safeAreaHeight = self.view.safeAreaInsets.top ? 32.f : .0f;
    
    _viewTutorialSteps.translatesAutoresizingMaskIntoConstraints = NO;
    [_viewTutorialSteps.heightAnchor constraintEqualToConstant:96.f + safeAreaHeight].active = YES;
    [_viewTutorialSteps.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [_viewTutorialSteps.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [_viewTutorialSteps.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    
    _stackTutorialSteps.axis = UILayoutConstraintAxisHorizontal;
    _stackTutorialSteps.translatesAutoresizingMaskIntoConstraints = NO;
    [_stackTutorialSteps.leftAnchor constraintEqualToAnchor:_buttonBack.rightAnchor].active = YES;
    [_stackTutorialSteps.rightAnchor constraintEqualToAnchor:_viewTutorialSteps.rightAnchor constant:-16.f].active = YES;
    [_stackTutorialSteps.topAnchor constraintEqualToAnchor:_viewTutorialSteps.topAnchor constant:safeAreaHeight].active = YES;
    [_stackTutorialSteps.bottomAnchor constraintEqualToAnchor:_viewTutorialSteps.bottomAnchor].active = YES;
    
    _buttonShutter.translatesAutoresizingMaskIntoConstraints = NO;
    [_buttonShutter.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [_buttonShutter.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-16.f].active = YES;
    
    return safeAreaHeight + 96.f;
}

- (void)loadScannerConfig {
    // No overlay at the beginning.
    _imageOverlayStatus.image = nil;
    
    if (_type == KYCDocumentTypeIdCard) {
        [self.captureView setCaptureDocuments:[Document getDocumentModeICAO]];
    } else {
        [self.captureView setCaptureDocuments:[Document getDocumentModePassport]];
    }
    
    // Update current steps and wait for first detectionWarnings. See initialStep usage.
    self.steps          = [[KYCManager sharedInstance] scanningStepsWithType:_type];
    self.initialStep    = YES;
    
    // Add all steps to side bar.
    if (!_reused) {
        for (KYCScannerStep *loopStep in _steps) {
            [_stackTutorialSteps addArrangedSubview:[KYCScannerStepView stepWithStepData:loopStep]];
        }
        // Add empty slots, so we always have 3 virtual steps here.
        for (NSInteger index = _stackTutorialSteps.arrangedSubviews.count; index < 3; index++) {
            [_stackTutorialSteps addArrangedSubview:({
                UIView *stackFill = [UIView new];
                [stackFill setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
                [stackFill setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
                stackFill;
            })];
        }
    }
    
    // Hide all overlays before displaying step info.
    [self setDisableCustomOverlays:YES];
    
    // Add blur effect
    if (!_reused) {
        UIBlurEffect *blurEffect        = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.blurOverlay                = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        if ([KYCManager sharedInstance].cameraOrientation) {
            _blurOverlay.frame          = self.view.bounds;
        } else {
            _blurOverlay.frame          = CGRectMake(.0f, .0f, self.view.bounds.size.height, self.view.bounds.size.width);
        }
        _blurOverlay.autoresizingMask   = UIViewAutoresizingNone;
        _blurOverlay.alpha              = .0f;
        
        // Make all basic views transparent
        for (UIView *loopView in [KYCManager getClassesFromSubviews:[UIView class] parent:self.captureView]) {
            loopView.backgroundColor = [UIColor clearColor];
        }
        for (AVCameraPreviewView *loopPreivew in [KYCManager getClassesFromSubviews:[AVCameraPreviewView class] parent:self.captureView]) {
            // Insert it just above capture view.
            [loopPreivew addSubview:_blurOverlay];
            // iPhone X and bigger does not have full screen preview. At least make background black.
            loopPreivew.backgroundColor = UIColor.blackColor;
        }
    }
    
    // Skip document turn step.
    [self.captureView setSecondPageTimeout:0];
    
    // Result Ok Screen auto skip.
    [self.captureView setQACheckResultTimeout:3];
    
    [self.captureView setEdgesMode:MachineLearning];
    
    // Disable SDK shutter button. It does not work properly.
    [self.captureView hideUIElementsForStep:Detecting];
}

- (BOOL)activeStep:(NSUInteger)step {
    if (step >= _steps.count) {
        return NO;
    }
    
    self.step = step;
    
    // Highligh step in side menu.
    for (NSInteger loopIndex = 0; loopIndex < _stackTutorialSteps.arrangedSubviews.count; loopIndex++) {
        KYCScannerStepView *loopStep = _stackTutorialSteps.arrangedSubviews[loopIndex];
        if ([loopStep isKindOfClass:KYCScannerStepView.class]) {
            loopStep.activeStep = loopIndex == step;
        }
    }
    
    // Display current step, play related animation etc...
    // Get frame of current step in side menu.
    CGRect frame = _stackTutorialSteps.arrangedSubviews[step].frame;
    frame.origin.x += _stackTutorialSteps.frame.origin.x;
    frame.origin.y += _stackTutorialSteps.frame.origin.y;
    
    // Prepare detail overview and wait for delegate response
    KYCScannerStepDetailView *stepDetailView = [KYCScannerStepDetailView stepWithStepData:_steps[_step] delegate:self];
    [stepDetailView showDetailFromFrame:frame];
    [self.view addSubview:stepDetailView];
    
    // Hide all overlays for detail.
    [self setDisableCustomOverlays:YES];
    
    return YES;
}

- (void)setDisableCustomOverlays:(BOOL)disable {
    _disableCustomOverlays = disable;
    
    // Disable SDK auto behaviour.
    for (AVCameraDetectedLineView *loopLine in [KYCManager getClassesFromSubviews:[AVCameraDetectedLineView class] parent:self.captureView]) {
        [loopLine setAlpha:disable ? .0f : 1.f];
    }
    if (disable) {
        [self.captureView setAutoSnapshot:NO];
    } else {
        [self.captureView setAutoSnapshot:![KYCManager sharedInstance].manualScan];
    }
    
    // Hide all overlay elements
    [self.captureZoneOverlay    setHidden:disable];
    [_imageOverlayStatus        setHidden:disable];
    [_buttonShutter             setHidden:disable || ![KYCManager sharedInstance].manualScan];
    
    if (disable) {
        [_kycNotification hide];
    }
    
    // Cancel all current animations
    //    [self.blurOverlay.layer removeAllAnimations];
    
    [UIView animateWithDuration:1.f
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.5
                        options:0
                     animations:^{
        self.blurOverlay.alpha = disable ? 1.f : .0f;
    } completion:nil];
}

- (void)updateNotification:(BOOL)includingOverlay type:(NotifyType)type {
    NSString *iconName;
    NSString *caption;
    
    if ((_lastWarning & FitDocument) == FitDocument) {
        iconName    = @"KYC_ScanOverlay_Fit";
        caption     = TRANSLATE(@"STRING_KYC_DOC_SCAN_WARNING_FIT");
    }
    if ((_lastWarning & FocusInProgress) == FocusInProgress) {
        iconName    = @"KYC_ScanOverlay_Focus";
        caption     = TRANSLATE(@"STRING_KYC_DOC_SCAN_WARNING_FOCUSING");
    }
    if ((_lastWarning & Hotspot) == Hotspot) {
        iconName    = @"KYC_ScanOverlay_Hotspot";
        caption     = TRANSLATE(@"STRING_KYC_DOC_SCAN_WARNING_HOTSPOT");
    }
    if ((_lastWarning & LowContrast) == LowContrast) {
        iconName    = @"KYC_ScanOverlay_Contrast";
        caption     = TRANSLATE(@"STRING_KYC_DOC_SCAN_WARNING_CONTRAST");
    }
    if ((_lastWarning & LowLight) == LowLight) {
        iconName    = @"KYC_ScanOverlay_Light";
        caption     = TRANSLATE(@"STRING_KYC_DOC_SCAN_WARNING_LIGHT");
    }
    if ((_lastWarning & Blur) == Blur) {
        iconName    = @"KYC_ScanOverlay_Focus";
        caption     = TRANSLATE(@"STRING_KYC_DOC_SCAN_WARNING_BLUR");
    }
    
    if (iconName && includingOverlay) {
        _imageOverlayStatus.image = [UIImage imageNamed:iconName];
    }
    if (caption) {
        [_kycNotification display:caption type:type];
    } else {
        [_kycNotification hide];
    }
}

- (void)fixBeggierScreenPreview:(BOOL)portrait {
    // Actual view preview size.
    CGFloat aspect = 1280.f / 720.f;

    if (portrait) {
        CGFloat emptySpace = self.view.frame.size.height - _viewTutorialSteps.frame.size.height;
        CGFloat realHeight = _captureView.frame.size.width * aspect;
        if (realHeight < emptySpace) {
            // Real height is smaller than window to fit. Place it to the middle.
            _captureView.frame = CGRectMake(.0f, _viewTutorialSteps.frame.size.height + (emptySpace - realHeight) * .5f, self.view.frame.size.width, realHeight);
        } else {
            // Real height is bigger than window to fit. Place it from the bottom.
            _captureView.frame = CGRectMake(.0f, self.view.frame.size.height - realHeight, self.view.frame.size.width, realHeight);
        }
    } else {
        CGFloat emptySpace = self.view.frame.size.width - _viewTutorialSteps.frame.size.width;
        CGFloat realWidth = _captureView.frame.size.height * aspect;
        if (realWidth < emptySpace) {
            // Real width is smaller than window to fit. Place it to the middle.
            _captureView.frame = CGRectMake(_viewTutorialSteps.frame.size.width + (emptySpace - realWidth) * .5f, .0f, realWidth, self.view.frame.size.height);
        } else {
            // Real width is bigger than window to fit. Place it from the right.
            _captureView.frame = CGRectMake(self.view.frame.size.width - realWidth, .0f, realWidth, self.view.frame.size.height);
        }
    }
}

// MARK: - KYCScannerStepProtocol

- (void)onDetailStepDisplayed {
    
}

- (void)onDetailStepBeforeHide {
}

- (void)onDetailStepAfterHide {
    // Confirm turn over of document.
    if (_step < _steps.count && _steps[_step].stepType == KYCStepTypeTurnOver) {
        [self activeStep:_step + 1];
    } else {
        [self setDisableCustomOverlays:NO];
        [self detectionWarnings:_lastWarning];
    }
}

// MARK: - CaptureDelegate

- (void) onSuccess:(NSData*)p_side1 side:(NSData*)p_side2 metadata:(NSDictionary*)p_metaData {
    // Mandatory, but we don't need it. Wait for onSuccess:(CaptureResult *) captureResult
}

- (void) onSuccess:(CaptureResult *) captureResult {
    // Hide overlays.
    [self setDisableCustomOverlays:YES];
    
    // Stop capture view before dismiss to prevent any strange autorotation.
    [self.captureView stop];
    
    // Store scanned documents
    KYCManager *manager = [KYCManager sharedInstance];
    [manager setScannedDocFront:[captureResult.side1 copy]];
    [manager setScannedDocBack:[captureResult.side2 copy]];
    
    
    if ([KYCManager sharedInstance].facialRecognition) {
        [self performSegueWithIdentifier:kSegueFaceScanner sender:nil];
    } else {
        [self performSegueWithIdentifier:kSegueKYCOverview sender:nil];
    }
}

- (void)onScreenChanged:(CaptureScreen)screen {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Going from OK screen. Activate next step if possible.
        if (screen == OutResultOK) {
            [self activeStep:self.step + 1];
        }
        
        // Disable overlay on any other than capturng screen.
        if (screen != InDetecting && screen != OutResultKO) {
            [self setDisableCustomOverlays:YES];
            [self.kycNotification hide];
            self.imageOverlayStatus.image = nil;
        } else {
            [self setDisableCustomOverlays:NO];
            [self updateNotification:YES type:NotifyTypeInfo];
        }
    });
}

// MARK: - DetectionWarningDelegate

- (void)detectionWarnings:(DetectionWarning)warnings {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Preserve current warning so we can use that in swithing steps.
        self.lastWarning = warnings;
        
        // This way we know that camera is fully loaded and working.
        // We do not want to display first step while sdk is loading.
        if (self.initialStep) {
            [self activeStep:0];
            self.initialStep = NO;
            return;
        }
        
        // Ignore any notification from SDK while explaining current step.
        if (self.disableCustomOverlays) {
            return;
        }
        
        [self updateNotification:YES type:NotifyTypeInfo];
    });
}

// MARK: - User Interface

- (IBAction)onButtonPressedBack:(UIButton *)sender {
    // Stop capture view before dismiss to prevent any strange autorotation.
    [self.captureView stop];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)onButtonPressedShutter:(UIButton *)sender {
    [self.captureView triggerSnapshotButton];
}

@end
