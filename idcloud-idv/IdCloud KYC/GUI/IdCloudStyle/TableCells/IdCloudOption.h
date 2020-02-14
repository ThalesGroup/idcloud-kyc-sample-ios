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

typedef NS_ENUM(NSInteger, IdCloudOptionSection) {
    IdCloudOptionSectionGeneral                 = 0,
    IdCloudOptionSectionRiskManagement          = 1,
    IdCloudOptionSectionIdentityDocumentScan    = 2,
    IdCloudOptionSectionFaceCapture             = 3,
    IdCloudOptionSectionVersion                 = 4
};

typedef NS_ENUM(NSInteger, IdCloudOptionType) {
    IdCloudOptionTypeCheckbox   = 0,
    IdCloudOptionTypeNumber     = 1,
    IdCloudOptionTypeVersion    = 2,
    IdCloudOptionTypeSegment    = 3,
    IdCloudOptionTypeButton     = 4,
    IdCloudOptionTypeText       = 5,

    IdCloudOptionTypeLB = IdCloudOptionTypeCheckbox,
    IdCloudOptionTypeUB = IdCloudOptionTypeText,
};

typedef NS_ENUM(NSInteger, KYCDocumentType) {
    KYCDocumentTypeIdCard               = 0,
    KYCDocumentTypePassport             = 1,
    KYCDocumentTypePassportBiometric    = 2,
};

@interface IdCloudOption : NSObject

+ (instancetype)number:(NSString *)caption
           description:(NSString *)description
               section:(IdCloudOptionSection)section
                target:(id)target
           selectorGet:(SEL)selectorGet
           selectorSet:(SEL)selectorSet
              minValue:(NSInteger)minValue
              maxValue:(NSInteger)maxValue;

+ (instancetype)checkbox:(NSString *)caption
             description:(NSString *)description
                 section:(IdCloudOptionSection)section
                  target:(id)target
             selectorGet:(SEL)selectorGet
             selectorSet:(SEL)selectorSet;

+ (instancetype)segment:(NSString *)caption
                section:(IdCloudOptionSection)section
                options:(NSDictionary<NSNumber *, NSString *> *)options
                 target:(id)target
            selectorGet:(SEL)selectorGet
            selectorSet:(SEL)selectorSet;

+ (instancetype)version:(NSString *)caption
            description:(NSString *)description;

+ (instancetype)text:(NSString *)caption
             section:(IdCloudOptionSection)section
              target:(id)target
         selectorGet:(SEL)selectorGet;

+ (instancetype)button:(NSString *)caption
               section:(IdCloudOptionSection)section
                target:(id)target
              selector:(SEL)selector;

@property (nonatomic, assign, readonly) IdCloudOptionSection    section;
@property (nonatomic, assign, readonly) IdCloudOptionType       type;
@property (nonatomic, assign, readonly) id                      target;
@property (nonatomic, assign, readonly) SEL                     selectorGet;
@property (nonatomic, assign, readonly) SEL                     selectorSet;
@property (nonatomic, copy, readonly)   NSString                *titleCaption;
@property (nonatomic, copy, readonly)   NSString                *titleDescription;

// For numeric type only. If there will be more types add inheritance.
@property (nonatomic, assign, readonly) NSInteger               minValue;
@property (nonatomic, assign, readonly) NSInteger               maxValue;

// For segment type only. If there will be more types add inheritance.
@property (nonatomic, copy, readonly)   NSDictionary<NSNumber *, NSString *> *options;

// For button type only. If there will be more types add inheritance.
@property (nonatomic, assign, readonly) SEL                     selectorButton;

@end

