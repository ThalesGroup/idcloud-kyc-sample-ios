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

#import "KYCFaceIdTutorialViewController.h"

@interface KYCFaceIdTutorialViewController () <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet IdCloudButton      *buttonNext;
@property (nonatomic, weak) IBOutlet UIImageView        *imageExample;
@property (nonatomic, weak) IBOutlet UIImageView        *imageGood;
@property (nonatomic, weak) IBOutlet UIScrollView       *imageBad;
@property (nonatomic, weak) IBOutlet UILabel            *labelDescription;
@property (nonatomic, weak) IBOutlet UIImageView        *imageTutorialHand;
@property (nonatomic, assign) BOOL                      animateHand;

@end

@implementation KYCFaceIdTutorialViewController

// MARK: - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    // Animate label
    CGFloat delay = .0f;
    [IdCloudHelper animateView:_labelDescription inParent:self.view withDelay:&delay];
    [IdCloudHelper animateView:_imageGood inParent:self.view withDelay:&delay];
    [IdCloudHelper animateView:_imageBad inParent:self.view withDelay:&delay];
    [IdCloudHelper animateView:_imageExample inParent:self.view withDelay:&delay];
    [IdCloudHelper animateView:_buttonNext inParent:self.view withDelay:kZeroDelay];
    
    self.animateHand = YES;
    _imageTutorialHand.alpha = .0f;
    
    _imageBad.delegate = self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_animateHand) {
        // Animate hand move
        // First move it to 25% of table height
        CGFloat             tableHeight         = _imageBad.bounds.size.height;
        CGAffineTransform   originalPosition    = CGAffineTransformTranslate(_imageBad.transform, .0f, -tableHeight * .25f);
        _imageTutorialHand.transform    = originalPosition;
        
        [self animateShowMoveUpAndHide:1.f handler:nil];
        
        self.animateHand = NO;
    }
}

// MARK: - Private Helpers

- (void)animateShowMoveUpAndHide:(CGFloat)delay handler:(void (^)(BOOL finished))handler {
    CGFloat tableHeight = _imageBad.bounds.size.height;
    
    [self animateHandAlpha:1.f delay:delay duration:.75f handler:^(BOOL finished) {
        if (finished) {
            [self animateHandMove:tableHeight * .55f delay:.0f duration:2.f handler:^(BOOL finished) {
                if (finished) {
                    [self animateHandAlpha:.0f delay:.0f duration:1.5f handler:handler];
                }
            }];
        }
    }];
}

- (void)animateHandAlpha:(CGFloat)alpha
                   delay:(CGFloat)delay
                duration:(CGFloat)duration
                 handler:(void (^)(BOOL finished))handler {
    
    [UIView animateWithDuration:duration
                          delay:delay
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.imageTutorialHand.alpha = alpha;
                     } completion:handler];
}

- (void)animateHandMove:(CGFloat)offset
                  delay:(CGFloat)delay
               duration:(CGFloat)duration
                handler:(void (^)(BOOL finished))handler {
    
    CGAffineTransform transform = CGAffineTransformTranslate(_imageTutorialHand.transform, .0f, -offset);
    
    [UIView animateWithDuration:duration
                          delay:delay
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
//                         self.tableExamples.contentOffset = CGPointMake(0, offset);
                         self.imageTutorialHand.transform = transform;
                     } completion:handler];
}

// MARK: - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // Disable horizontal scroll;
    sender.contentOffset = CGPointMake(.0f, sender.contentOffset.y);
}
 
@end
