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

#import "KYCScannerNotification.h"

#define kAnimationSpeed     .3f
#define kFramePadding       16.f

#define kIconInfoName       @"IdCloudNotificationInfo"
#define kIconWarningName    @"IdCloudNotificationWarning"
#define kIconErrorName      @"IdCloudNotificationError"

@interface KYCScannerNotification()

@property (nonatomic, assign)   CGFloat                         screenOffset;

@property (nonatomic, strong)   UIImageView                     *imageView;
@property (nonatomic, strong)   UILabel                         *labelCaption;

@property (nonatomic, assign)   BOOL                            runningAction;
@property (nonatomic, strong)   NSMutableArray<NotifyAction *>  *scheduledActions;

@end

@implementation KYCScannerNotification

// MARK: - Life Cycle

+ (instancetype)notificationWithScreenOffset:(CGFloat)offset {
    return [[KYCScannerNotification alloc] initWithScreenOffset:offset];
}

- (instancetype)initWithScreenOffset:(CGFloat)offset {
    if (self = [super initWithFrame:[UIScreen mainScreen].bounds]) {
        self.screenOffset = offset;
        [self initXIB];
    }
    
    return self;
}

- (void)initXIB {
    // There is no running action by default and state is hidden.
    self.runningAction          = NO;
    self.scheduledActions       = [NSMutableArray new];
    
    // Load all gui elements.
    [self initGUI];
}

// MARK: - Public API

- (void)display:(NSString *)message
           type:(NotifyType)type {
    // First make sure that view is in correct state.
    [self scheduleHideIfNeeded];
    
    // Schedule new message show.
    [_scheduledActions addObject:[NotifyAction actionShow:message type:type]];
    
    // Trigger queue processing.
    [self proccessQueue];
}

- (void)displayErrorIfExists:(NSError *)error {
    if (error) {
        [self display:error.localizedDescription type:NotifyTypeError];
    }
}

- (void)hide {
    
    // Schedule hide if it's not already.
    [self scheduleHideIfNeeded];
    
    // Trigger queue processing.
    [self proccessQueue];
}

// MARK: - Private Helpers

- (void)initGUI {
    self.opaque             = NO;
    self.cornerRadius       = 10.f;
    self.backgroundColor    = [UIColor colorWithRed:0 green:0 blue:0 alpha:.5f];

    // Prepare UI
    UIImage *image = [NotifyAction NotifyTypeImage:NotifyTypeWarning];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(.0f, .0f, image.size.width, image.size.height)];
    [_imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_imageView setImage:image];
    [self addSubview:_imageView];
    
    self.labelCaption = [[UILabel alloc] initWithFrame:CGRectZero];
    [_labelCaption setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f]];
    [_labelCaption setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_labelCaption setNumberOfLines:10];
    [_labelCaption setTextAlignment:NSTextAlignmentCenter];
    [_labelCaption setTextColor:[UIColor whiteColor]];
    [self addSubview:_labelCaption];
    
    // Keep image size all the time
    [_imageView.widthAnchor constraintEqualToConstant:image.size.width].active = YES;
    [_imageView.heightAnchor constraintEqualToConstant:image.size.height].active = YES;
    // Move image kFramePadding points from super view left side.
    [_imageView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:kFramePadding].active = YES;
    // Center image vertically.
    [_imageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
    
    // Make space between image and label kFramePadding points.
    [_labelCaption.leftAnchor constraintEqualToAnchor:_imageView.rightAnchor constant:kFramePadding].active = YES;
    // Label should be kFramePadding points from right side.
    [_labelCaption.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-kFramePadding].active = YES;
    // Center label vertically.
    [_labelCaption.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
    
    // Hide view by default.
    [self setHidden:YES];
}

- (void)scheduleHideIfNeeded {
    // Schedule hide if last scheduled action is not that one already.
    // Or there is no action scheduled and view is not hidden.
    if ((_scheduledActions.count && _scheduledActions.lastObject.scheduledDisplay) ||
        (!_scheduledActions.count && !self.hidden)) {
        // In both cases add hide action first.
        [_scheduledActions addObject:[NotifyAction actionHide]];
    }
}

- (void)proccessQueue {
    if (_runningAction || !_scheduledActions.count) {
        return;
    }
    
    NotifyAction *newAction = [_scheduledActions firstObject];
    if (newAction.scheduledDisplay) {
        [self actionShow:newAction];
    } else {
        [self actionHide:newAction];
    }
}

- (CGSize)frameWidthWithString:(NSString *)string {
    // We are going to fit notification to screen width.
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    // First set maximum allowed text width.
    CGFloat fullOffset  = 5.f * kFramePadding + _imageView.bounds.size.width;
    CGFloat outerOffset = 3.f * kFramePadding + _imageView.bounds.size.width;
    [_labelCaption setPreferredMaxLayoutWidth:bounds.size.width - fullOffset];
    
    // With prefered line width we can calculate actual size.
    CGSize textSize     = [_labelCaption intrinsicContentSize];
    CGFloat retWidth    = outerOffset + textSize.width;
    CGFloat retHeight   = 2.f * kFramePadding + MAX(_imageView.bounds.size.height, textSize.height);
    
    // Fit to screen width - edge padding.
    retWidth = MIN(bounds.size.width - 2.f * kFramePadding, retWidth);
    
    return CGSizeMake(retWidth, retHeight);
}

- (void)actionShow:(NotifyAction *)action {
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    // Mark that we are running some action.
    self.runningAction = YES;
    
    // Change content before frame calculation
    [_labelCaption  setText:action.scheduledLabel];
    [_imageView     setImage:[NotifyAction NotifyTypeImage:action.scheduledType]];
    [_imageView     setTintColor:[UIColor whiteColor]];
    
    // Update frame size based on new content.
    CGSize size = [self frameWidthWithString:action.scheduledLabel];
    // Move frame under screen and unhide it.
    self.frame = CGRectMake(bounds.size.width * .5f - size.width * .5f,
                            bounds.size.height - size.height - _screenOffset,
                            size.width, size.height);
    [self setHidden:NO];
    
    // Animate display.
    [UIView animateWithDuration:kAnimationSpeed
                          delay:.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.alpha = 1.f;
                     } completion:^(BOOL finished) {
                         // Remove current action from queue
                         [self.scheduledActions removeObject:action];
                         
                         // Mark action finished and process next one in queue.
                         self.runningAction = NO;
                         [self proccessQueue];
                     }];
}

- (void)actionHide:(NotifyAction *)action {
    // Mark that we are running some action.
    self.runningAction = YES;
    
    // Move frame under screen and unhide it.
    [self.superview layoutIfNeeded];
    
    // Animate hide action.
    [UIView animateWithDuration:kAnimationSpeed
                          delay:.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.alpha = .0f;
                     } completion:^(BOOL finished) {
                         
                         // Remove current action from queue
                         [self.scheduledActions removeObject:action];
                         
                         // Hide view.
                         [self setHidden:YES];
                         
                         // Mark action finished and process next one in queue.
                         self.runningAction = NO;
                         [self proccessQueue];
                     }];
}

@end
