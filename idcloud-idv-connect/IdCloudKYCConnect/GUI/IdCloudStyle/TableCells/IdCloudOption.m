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

#import "IdCloudOption.h"

@implementation IdCloudOption

+ (instancetype)number:(NSString *)caption
           description:(NSString *)description
               section:(IdCloudOptionSection)section
                target:(id)target
           selectorGet:(SEL)selectorGet
           selectorSet:(SEL)selectorSet
              minValue:(NSInteger)minValue
              maxValue:(NSInteger)maxValue {
    return [[IdCloudOption alloc] initWithType:IdCloudOptionTypeNumber
                                             caption:caption
                                             section:section
                                         description:description
                                              target:target
                                         selectorGet:selectorGet
                                         selectorSet:selectorSet
                                            minValue:minValue
                                            maxValue:maxValue
                                             options:nil
                                      selectorButton:nil];
}

+ (instancetype)checkbox:(NSString *)caption
             description:(NSString *)description
                 section:(IdCloudOptionSection)section
                  target:(id)target
             selectorGet:(SEL)selectorGet
             selectorSet:(SEL)selectorSet {
    return [[IdCloudOption alloc] initWithType:IdCloudOptionTypeCheckbox
                                             caption:caption
                                             section:section
                                         description:description
                                              target:target
                                         selectorGet:selectorGet
                                         selectorSet:selectorSet
                                            minValue:0 maxValue:0 options:nil selectorButton:nil];
}

+ (instancetype)version:(NSString *)caption
            description:(NSString *)description {
    return [[IdCloudOption alloc] initWithType:IdCloudOptionTypeVersion
                                             caption:caption
                                             section:IdCloudOptionSectionVersion
                                         description:description
                                              target:nil selectorGet:nil selectorSet:nil
                                            minValue:0 maxValue:0 options:nil selectorButton:nil];
}

+ (instancetype)text:(NSString *)caption
             section:(IdCloudOptionSection)section
              target:(id)target
         selectorGet:(SEL)selectorGet {
    return [[IdCloudOption alloc] initWithType:IdCloudOptionTypeText
                                       caption:caption
                                       section:section
                                   description:nil
                                        target:target
                                   selectorGet:selectorGet
                                   selectorSet:nil
                                      minValue:0 maxValue:0 options:nil selectorButton:nil];
}

+ (instancetype)segment:(NSString *)caption
                section:(IdCloudOptionSection)section
                options:(NSDictionary<NSNumber *, NSString *> *)options
                 target:(id)target
            selectorGet:(SEL)selectorGet
            selectorSet:(SEL)selectorSet {
    return [[IdCloudOption alloc] initWithType:IdCloudOptionTypeSegment
                                             caption:caption
                                             section:section
                                         description:nil
                                              target:target
                                         selectorGet:selectorGet selectorSet:selectorSet
                                            minValue:0 maxValue:0
                                             options:options
                                      selectorButton:nil];
}

+ (instancetype)button:(NSString *)caption
               section:(IdCloudOptionSection)section
                target:(id)target
              selector:(SEL)selector {
    return [[IdCloudOption alloc] initWithType:IdCloudOptionTypeButton
                                             caption:caption
                                             section:section
                                         description:nil
                                              target:target
                                         selectorGet:nil selectorSet:nil
                                            minValue:0 maxValue:0
                                             options:nil
                                      selectorButton:selector];
}

- (instancetype)initWithType:(IdCloudOptionType)type
                     caption:(NSString *)caption
                     section:(IdCloudOptionSection)section
                 description:(NSString *)description
                      target:(id)target
                 selectorGet:(SEL)selectorGet
                 selectorSet:(SEL)selectorSet
                    minValue:(NSInteger)minValue
                    maxValue:(NSInteger)maxValue
                     options:(NSDictionary<NSNumber *, NSString *> *)options
              selectorButton:(SEL)selectorButton {
    if (self = [super init]) {
        _type               = type;
        _titleCaption       = [caption copy];
        _titleDescription   = [description copy];
        _section            = section;
        _target             = target;
        _selectorGet        = selectorGet;
        _selectorSet        = selectorSet;
        _minValue           = minValue;
        _maxValue           = maxValue;
        _options            = [options copy];
        _selectorButton     = selectorButton;
    }
    
    return self;
}

@end
