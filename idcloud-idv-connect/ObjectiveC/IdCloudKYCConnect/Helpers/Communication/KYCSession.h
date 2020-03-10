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

#import "KYCResponse.h"

/**
 Verification session callback
 
 @param response Response from verification backend.
 @param error Error from verification backend - optional if errro occured.
 */
typedef void (^KYCResponseHandler)(KYCResponse *response, NSString *error);

/**
 Session with verification backend.
*/
@interface KYCSession : NSObject

/**
 URL for document verification.
 */
@property (nonatomic, copy, readonly)   NSURL   *urlDocument;

/**
 URL for selfie verification.
 */
@property (nonatomic, copy, readonly)   NSURL   *urlSelfie;

/**
 Selfie image.
 */
@property (nonatomic, copy, readonly)   NSData  *portrait;

/**
 Creates a new {@code KYCSession} instance.
 
 @param urlBase Verificaiton backend URL.
 @param portrait Selfie image.
 @param handler Callback.
 
 @return Instance of {@code KYCSession}.
 */
+ (instancetype)createWithURL:(NSString *)urlBase
                     portrait:(NSData *)portrait
                   andHandler:(KYCResponseHandler)handler;

/**
 Parses error data received from verifiatin backend.
 
 @param data Error data received from verification backend.
 
 @return Error dictionary.
 */
- (NSDictionary *)parseResultAndHandleErrors:(NSData *)data;

/**
 Posts the error on the main UI thread.
 
 @param error Error.
 */
- (void)handleError:(NSString *)error;

/**
 Posts the result on the main UI thread.
 
 @param result Result.
 */
- (void)handleResult:(KYCResponse *)result;

@end
