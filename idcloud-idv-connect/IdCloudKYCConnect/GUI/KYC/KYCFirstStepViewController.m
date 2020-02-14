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

#import "KYCFirstStepViewController.h"

@interface KYCFirstStepViewController ()

@property (nonatomic, weak) IBOutlet UILabel        *labelDescription;
@property (nonatomic, weak) IBOutlet UIStackView    *stackSteps;
@property (nonatomic, weak) IBOutlet IdCloudButton  *buttonNext;

@end

@implementation KYCFirstStepViewController

// MARK: - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Remove current setup.
    for (UIView *loopView in _stackSteps.arrangedSubviews) {
        [_stackSteps removeArrangedSubview:loopView];
        [loopView removeFromSuperview];
    }
    
    // Animate label
    CGFloat delay = .0f;
    [IdCloudHelper animateView:_labelDescription inParent:self.view withDelay:&delay];
    
    // Add new chevrons based on configuration.
    [self addChevronWithCaption:TRANSLATE(@"STRING_KYC_FIRST_STEP_ID")
                      imageName:@"KYC_FirstStep_IdRed"
                          delay:&delay];
    if ([KYCManager sharedInstance].facialRecognition) {
        [self addChevronWithCaption:TRANSLATE(@"STRING_KYC_FIRST_STEP_FACE")
                          imageName:@"KYC_FirstStep_PersonRed"
                              delay:&delay];
    }
    [self addChevronWithCaption:TRANSLATE(@"STRING_KYC_FIRST_STEP_REVIEW")
                      imageName:@"KYC_FirstStep_CheckRed"
                          delay:&delay];
    
    [IdCloudHelper animateView:_buttonNext inParent:self.view withDelay:kZeroDelay];
}

// MARK: - Private Helpers

- (void)addChevronWithCaption:(NSString *)caption
                    imageName:(NSString *)imageName
                        delay:(CGFloat *)delay {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [UIImageView new];
    [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageView.widthAnchor constraintEqualToConstant:image.size.width].active = YES;
    [imageView.heightAnchor constraintEqualToConstant:image.size.height].active = YES;
    [imageView setImage:image];
    
    UILabel *labelCaption = [[UILabel alloc] initWithFrame:CGRectZero];
    [labelCaption setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f]];
    [labelCaption setTextColor:[UIColor colorNamed:@"TextPrimary"]];
    [labelCaption setTextAlignment:NSTextAlignmentLeft];
    [labelCaption setText:caption];
    
    UIStackView *stackToAdd = [[UIStackView alloc] initWithArrangedSubviews:@[imageView, labelCaption]];
    [stackToAdd setAxis:UILayoutConstraintAxisHorizontal];
    [stackToAdd setAlignment:UIStackViewAlignmentFill];
    [stackToAdd setDistribution:UIStackViewDistributionFill];
    [stackToAdd setSpacing:8.f];
    
    [_stackSteps addArrangedSubview:stackToAdd];
    
    // Animate
    [IdCloudHelper animateView:stackToAdd inParent:self.view withDelay:delay];
}


@end
