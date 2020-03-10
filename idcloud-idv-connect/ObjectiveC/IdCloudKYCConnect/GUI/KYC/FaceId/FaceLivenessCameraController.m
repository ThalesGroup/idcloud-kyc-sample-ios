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
@property (nonatomic, strong) FaceCaptureSession            *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer    *videoPreviewLayer;
@property (nonatomic, strong) CAShapeLayer                  *faceOval;
@property (nonatomic, strong) CATextLayer                   *blinkLabel;
@property (nonatomic, assign) CGFloat                        currentFrameTime;

@end

#define FRAME_DURATION 0.1f

@implementation FaceLivenessCameraController

// MARK: - Life Cycle

- (id)init {
    if (self = [super init]) {
        _currentFrameTime = .0f;
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
    [self startCameraView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _captured = NO;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (_videoPreviewLayer.connection) {
        [self updatePreviewLayer:_videoPreviewLayer.connection orientation:AVCaptureVideoOrientationPortrait];
    }
}

// MARK: - Private Helpers

- (void)updatePreviewLayer:(AVCaptureConnection *)layer orientation:(AVCaptureVideoOrientation)orientation {
    _videoPreviewLayer.connection.videoOrientation = orientation;
}

- (void)startCameraView {
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                                        mediaType:AVMediaTypeVideo
                                                                         position:AVCaptureDevicePositionFront];
    
    self.captureSession = [AcuantHGLiveness getFaceCaptureSessionWithDelegate:self
                                                                captureDevice:captureDevice];
    [_captureSession start];

    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _videoPreviewLayer.frame = self.view.layer.bounds;

    [self addoverlay];
    [self displayBlinkMessage];
    
    self.faceOval = [CAShapeLayer new];
    _faceOval.fillColor = UIColor.clearColor.CGColor;
    _faceOval.strokeColor = UIColor.greenColor.CGColor;
    _faceOval.lineWidth = 5.f;
    
    [_videoPreviewLayer addSublayer:_faceOval];
    [self.view.layer addSublayer:_videoPreviewLayer];
}

- (BOOL)shouldSkipFrame:(LiveFaceDetails *)liveFaceDetails faceType:(AcuantFaceType)faceType {
    BOOL skipFrame = NO;
    if(_currentFrameTime < 0 || (liveFaceDetails && liveFaceDetails.isLiveFace) || CFAbsoluteTimeGetCurrent() - _currentFrameTime >= FRAME_DURATION) {
        _currentFrameTime = CFAbsoluteTimeGetCurrent();
    }
    else{
        skipFrame = YES;
    }
    return skipFrame;
}

- (CGRect)getViewFrame {
    return [UIScreen mainScreen].bounds;
}

- (CGSize)getViewFrameSize {
    return [self getViewFrame].size;
}

- (CGRect)getTransparentRect {
    CGRect retRect = CGRectZero;
    
    CGFloat hSpace = .95f;
    CGFloat vSpace = .75f;
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        hSpace = .75f;
    }
    CGRect overlayRect = [self getViewFrame];

    CGFloat rectWidth = overlayRect.size.width;
    CGFloat rectHeight = overlayRect.size.height;

    CGFloat width = rectWidth * hSpace;
    CGFloat height = rectHeight * vSpace;
    CGFloat horizontalSpace = (overlayRect.size.width - width) * .5f;
    CGFloat verticalSpace = .15f * overlayRect.size.height;
    
    retRect = CGRectMake(horizontalSpace, verticalSpace, width, height);
    
    return retRect;
}


- (UIBezierPath *)getTransparentBezierPath {
    return [UIBezierPath bezierPathWithOvalInRect:[self getTransparentRect]];
}

- (void)addoverlay {
    self.overlayView = [[UIView alloc] initWithFrame:[self getViewFrame]];
    _overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.1f];
    UIBezierPath *overlayPath = [UIBezierPath bezierPathWithRect:_overlayView.bounds];
    UIBezierPath *transparentPath = [self getTransparentBezierPath];
    [overlayPath appendPath:transparentPath];
    overlayPath.usesEvenOddFillRule = YES;
    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = overlayPath.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = [UIColor colorWithRed:.0f green:.0f blue:.0f alpha:.6f].CGColor;
    [_overlayView.layer addSublayer:fillLayer];
    [_videoPreviewLayer addSublayer:_overlayView.layer];
}

