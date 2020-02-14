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

#import "IdCloudNumberTVC.h"
#import "AppDelegate.h"

@interface IdCloudNumberTVC()

@property (nonatomic, weak) IBOutlet UILabel        *labelTitle;
@property (nonatomic, weak) IBOutlet UILabel        *labelSubtitle;
@property (nonatomic, weak) IBOutlet UITextField    *value;

@property (nonatomic, weak) IdCloudOption     *currentOption;

@end

@implementation IdCloudNumberTVC

@synthesize enabled = _enabled;

// MARK: - Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setBackgroundColor:[UIColor clearColor]];
    [self.backgroundView setBackgroundColor:[UIColor clearColor]];
    
    _value.layer.cornerRadius       = 8.f;
    _value.layer.borderColor        = [UIColor grayColor].CGColor;
    _value.layer.borderWidth        = 1.f;
    _value.userInteractionEnabled   = NO;
    
    // Add apply + cancel button to number cell text input.
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.items = @[
                            [[UIBarButtonItem alloc] initWithTitle:TRANSLATE(@"STRING_COMMON_CANCEL")
                                                             style:UIBarButtonItemStylePlain
                                                            target:self action:@selector(onButtonPressedCancel)],
                            
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                          target:nil action:nil],
                            
                            [[UIBarButtonItem alloc] initWithTitle:TRANSLATE(@"STRING_COMMON_OK")
                                                             style:UIBarButtonItemStyleDone
                                                            target:self action:@selector(onButtonPressedOk)]
                            ];
    [numberToolbar sizeToFit];
    _value.inputAccessoryView = numberToolbar;
    
    _enabled = YES;
}

// MARK: - KYCCellProtocol

- (void)onUserTap {
    if (_enabled) {
        [self enableUserInteraction:NO];
        [_value becomeFirstResponder];
    }
}

- (void)updateWithOption:(IdCloudOption *)option {
    self.currentOption = option;
    
    [_labelTitle    setText:option.titleCaption];
    [_labelSubtitle setText:option.titleDescription];
    
    id  target      = option.target;
    SEL selector    = option.selectorGet;
    if ([target respondsToSelector:selector]) {
        NSInteger value = ((NSInteger (*)(id, SEL))[target methodForSelector:selector])(target, selector);
        [_value setText:[NSString stringWithFormat:@"%ld", (long)value]];
    } else {
        // Incorrect selector configuration in KYCManager.init
        assert(false);
    }
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    
    [_labelTitle    setEnabled:enabled];
    [_labelSubtitle setEnabled:enabled];
    [_value         setEnabled:enabled];
}

// MARK: - Private Helpers

- (void)enableUserInteraction:(BOOL)enable {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.window.rootViewController.view setUserInteractionEnabled:enable];
    
    // Textfiled should be disabled so we will handle cell select on one place.
    // But also must be reanabled to allow keyboard at all.
    [_value setUserInteractionEnabled:!enable];

}

// MARK: - User Interface

- (void)onButtonPressedCancel {
    [self enableUserInteraction:YES];
    [_value resignFirstResponder];
    
    // Reload original value.
    if (_currentOption) {
        [self updateWithOption:_currentOption];
    }
}

- (void)onButtonPressedOk {
    [self enableUserInteraction:YES];
    [_value resignFirstResponder];
    if (_currentOption) {
        id  target      = _currentOption.target;
        SEL selector    = _currentOption.selectorSet;
        if ([target respondsToSelector:selector]) {
            // Fit value to defined range.
            NSInteger value = [_value.text integerValue];
            value = MAX(MIN(_currentOption.maxValue, value), _currentOption.minValue);
            ((void (*)(id, SEL, NSInteger))[target methodForSelector:selector])(target, selector, value);
        } else {
            // Incorrect selector configuration in KYCManager.init
            assert(false);
        }
        
        // Reload saved value to ensure correct parsing.
        [self updateWithOption:_currentOption];
    }
}

@end
