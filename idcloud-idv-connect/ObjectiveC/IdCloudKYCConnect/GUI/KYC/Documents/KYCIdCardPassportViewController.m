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

#import "KYCIdCardPassportViewController.h"

@interface KYCIdCardPassportViewController ()

@property (nonatomic, weak) IBOutlet UILabel        *labelCaption;
@property (nonatomic, weak) IBOutlet UILabel        *labelDescription01;
@property (nonatomic, weak) IBOutlet UIImageView    *imageDescription01;
@property (nonatomic, weak) IBOutlet UILabel        *labelDescription02;
@property (nonatomic, weak) IBOutlet UIImageView    *imageDescription02;
@property (nonatomic, weak) IBOutlet IdCloudButton  *buttonNext;

@end

@implementation KYCIdCardPassportViewController

// MARK: - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    // Update screen based on configuration
    _labelCaption.text          = [self caption];
    _labelDescription01.text    = [self labelForIndex:1];
    _labelDescription02.text    = [self labelForIndex:2];
    _imageDescription01.image   = [self imageForIndex:1];
    _imageDescription02.image   = [self imageForIndex:2];
    
    // Skip animation during direct transition from doc scaner to face tutorial etc.
    if (self.shouldAnimate) {
        CGFloat delay = .0f;
        [IdCloudHelper animateView:_labelDescription01 inParent:self.view withDelay:&delay];
        [IdCloudHelper animateView:_imageDescription01 inParent:self.view withDelay:&delay];
        [IdCloudHelper animateView:_labelDescription02 inParent:self.view withDelay:&delay];
        [IdCloudHelper animateView:_imageDescription02 inParent:self.view withDelay:&delay];
        [IdCloudHelper animateView:_buttonNext inParent:self.view withDelay:kZeroDelay];
    }
    self.shouldAnimate = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Make sure that autoresized labels does have same size.
    [IdCloudHelper unifyLabelsToSmallestSize:_labelDescription01, _labelDescription02, nil];
}

// MARK: - Private Helpers

- (NSString *)caption {
    if (_type == KYCDocumentTypePassport) {
        return TRANSLATE(@"STRING_KYC_DOC_SCAN_CAPTION_PASSPORT");
    } else {
        return TRANSLATE(@"STRING_KYC_DOC_SCAN_CAPTION_IDCARD");
    }
}

- (NSString *)labelForIndex:(NSInteger)index {
    NSString    *stringKey  = [NSString stringWithFormat:@"STRING_KYC_DOC_SCAN_%02ld_AUTO", (long)index];
    
    return TRANSLATE(stringKey);
}

-(UIImage *)imageForIndex:(NSInteger)index {
    NSString    *type       = _type == KYCDocumentTypePassport ? @"Passport" : @"IdCard";
    NSString    *imageName  = [NSString stringWithFormat:@"KYC_ThirdStep_%@_%02ld_Auto", type, (long)index];
    
    return [UIImage imageNamed:imageName];
}

// MARK: - User Interface

- (IBAction)onButtonPressedNext:(IdCloudButton *)sender {
    [self showDocumentScan:_type];
}

@end
