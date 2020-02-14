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

#import "FaceLivenessCameraController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreText/CoreText.h>

@interface FaceLivenessCameraController () <AcuantHGLiveFaceCaptureDelegate>

@property (nonatomic, strong) UIView                        *overlayView;
@property (nonatomic, assign) BOOL                          captured;
@property (nonatomic, strong) CIContext                     *context;
@property (nonatomic, strong) FaceCaptureSession            *captureSession;
@property (nonatomic, assign) UIDeviceOrientation           lastDeviceOrientation;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer    *videoPreviewLayer;
@property (nonatomic, strong) CAShapeLayer                  *faceOval;
@property (nonatomic, assign) CGRect                        messageBoundingRect;

@end

@implementation FaceLivenessCameraController

// MARK: - Life Cycle

- (id)init {
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    (UIApplication.shared.delegate as! AppDelegate).orientationLock = .portrait
}

- (void)viewDidAppear:(BOOL)animated {
    _captured = NO;
    [super viewDidAppear:animated];
    [self startCameraView];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_captureSession.isRunning) {
        [_captureSession stopRunning];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    AVCaptureConnection *previewLayerConnection = self.videoPreviewLayer.connection;
    if (previewLayerConnection && previewLayerConnection.isVideoOrientationSupported) {
        UIDevice *currentDevice = UIDevice.currentDevice;
        UIDeviceOrientation orientation = currentDevice.orientation;
        
        switch (orientation) {
            case UIDeviceOrientationLandscapeRight:
                [self updatePreviewLayer:previewLayerConnection orientation:AVCaptureVideoOrientationLandscapeLeft];
                break;
            case UIDeviceOrientationLandscapeLeft:
                [self updatePreviewLayer:previewLayerConnection orientation:AVCaptureVideoOrientationLandscapeRight];
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                [self updatePreviewLayer:previewLayerConnection orientation:AVCaptureVideoOrientationPortraitUpsideDown];
                break;
            default:
                [self updatePreviewLayer:previewLayerConnection orientation:AVCaptureVideoOrientationPortrait];
                break;
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        UIInterfaceOrientation orient = UIApplication.sharedApplication.statusBarOrientation;
        switch (orient) {
            case UIInterfaceOrientationPortrait:
                NSLog(@"Portrait");
                break;
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                NSLog(@"Landscape");
                break;
            default:
                NSLog(@"Anything But Portrait");
                break;
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.captureSession stopRunning];
        [self startCameraView];
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

// MARK: - Private Helpers

- (void)startCameraView {
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                                        mediaType:AVMediaTypeVideo
                                                                         position:AVCaptureDevicePositionFront];
    self.captureSession = [AcuantHGLiveness getFaceCaptureSessionWithDelegate:self
                                                                captureDevice:captureDevice
                                                                 previewWidth:self.view.layer.bounds.size.width
                                                                previewHeight:self.view.layer.bounds.size.height];
    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _videoPreviewLayer.frame = self.view.layer.bounds;
    [self addoverlay];
    [self displayBlinkMessage];
    [self.view.layer addSublayer:_videoPreviewLayer];
    [_captureSession startRunning];
}

- (void)updatePreviewLayer:(AVCaptureConnection *)layer orientation:(AVCaptureVideoOrientation)orientation {
    _videoPreviewLayer.connection.videoOrientation = orientation;
}

- (CGRect)getViewFrame {
    return UIScreen.mainScreen.bounds;
}

- (CGSize)getViewFrameSize {
    return [self getViewFrame].size;
}

- (CGRect)getTransparentRect {
    
    CGFloat hSpace          = .75f;
    CGFloat vSpace          = .75f;
    CGRect  overlayRect     = [self getViewFrame];
    CGFloat rectWidth       = overlayRect.size.width;
    CGFloat rectHeight      = overlayRect.size.height;
    BOOL    isLandscape     = UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation);
    
    if(isLandscape){
        [self swap:&rectWidth second:&rectHeight];
    }

    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if(isLandscape){
            vSpace = .5f;
        }
    } else if (isLandscape) {
        hSpace = .75f;
        vSpace = .45f;
    } else {
        hSpace = .95f;
    }
    
    CGFloat width           = rectWidth * hSpace;
    CGFloat height          = rectHeight * vSpace;
    CGFloat horizontalSpace = (overlayRect.size.width-width) / 2.f;
    CGFloat verticalSpace   = .15f * overlayRect.size.height;
    
    return CGRectMake(horizontalSpace, verticalSpace, width, height);
}

- (UIBezierPath *)getTransparentBezierPath {
    return [UIBezierPath bezierPathWithOvalInRect:[self getTransparentRect]];
}

- (void)addoverlay {
    UIView *overlayView = [[UIView alloc] initWithFrame:[self getViewFrame]];
    overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.1f];
    UIBezierPath *overlayPath = [UIBezierPath bezierPathWithRect:overlayView.bounds];
    UIBezierPath *transparentPath = [self getTransparentBezierPath];
    [overlayPath appendPath:transparentPath];
    overlayPath.usesEvenOddFillRule = YES;
    CAShapeLayer *fillLayer = [CAShapeLayer new];
    fillLayer.path = overlayPath.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = [UIColor colorWithRed:.0f green:.0f blue:.0f alpha:.6f].CGColor;

    [_overlayView.layer addSublayer:fillLayer];
    [_videoPreviewLayer addSublayer:_overlayView.layer];
}

