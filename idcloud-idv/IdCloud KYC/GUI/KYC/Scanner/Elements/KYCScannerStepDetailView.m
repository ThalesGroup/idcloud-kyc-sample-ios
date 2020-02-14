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

#import "KYCScannerStepDetailView.h"

// Side menu transition animation duration in seconds
#define kAnimationDuration      .75f

@interface KYCScannerStepDetailView()

@property (nonatomic, weak)     IBOutlet UILabel            *labelTop;
@property (nonatomic, weak)     IBOutlet UIImageView        *image;
@property (nonatomic, weak)     IBOutlet UILabel            *labelBottom;

@property (nonatomic, weak)     id<KYCScannerStepProtocol>  delegate;
@property (nonatomic, assign)   CGAffineTransform           transformHidden;
@property (nonatomic, assign)   CGAffineTransform           transformVisible;
@property (nonatomic, assign)   KYCStepAnimation            animation;

@property (nonatomic, strong)   UIImage                     *animOriginalImage;
@property (nonatomic, strong)   UIImage                     *animFlippedImage;

@end

@implementation KYCScannerStepDetailView

// MARK: - Life Cycle

+ (instancetype)stepWithStepData:(KYCScannerStep *)step
                        delegate:(id<KYCScannerStepProtocol>)delegate {
    CGRect frame = [UIScreen mainScreen].bounds;
    if (![KYCManager sharedInstance].cameraOrientation) {
        // Transform to landscape mode.
        frame.origin.x = frame.size.width * .5f - frame.size.height * .5f;
        frame.size.width = frame.size.height;
    }
    
    KYCScannerStepDetailView* retValue = [[KYCScannerStepDetailView alloc] initWithFrame:frame];

    UIImage *image              = step.overlayIcon ? [UIImage imageNamed:step.overlayIcon] : nil;
    UIImage *imageAnim          = step.overlayAnimationImage ? [UIImage imageNamed:step.overlayAnimationImage] : nil;
    retValue.delegate           = delegate;
    retValue.labelTop.text      = step.overlayCaptionTop;
    retValue.image.image        = image;
    retValue.labelBottom.text   = step.overlayCaptionBottom;
    retValue.animation          = step.overlayAnimation;

    switch (step.overlayAnimation) {
        case KYCStepAnimationFlipHorizontally:
        {
            retValue.animOriginalImage  = image;
            retValue.animFlippedImage   = [UIImage imageWithCGImage:imageAnim.CGImage
                                                              scale:imageAnim.scale
                                                        orientation:UIImageOrientationUpMirrored];
        }   break;
        case KYCStepAnimationNone:
            break;
    }
    
    [IdCloudHelper unifyLabelsToSmallestSize:retValue.labelTop, retValue.labelBottom, nil];
    
    return retValue;
}

- (void)initXIB {
    [super initXIB];
    
    // Hide view on user tap.
    [_image setUserInteractionEnabled:YES];
    [_image addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                         action:@selector(onUserTap:)]];
    self.transformVisible = self.transform;
}

// MARK: - Public API

- (void)showDetailFromFrame:(CGRect)frame {
    
    // Move to destination frame position.
    CGFloat moveX = CGRectGetMidX(frame) - CGRectGetMidX(self.frame);
    CGFloat moveY = CGRectGetMidY(frame) - CGRectGetMidY(self.frame);
    self.transformHidden = CGAffineTransformTranslate(_transformVisible, moveX, moveY);
    
    // Scale to destination frame size.
    CGFloat scaleX = frame.size.width / self.bounds.size.width;
    CGFloat scaleY = frame.size.height / self.bounds.size.height;
    self.transformHidden = CGAffineTransformScale(_transformHidden, scaleX, scaleY);
    
    self.alpha      = .0f;
    self.transform  = _transformHidden;
    [UIView animateWithDuration:kAnimationDuration
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.transform  = self.transformVisible;
                         self.alpha      = 1.f;
                     } completion:^(BOOL finished) {
                         [self.delegate onDetailStepDisplayed];
                         
                         // Animate rotation if defined.
                         switch (self.animation) {
                             case KYCStepAnimationFlipHorizontally:
                                 [self animateHorizontalFlip];
                                 // Auto hide detail after certain time period. 
                                 [self performSelector:@selector(hideDetail) withObject:nil afterDelay:4];
                                 break;
                             case KYCStepAnimationNone:
                                 // Auto hide detail after certain time period.
                                 [self performSelector:@selector(hideDetail) withObject:nil afterDelay:3];
                                 break;
                         }
                     }];
}

- (void)hideDetail {
    // Cancel scheduled autohide
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideDetail) object:nil];
    
    [_delegate onDetailStepBeforeHide];
    
    // Cancel all current animations
    [self.layer removeAllAnimations];
    
    [UIView animateWithDuration:kAnimationDuration
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.5
                        options:0
                     animations:^{
                         self.transform  = self.transformHidden;
                         self.alpha      = .0f;
                     } completion:^(BOOL finished) {
                         [self removeFromSuperview];
                         [self.delegate onDetailStepAfterHide];
                     }];
}

// MARK: - Private Helpers

- (void)animateHorizontalFlip {
    CABasicAnimation* animation     = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    animation.fromValue             = @(0);
    animation.toValue               = @(M_PI);
    animation.repeatCount           = 1;
    animation.duration              = 2.f;
    animation.fillMode              = kCAFillModeForwards;
    animation.removedOnCompletion   = NO;
    animation.timingFunction        = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.image.layer addAnimation:animation forKey:@"rotation"];

    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 1.0 / 500.0;
    self.image.layer.transform = transform;

    [self performSelector:@selector(animateHorizontalFlip_SwapImage)
               withObject:nil afterDelay:animation.duration * .5f];
}

- (void)animateHorizontalFlip_SwapImage {
    _image.image = _animFlippedImage;
}

// MARK: - User Interface

- (void)onUserTap:(UITapGestureRecognizer *)recognizer {
    [self hideDetail];
}

@end
