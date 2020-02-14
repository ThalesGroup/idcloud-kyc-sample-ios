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

#import "BaseViewController.h"

@interface BaseViewController()

@property (nonatomic, strong) IdCloudLoadingIndicator       *loadingIndicator;

@end

@implementation BaseViewController

// MARK: - Life Cycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Realod common as well as inherited values.
    [self reloadGUI];
        
    if (!_loadingIndicator) {
        self.loadingIndicator = [IdCloudLoadingIndicator loadingIndicator];
        [self.view addSubview:_loadingIndicator];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
        
    // Stop getting information about notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// MARK: - Loading Indicator

- (void)loadingIndicatorShowWithCaption:(NSString *)caption {
    // Loading indicator is already present or not configured for view at all.
    if (!_loadingIndicator || _loadingIndicator.isPresent) {
        return;
    }
    
    // Display loading indicator.
    [_loadingIndicator setCaption:caption];
    [_loadingIndicator loadingBarShow:YES animated:YES];
    
    // We want to lock UI behind it.
    [self reloadGUI];
}

- (void)loadingIndicatorHide {
    // Loading indicator is already hidden or not configured for view at all.
    if (!_loadingIndicator || !_loadingIndicator.isPresent) {
        return;
    }
    
    // Hide loading indicator.
    [_loadingIndicator loadingBarShow:NO animated:YES];
    
    // We want to un-lock UI behind it.
    [self reloadGUI];
}

- (BOOL)overlayViewVisible {
    return _loadingIndicator.isPresent ;
}

// MARK: - Dialogs

- (void)displayOnCancelDialog:(NSString *)caption
                      message:(NSString *)message
                     okButton:(NSString *)okButton
                 cancelButton:(NSString *)cancelButton
            completionHandler:(void (^)(BOOL))handler {
    // Main alert builder.
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:caption
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // Add ok button with handler.
    [alert addAction:[UIAlertAction actionWithTitle:okButton
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                handler(YES);
                                            }]];
    
    // Add cancel button with handler.
    [alert addAction:[UIAlertAction actionWithTitle:cancelButton
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                handler(NO);
                                            }]];
    
    // Present dialog.
    [self presentViewController:alert animated:true completion:nil];
}

// MARK: - Common Helpers

- (void)reloadGUI {
    [self enableGUI:![self overlayViewVisible]];
}

- (void)enableGUI:(BOOL)enabled {
    // Override
}

// MARK: - User Interface

- (IBAction)onButtonPressedBack:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