- (void)displayBlinkMessage {
    NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:@"Move closer and blink\nwhen green oval appears"];
    [message addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, message.length)];
    [message addAttribute:NSForegroundColorAttributeName value:UIColor.greenColor range:NSMakeRange(27, 10)];
    [message addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:24.f] range:NSMakeRange(0, message.length)];

    CATextLayer *blinkLabel = [CATextLayer new];
    blinkLabel.frame            = [self getBlinkMessageRect];
    blinkLabel.string           = message;
    blinkLabel.contentsScale    = UIScreen.mainScreen.scale;
    blinkLabel.alignmentMode    = kCAAlignmentCenter;
    blinkLabel.foregroundColor  = UIColor.whiteColor.CGColor;
    
    [_videoPreviewLayer addSublayer:blinkLabel];
}

- (CGRect)getBlinkMessageRect {
    CGFloat width = 330.f;
    CGFloat height = 60.f;
    CGRect mainViewFrame = [self getViewFrame];

    return CGRectMake(mainViewFrame.origin.x + mainViewFrame.size.width / 2.f -width / 2.f,
                      0.08f * mainViewFrame.size.height,
                      width,
                      height);
}

- (CGRect)videoBox:(CGSize)frameSize apertureSize:(CGSize)apertureSize {
//    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
//    CGFloat viewRatio = frameSize.width / frameSize.height;

    CGSize size = CGSizeMake(apertureSize.height * (frameSize.height / apertureSize.width), frameSize.height);
    CGRect videoBox = CGRectMake(.0, .0, size.width, size.height);
    
    if (size.width < frameSize.width) {
        videoBox.origin.x = (frameSize.width - size.width) / 2.0f;
    } else {
        videoBox.origin.x = (size.width - frameSize.width) / 2.0f;
    }

    if (size.height < frameSize.height) {
        videoBox.origin.y = (frameSize.height - size.height) / 2.0f;
    } else {
        videoBox.origin.y = (size.height - frameSize.height) / 2.0f;
    }

    return videoBox;
}

- (CGRect)calculateFaceRect:(CGRect)faceBounds clearAperture:(CGRect)clearAperture {
    CGSize parentFrameSize = self.videoPreviewLayer.frame.size;
    CGSize apperatureSize = clearAperture.size;
    if (@available(iOS 11.0, *)) {
        parentFrameSize.width = parentFrameSize.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right;
        apperatureSize.width = apperatureSize.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right;
    } else {
        // Fallback on earlier versions
    }
    
    if (@available(iOS 11.0, *)) {
        parentFrameSize.height = parentFrameSize.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom;
        apperatureSize.height = apperatureSize.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom;
    } else {
        // Fallback on earlier versions
    }
    CGRect previewBox = [self videoBox:parentFrameSize apertureSize:apperatureSize];
    CGRect faceRect = faceBounds;

    [self swap:&faceRect.size.width second:&faceRect.size.height];
    [self swap:&faceRect.origin.x second:&faceRect.origin.y];

    CGFloat widthScaleBy = previewBox.size.width / apperatureSize.height;
    CGFloat heightScaleBy = previewBox.size.height / apperatureSize.width;
    faceRect.size.width *= widthScaleBy;
    faceRect.size.height *= heightScaleBy;
    faceRect.origin.x *= widthScaleBy;
    faceRect.origin.y *= heightScaleBy;

    faceRect = CGRectOffset(faceRect, .0f, previewBox.origin.y);
    CGRect frame = CGRectMake((parentFrameSize.width) - faceRect.origin.x - faceRect.size.width - previewBox.origin.x / 2.0,
                              faceRect.origin.y, faceRect.size.width, faceRect.size.height);
    return frame;
}

- (void)swap:(CGFloat *)first second:(CGFloat *)second {
    // TODO: Check this
    CGFloat tmp = *first;
    *first = *second;
    *second = tmp;
}


// MARK: - AcuantHGLiveFaceCaptureDelegate

- (void)liveFaceDetailsCapturedWithLiveFaceDetails:(LiveFaceDetails *)liveFaceDetails {
    
    if (liveFaceDetails.faceRect && liveFaceDetails.image && liveFaceDetails.cleanAperture) {
        CGRect translatedFaceRect = [self calculateFaceRect:liveFaceDetails.faceRect.toCGRect clearAperture:liveFaceDetails.cleanAperture.toCGRect];
        CGFloat topPadding = self.view.safeAreaInsets.top;
        CGFloat bottomPadding = self.view.safeAreaInsets.bottom;
        CGFloat width = 1.1f * translatedFaceRect.size.width;
        CGFloat height = 1.3f * translatedFaceRect.size.height;
        CGFloat x = translatedFaceRect.origin.x + (translatedFaceRect.size.width - width) + (topPadding + bottomPadding) / 2.f;
        CGFloat y = translatedFaceRect.origin.y + (translatedFaceRect.size.height - height);
        CGRect faceRect = CGRectMake(x, y, width, height);
        [_faceOval removeFromSuperlayer];
        
        self.faceOval = [CAShapeLayer new];
        _faceOval.path = [UIBezierPath bezierPathWithOvalInRect:faceRect].CGPath;
        _faceOval.fillColor = UIColor.clearColor.CGColor;
        _faceOval.strokeColor = UIColor.greenColor.CGColor;
        _faceOval.lineWidth = 5.f;
        [_videoPreviewLayer addSublayer:_faceOval];
        if (liveFaceDetails.isLiveFace) {
            if (!_captured) {
                _captured = YES;
            } else if (_delegate) {
                [_delegate liveFaceCapturedWithImage:liveFaceDetails.image];
                _delegate = nil;
            }
        }
    } else if (!liveFaceDetails || !liveFaceDetails.faceRect) {
        [self.faceOval removeFromSuperlayer];
    }
}

@end
