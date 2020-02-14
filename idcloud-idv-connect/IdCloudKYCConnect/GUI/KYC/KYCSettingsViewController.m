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

#import "KYCSettingsViewController.h"
#import "SideMenuViewController.h"
#import "IdCloudBoolenTVC.h"

#define kTableCellHeader @"KYCHeader"

@interface KYCSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak)     IBOutlet UITableView    *tableSettings;

@end

@implementation KYCSettingsViewController

// MARK: - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_tableSettings setDelegate:self];
    [_tableSettings setDataSource:self];
    
    // Register all cell types.
    for (IdCloudOptionType loopOption = IdCloudOptionTypeLB; loopOption <= IdCloudOptionTypeUB; loopOption++) {
        [self registerCellWithType:loopOption];
    }
    
    // Register headers.
    [_tableSettings registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:kTableCellHeader];
    
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
    [_tableSettings reloadData];
}

- (void)registerCellWithType:(IdCloudOptionType)type {
    NSString *cellId = [self cellIdWithType:type];
    [_tableSettings registerNib:[UINib nibWithNibName:cellId
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:cellId];
}

- (NSString *)cellIdWithType:(IdCloudOptionType)type {
    switch (type) {
        case IdCloudOptionTypeCheckbox:
            return kTableCellBoolean;
        case IdCloudOptionTypeVersion:
            return kTableCellVersion;
        case IdCloudOptionTypeNumber:
            return kTableCellNumber;
        case IdCloudOptionTypeSegment:
            return kTableCellSegment;
        case IdCloudOptionTypeButton:
            return kTableCellButton;
        case IdCloudOptionTypeText:
            return kTableCellText;
    }
    
    // Unknown cell type.
    assert(false);
    return nil;
}

// MARK: - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Versions does not need to be that big.
    if (indexPath.section == 3) {
        return 60.f;
    } else {
        return 80.f;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Make header orange with black text
    UITableViewHeaderFooterView *headerView     = (UITableViewHeaderFooterView *)view;
    headerView.contentView.backgroundColor      = [UIColor lightGrayColor];
    headerView.textLabel.textColor              = [UIColor colorNamed:@"TextPrimary"];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id<IdCloudCellProtocol> cell    = [tableView cellForRowAtIndexPath:indexPath];
    IdCloudOption           *option = [KYCManager sharedInstance].options[indexPath.section][indexPath.row];
    
    // Ignore selection on disabled cells.
    if (cell.enabled) {
        // Make sure that all cells with inputs are visible on screen.
        // Currently only supported cell is numeric.
        if (option.type == IdCloudOptionTypeNumber) {
            [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        
        // Handle tap instead of selection to prevent different behaviour on different devices.
        [cell onUserTap];
        
        //        // Call after tap handler to reflect updated values.
        //        if (option.section == IdCloudOptionSectionGeneral) {
        //            [tableView reloadSections:[NSIndexSet indexSetWithIndex:IdCloudOptionSectionFaceCapture] withRowAnimation:UITableViewRowAnimationFade];
        //        }
    }
    
    // Do not allow iOS to handle selection.
    return nil;
}

// MARK: - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [KYCManager sharedInstance].optionCaptions.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *retValue = [_tableSettings dequeueReusableHeaderFooterViewWithIdentifier:kTableCellHeader];
    NSArray<NSString *>         *captions = [KYCManager sharedInstance].optionCaptions;
    
    if (section < captions.count) {
        [retValue.textLabel setText:captions[section]];
    }
    
    return retValue;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Hide all elements in section.
    //    if (section == IdCloudOptionSectionFaceCapture && ![KYCManager sharedInstance].facialRecognition) {
    //        return 0;
    //    }
    return [KYCManager sharedInstance].options[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell<IdCloudCellProtocol> *retValue = nil;
    
    IdCloudOption *option = [KYCManager sharedInstance].options[indexPath.section][indexPath.row];
    retValue = [tableView dequeueReusableCellWithIdentifier:[self cellIdWithType:option.type]];
    [retValue updateWithOption:option];
    
    // Enable face id section only when face id is enabled in the first place.
    if (option.section == IdCloudOptionSectionFaceCapture) {
        [retValue setEnabled:[KYCManager sharedInstance].facialRecognition];
    } else {
        // Cells are reused. Re-enable others.
        [retValue setEnabled:YES];
    }
    
    return retValue;
}

@end
