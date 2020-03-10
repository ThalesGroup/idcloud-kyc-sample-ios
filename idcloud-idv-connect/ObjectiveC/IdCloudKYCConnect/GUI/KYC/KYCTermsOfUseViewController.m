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

#import "KYCTermsOfUseViewController.h"

@interface KYCTermsOfUseViewController()
@property (nonatomic, weak) IBOutlet UILabel    *labelCaption;
@property (nonatomic, weak) IBOutlet UILabel    *labelDescription;
@property (nonatomic, weak) IBOutlet UITextView *labelDescription2;

@end

@implementation KYCTermsOfUseViewController

// MARK: - Life Cycle

+ (instancetype)viewController {
    KYCTermsOfUseViewController *retValue = CreateVC(@"KYC", self);
    return retValue;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Animate label
    CGFloat delay = .0f;
    [IdCloudHelper animateView:_labelDescription inParent:self.view withDelay:&delay];
    [IdCloudHelper animateView:_labelDescription2 inParent:self.view withDelay:&delay];
}

@end
