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

#import "IdCloudSegmentTVC.h"

@interface IdCloudSegmentTVC()

@property (nonatomic, weak) IBOutlet UILabel            *labelTitle;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentValue;

@property (nonatomic, weak) IdCloudOption         *currentOption;

@end

@implementation IdCloudSegmentTVC

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
    // Ignore
}

- (void)updateWithOption:(IdCloudOption *)option {
    self.currentOption = option;

    [_labelTitle    setText:option.titleCaption];
    
    // Reload segments
    [_segmentValue removeAllSegments];
    for (NSNumber *loopKey in _currentOption.options.allKeys) {
        [_segmentValue insertSegmentWithTitle:_currentOption.options[loopKey]
                                      atIndex:_segmentValue.numberOfSegments
                                     animated:NO];
    }
    
    id  target      = option.target;
    SEL selector    = option.selectorGet;
    if ([target respondsToSelector:selector]) {
        NSInteger value = ((NSInteger (*)(id, SEL))[target methodForSelector:selector])(target, selector);
        [_segmentValue setSelectedSegmentIndex:value];
    } else {
        // Incorrect selector configuration in KYCManager.init
        assert(false);
    }
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    [_labelTitle    setEnabled:enabled];
    [_segmentValue  setEnabled:enabled];
}

// MARK: - User Interface

- (IBAction)onSegmentChanged:(UISegmentedControl *)sender {
    if (_currentOption) {
        id  target      = _currentOption.target;
        SEL selector    = _currentOption.selectorSet;
        if ([target respondsToSelector:selector]) {
            ((void (*)(id, SEL, NSInteger))[target methodForSelector:selector])(target, selector, sender.selectedSegmentIndex);
        } else {
            // Incorrect selector configuration in KYCManager.init
            assert(false);
        }
    }
}


@end