- (void)addMessage {
    [self addMessage:nil];
}

- (void)addMessage:(NSString *)message  {
    [self addMessage:message color:UIColor.redColor.CGColor];
}

- (void)addMessage:(NSString *)message color:(CGColorRef)color  {
    [self addMessage:message color:color fontSize:25.f];
}

- (void)addMessage:(NSString *)message color:(CGColorRef)color fontSize:(CGFloat)fontSize {
    if(!message){
        NSMutableAttributedString *msg = [[NSMutableAttributedString alloc] initWithString:@"Align face and blink when green oval appears"];
        [msg addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, msg.length)];
        [msg addAttribute:NSForegroundColorAttributeName value:UIColor.greenColor range:NSMakeRange(26, 10)];
        [msg addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13.f] range:NSMakeRange(0, msg.length)];
        
        _blinkLabel.fontSize = 15;
        _blinkLabel.foregroundColor = UIColor.whiteColor.CGColor;
        _blinkLabel.string = msg;
    } else{
        _blinkLabel.fontSize = fontSize;
        _blinkLabel.foregroundColor = color;
        _blinkLabel.string = message;
    }
}

- (void)displayBlinkMessage {
    self.blinkLabel = [CATextLayer layer];
    _blinkLabel.frame = [self getBlinkMessageRect];
    _blinkLabel.contentsScale = [UIScreen mainScreen].scale;
    _blinkLabel.alignmentMode = kCAAlignmentCenter;
    _blinkLabel.foregroundColor = UIColor.whiteColor.CGColor;
    [self addMessage];
    [_videoPreviewLayer addSublayer:_blinkLabel];
}

- (CGRect)getBlinkMessageRect {
    CGFloat width = 330.f;
    CGFloat height = 55.f;
    CGRect mainViewFrame = [self getViewFrame];
    
    return CGRectMake(mainViewFrame.origin.x + mainViewFrame.size.width/2.f-width/2.f,
                      0.06f*mainViewFrame.size.height, width, height);
}

// MARK: - AcuantHGLiveFaceCaptureDelegate

- (void)liveFaceDetailsCapturedWithLiveFaceDetails:(LiveFaceDetails *)liveFaceDetails
                                          faceType:(enum AcuantFaceType)faceType {
    if ([self shouldSkipFrame:liveFaceDetails faceType:faceType]) {
        return;
    }

    switch (faceType) {
        case AcuantFaceTypeNONE:
            [self addMessage];
            break;
        case AcuantFaceTypeFACE_TOO_CLOSE:
            [self addMessage:@"Too Close! Move Away"];
            break;
        case AcuantFaceTypeFACE_TOO_FAR:
            [self addMessage:@"Move Closer"];
            break;
        case AcuantFaceTypeFACE_NOT_IN_FRAME:
            [self addMessage:@"Move in Frame"];
            break;
        case AcuantFaceTypeFACE_GOOD_DISTANCE:
            [self addMessage:@"Blink!" color:UIColor.greenColor.CGColor];
            break;
        case AcuantFaceTypeFACE_MOVED:
            [self addMessage:@"Hold Steady"];
            break;
    }

    if (liveFaceDetails.faceRect && liveFaceDetails.cleanAperture) {
        CGRect rect = liveFaceDetails.faceRect.toCGRect;
        CGRect totalSize = liveFaceDetails.cleanAperture.toCGRect;
        CGRect scaled = CGRectMake((rect.origin.x - 150)/totalSize.size.width,
                                   1-((rect.origin.y)/totalSize.size.height + (rect.size.height)/totalSize.size.height),
                                   (rect.size.width + 150)/totalSize.size.width, (rect.size.height)/totalSize.size.height);
        CGRect faceRect = [_videoPreviewLayer rectForMetadataOutputRectOfInterest:scaled];
        
        _faceOval.hidden = NO;
        _faceOval.path = [UIBezierPath bezierPathWithRect:faceRect].CGPath;

        if (liveFaceDetails.isLiveFace && !_captured) {
            _captured = YES;
            [_delegate liveFaceCapturedWithImage:liveFaceDetails.image];
        }
    } else if(!liveFaceDetails || !liveFaceDetails.faceRect) {
        _faceOval.hidden = YES;
    }
}

@end
