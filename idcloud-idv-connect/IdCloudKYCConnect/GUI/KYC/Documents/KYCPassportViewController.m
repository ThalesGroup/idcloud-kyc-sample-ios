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

#import "KYCPassportViewController.h"
#import "KYCIdCardPassportViewController.h"

@interface KYCPassportViewController ()

@property (nonatomic, weak) IBOutlet UIImageView    *imageDescription01;
@property (nonatomic, weak) IBOutlet UIImageView    *imageDescription02;
@property (nonatomic, weak) IBOutlet UILabel        *labelQuestion;
@property (nonatomic, weak) IBOutlet UIStackView    *stackButtons;

@end

@implementation KYCPassportViewController

// MARK: - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Skip animation during direct transition from doc scaner to face tutorial etc.
    if (self.shouldAnimate) {
        CGFloat delay = .0f;
        [IdCloudHelper animateView:_imageDescription01 inParent:self.view withDelay:&delay];
        [IdCloudHelper animateView:_imageDescription02 inParent:self.view withDelay:&delay];
        [IdCloudHelper animateView:_labelQuestion inParent:self.view withDelay:&delay];
        [IdCloudHelper animateView:_stackButtons inParent:self.view withDelay:kZeroDelay];
    }
    self.shouldAnimate = YES;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueStandardPassport"]) {
        KYCIdCardPassportViewController *destination = segue.destinationViewController;
        destination.type = KYCDocumentTypePassport;
    }
}

@end
