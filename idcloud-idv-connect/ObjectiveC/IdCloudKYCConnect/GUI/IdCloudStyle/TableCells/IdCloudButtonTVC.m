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

#import "IdCloudButtonTVC.h"

@interface IdCloudButtonTVC()

@property (nonatomic, weak) IBOutlet UIButton   *button;
@property (nonatomic, weak) IdCloudOption *currentOption;

@end

@implementation IdCloudButtonTVC

@synthesize enabled = _enabled;

// MARK: - Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self.backgroundView setBackgroundColor:[UIColor clearColor]];
    
    _enabled = YES;
}

// MARK: - KYCCellProtocol

- (void)onUserTap {
    if (_currentOption) {
        id  target      = _currentOption.target;
        SEL selector    = _currentOption.selectorButton;
        if ([target respondsToSelector:selector]) {
            ((void (*)(id, SEL))[target methodForSelector:selector])(target, selector);
        } else {
            // Incorrect selector configuration in KYCManager.init
            assert(false);
        }
    }
}

- (void)updateWithOption:(IdCloudOption *)option {
    self.currentOption = option;
    
    [_button setTitle:option.titleCaption forState: UIControlStateNormal];
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    
    [_button setEnabled:enabled];
}

// MARK: - User Interface

- (IBAction)onButtonPressed:(UIButton *)sender {
    [self onUserTap];
}

@end
