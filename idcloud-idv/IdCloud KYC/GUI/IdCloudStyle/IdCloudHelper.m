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

#import "IdCloudHelper.h"

@implementation IdCloudHelper

+ (void)unifyLabelsToSmallestSize:(UILabel *)firstObj, ... {
    if (firstObj) {
        CGFloat minSize = 10000.f;
        
        va_list args;
        va_start(args, firstObj);
        for (UILabel *loopLabel = firstObj; loopLabel != nil; loopLabel = va_arg(args, UILabel*) ) {
            CGFloat size = [IdCloudHelper getActualFontSize:loopLabel];
            minSize = MIN(minSize, size);
        }
        va_end(args);
        
        va_start(args, firstObj);
        for (UILabel *loopLabel = firstObj; loopLabel != nil; loopLabel = va_arg(args, UILabel*) ) {
            loopLabel.font = [loopLabel.font fontWithSize:minSize];
        }
        va_end(args);
    }
}

+ (CGFloat)getActualFontSize:(UILabel *)label {
    NSDictionary *attributes = @{NSFontAttributeName : label.font};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:label.text
                                                                           attributes:attributes];
    
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    context.minimumScaleFactor = label.minimumScaleFactor;
    
    [attributedString boundingRectWithSize:label.bounds.size
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                   context:context];
    return label.font.pointSize * context.actualScaleFactor;
}

+ (void)animateView:(UIView *)view
           inParent:(UIView *)parent
          withDelay:(CGFloat *)delay {
    CGAffineTransform transformTo   = view.transform;
    CGAffineTransform transformFrom = CGAffineTransformTranslate(transformTo, -parent.frame.size.width, .0f);
    
    view.transform = transformFrom;
    
    [UIView animateWithDuration:1.5f
                          delay:delay ? *delay : .0f
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        view.transform = transformTo;
    } completion:nil];
    if (delay) {
        *delay += .2f;
    }
}

+ (NSData *)imageFromBase64:(NSString *)base64 {
    if (base64 && base64.length) {
        return [[NSData alloc] initWithBase64EncodedString:base64 options:0];
    } else {
        return nil;
    }
}

@end
