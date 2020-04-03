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

#import "KYCDocumentScannerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AcuantCamera/AcuantCamera-Swift.h>
#import <AcuantCommon/AcuantCommon-Swift.h>
#import <AcuantImagePreparation/AcuantImagePreparation-Swift.h>
#import <AcuantIPLiveness/AcuantIPLiveness-Swift.h>
#import "KYCFaceIdTutorialViewController.h"
#import "KYCOverviewViewController.h"

@interface KYCDocumentScannerViewController () <CameraCaptureDelegate>

@property (nonatomic, assign) KYCDocumentType documentType;

@end

@implementation KYCDocumentScannerViewController

// MARK: - Life Cycle

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        _shouldAnimate = YES;
    }
    
    return self;
}

// MARK: - Public API

- (void)showDocumentScan:(KYCDocumentType)type {
    _documentType = type;
    
    [self showDocumentCaptureCamera];
}

// MARK: - Private Helpers

- (void)nextStepAfterDocumentScanning {
    if ([KYCManager sharedInstance].facialRecognition) {
        [self presentViewController:[KYCFaceIdTutorialViewController viewController] animated:YES completion:nil];
    } else {
        [self presentViewController:[KYCOverviewViewController viewController] animated:YES completion:nil];
    }
}

- (void)requestAccesSync:(void (^)(void))handler {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                handler();
            } else {
                notifyDisplay(@"Camera access is absolutely necessary to use this app", NotifyTypeError);
            }
        });
    }];
}

- (AcuantCameraOptions *)getCameraOptions {
    return [[AcuantCameraOptions alloc] initWithTimeInMsPerDigit:900
                                                    digitsToShow:2
                                                        allowBox:YES
                                                     autoCapture:YES
                                               hideNavigationBar:YES
                                       bracketLengthInHorizontal:80
                                         bracketLengthInVertical:50
                                       defaultBracketMarginWidth:.5f
                                      defaultBracketMarginHeight:.6f
                                                       colorHold:UIColor.yellowColor.CGColor
                                                  colorCapturing:UIColor.greenColor.CGColor
                                               colorBracketAlign:UIColor.blackColor.CGColor
                                              colorBracketCloser:UIColor.redColor.CGColor
                                                colorBracketHold:UIColor.yellowColor.CGColor
                                             colorBracketCapture:UIColor.greenColor.CGColor];
}

- (void)showDocumentCaptureCamera {
    [self requestAccesSync:^{
        DocumentCameraController *documentCameraController = [DocumentCameraController getCameraControllerWithDelegate:self
                                                                                                         cameraOptions:[self getCameraOptions]];
        documentCameraController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:documentCameraController animated:YES completion:nil];
    }];
}

- (Image *)getCropedImage:(Image *)image {
    CroppingData *data = [CroppingData new];
    data.image = image.image;
    
    return [AcuantImagePreparation cropWithData:data];
}

- (void)tryAgainWithMessage:(NSString *)message {
    [self displayOnCancelDialog:@"Try Again"
                        message:message
                       okButton:@"Try Again"
                   cancelButton:@"Cancel"
              completionHandler:^(BOOL result) {
        if (result) {
            [self showDocumentCaptureCamera];
        }
    }];
}

// MARK: - CameraCaptureDelegate

- (void)setCapturedImageWithImage:(Image * _Nonnull)image
                    barcodeString:(NSString *)barcodeString {
    // Hide current scanner.
    _shouldAnimate = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Get manager and crop image.
    KYCManager  *manager        = [KYCManager sharedInstance];
    Image       *croppedImage   = [self getCropedImage:image];
    
    if (!croppedImage.image || (croppedImage.error && croppedImage.error.errorCode == AcuantErrorCodes.ERROR_LowResolutionImage)) {
        [self tryAgainWithMessage:croppedImage.error.errorDescription];
    } else {
        // Check image sharpness, glare and minimum DPI.
        NSInteger sharpness = [AcuantImagePreparation sharpnessWithImage:croppedImage.image];
        NSInteger glare     = [AcuantImagePreparation glareWithImage:croppedImage.image];
        if (sharpness < CaptureConstants.SHARPNESS_THRESHOLD || glare < CaptureConstants.GLARE_THRESHOLD ||
            croppedImage.dpi < CaptureConstants.MANDATORY_RESOLUTION_THRESHOLD_SMALL) {
            NSString *message = [NSString stringWithFormat:@"Image did not meet basic criteria.\nSharpness: %ld(%ld)\nGlare: %ld(%ld)\nDPI: %ld(%ld)",
                                 sharpness, CaptureConstants.SHARPNESS_THRESHOLD,
                                 glare, CaptureConstants.GLARE_THRESHOLD,
                                 croppedImage.dpi, CaptureConstants.MANDATORY_RESOLUTION_THRESHOLD_SMALL];
            [self tryAgainWithMessage:message];
        } else {
            UIImage *scaledImage = croppedImage.image;
            if (scaledImage.size.width > KYCManager.sharedInstance.maxImageWidth) {
                scaledImage = [IdCloudHelper imageWithImage:scaledImage scaledToWidth:KYCManager.sharedInstance.maxImageWidth];
            }
            
            NSData *croppedImageData = UIImageJPEGRepresentation(scaledImage, 1.f);
            // Update current step.
            if (_documentType == KYCDocumentTypeIdCard && manager.scannedDocFront) {
                manager.scannedDocBack = croppedImageData;
                [self nextStepAfterDocumentScanning];
            } else {
                manager.scannedDocFront = croppedImageData;
                if (_documentType == KYCDocumentTypePassport) {
                    [self nextStepAfterDocumentScanning];
                } else {
                    // First page is scanned continue with another one.
                    [self showDocumentCaptureCamera];
                }
            }
        }
    }
}

@end
