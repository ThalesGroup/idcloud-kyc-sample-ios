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

#import "KYCIntroViewController.h"
#import "SideMenuViewController.h"

#define kSequeNextPage      @"sequeOpenNextPage"

@interface KYCIntroViewController ()

@property (nonatomic, weak) IBOutlet UILabel        *labelInit;
@property (nonatomic, weak) IBOutlet IdCloudButton  *buttonNext;

@end

@implementation KYCIntroViewController

// MARK: - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Notifications about data layer change to reload table.
    // Unregistration is done in base class.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData)
                                                 name:kNotificationDataLayerChanged
                                               object:nil];
    
    [self reloadData];
}

// MARK: - Private Helpers

- (void)reloadData {
    // Web token is set.
    if ([KYCManager sharedInstance].jsonWebToken) {
        _labelInit.hidden = YES;
        [_buttonNext setTitle:TRANSLATE(@"STRING_KYC_INTRO_BUTTON_NEXT") forState: UIControlStateNormal];
    } else {
        _labelInit.hidden = NO;
        [_buttonNext setTitle:TRANSLATE(@"STRING_KYC_INTRO_BUTTON_SCANN") forState: UIControlStateNormal];
    }
}

// MARK: - User Interface

- (IBAction)onButtonPressedSettings:(UIButton *)sender {
    SideMenuViewController *sideMenu = (SideMenuViewController *)self.parentViewController;
    [sideMenu menuDisplay];
}
- (IBAction)onButtonPressedNext:(IdCloudButton *)sender {
    if ([KYCManager sharedInstance].jsonWebToken) {
        [self performSegueWithIdentifier:kSequeNextPage sender:nil];
    } else {
        [[KYCManager sharedInstance] displayQRcodeScannerForInit];
    }
}

@end
