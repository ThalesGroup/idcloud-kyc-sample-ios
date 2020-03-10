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

#import "KYCDocument.h"
#import "KYCFace.h"

/**
 Verification backend response.
 */
@interface KYCResponse : NSObject

/**
 Details about the request.
 */
@property (nonatomic, copy)     NSString    *message;

/**
 Document type:
 <p><ul>
 <li> Passport
 <li> ID
 <li> Driving license.
 </ul><p>
 */
@property (nonatomic, copy)     NSString    *type;

/**
 Return code:
 <p><ul>
 <li> 0 - OK
 <li> >0 - Error
 </ul><p>
 */
@property (nonatomic, assign)   NSInteger   code;

/**
 Document - see {@link KYCDocument}.
 */
@property (nonatomic, strong)   KYCDocument *document;

/**
 Face - see {@link KYCFace}
 */
@property (nonatomic, strong)   KYCFace     *face;

/**
 Creates a new {@code KYCResponse} from the JSON verification backend response.
 
 @param response Verfication backend response.
 
 @return New {@code KYCResponse} instance.
 */
+ (instancetype)createWithJSON:(NSDictionary *)response;

/**
 Updates the {@code KYCResponse} object with the face data.
 
 @param response Response from verification backend.
 */
- (void)updateWithSelfieJSON:(NSDictionary *)response;

@end
