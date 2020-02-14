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

#import "KYCPrivacyPolicyViewController.h"
#import "KYCTermsOfUseViewController.h"

@interface KYCPrivacyPolicyViewController()
@property (nonatomic, weak) IBOutlet UILabel        *labelCaption;
@property (nonatomic, weak) IBOutlet UILabel        *labelDescription;
@property (nonatomic, weak) IBOutlet UIImageView    *imageLock;
@property (nonatomic, weak) IBOutlet UIButton       *buttonPrivacyPolicy;
@property (nonatomic, weak) IBOutlet UIButton       *buttonTermsOfUse;

@end

@implementation KYCPrivacyPolicyViewController

// MARK: - Life Cycle

+ (instancetype)viewController {
    KYCPrivacyPolicyViewController *retValue = CreateVC(@"KYC", self);
    return retValue;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Animate label
    CGFloat delay = .0f;
    [IdCloudHelper animateView:_imageLock inParent:self.view withDelay:&delay];
    [IdCloudHelper animateView:_labelDescription inParent:self.view withDelay:&delay];
    [IdCloudHelper animateView:_buttonPrivacyPolicy inParent:self.view withDelay:&delay];
    [IdCloudHelper animateView:_buttonTermsOfUse inParent:self.view withDelay:&delay];
}

// MARK: - User Interface

- (IBAction)onButtonPressedPrivacyPolicy:(UIButton *)sender {
    if (CFG_PRIVACY_POLICY_URL) {
        [[UIApplication sharedApplication] openURL:CFG_PRIVACY_POLICY_URL options:@{} completionHandler:nil];
    }
}

- (IBAction)onButtonPressedTermsOfUse:(UIButton *)sender {
    [self  presentViewController:[KYCTermsOfUseViewController viewController] animated:YES completion:nil];
}

@end
