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

typedef NS_ENUM(NSInteger, NotifyType) {
    NotifyTypeInfo = 0,
    NotifyTypeWarning,
    NotifyTypeError,
    NotifyType_KYCLeft,
    NotifyType_KYCRight,
    NotifyType_KYCUp,
    NotifyType_KYCDown,
    NotifyType_KYCCenter,
    NotifyType_KYCRotate,
    NotifyType_KYCKeepStill,
    NotifyType_KYCBlink,
};

@interface NotifyAction : NSObject

+ (instancetype)actionHide;
+ (instancetype)actionShow:(NSString *)label type:(NotifyType)type;

@property (nonatomic, assign)   BOOL        scheduledDisplay;
@property (nonatomic, assign)   NotifyType  scheduledType;
@property (nonatomic, copy)     NSString    *scheduledLabel;

+ (UIColor *)NotifyTypeColor:(NotifyType)type;
+ (UIImage *)NotifyTypeImage:(NotifyType)type;

@end

