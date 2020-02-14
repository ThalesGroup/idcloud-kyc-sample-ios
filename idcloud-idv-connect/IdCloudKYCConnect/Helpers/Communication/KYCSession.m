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

#import "KYCSession.h"

@interface KYCSession()

@property (nonatomic, copy)     NSString            *urlBase;
@property (nonatomic, copy)     NSString            *sessionId;
@property (nonatomic, copy)     KYCResponseHandler  handler;

@end

#define kCommonStateFailed      @"Failed"   // Check state.result for more details.
#define kCommonStateError       @"Error"    // Configuration error. Contact Thales representative.

@implementation KYCSession

// MARK: - Life Cycle

+ (instancetype)createWithURL:(NSString *)urlBase
                     portrait:(NSData *)portrait
                   andHandler:(KYCResponseHandler)handler{
    return [[KYCSession alloc] initWithURL:urlBase portrait:portrait andHandler:handler];
}

- (instancetype)initWithURL:(NSString *)urlBase
                   portrait:(NSData *)portrait
                 andHandler:(KYCResponseHandler)handler {
    if (self = [super init]) {
        _portrait       = portrait;
        self.urlBase    = urlBase;
        self.handler    = handler;
    }
    
    return self;
}

// MARK: - Public Methods

- (NSURL *)urlDocument {
    NSString *baseURL = [_urlBase stringByAppendingPathComponent:_sessionId];
    return [NSURL URLWithString:[baseURL stringByAppendingPathComponent:@"/state/steps/verifyResults"]];
}

- (NSURL *)urlSelfie {
    NSString *baseURL = [_urlBase stringByAppendingPathComponent:_sessionId];
    return [NSURL URLWithString:[baseURL stringByAppendingPathComponent:@"/state/steps/faceMatch"]];
}

- (NSDictionary *)parseResultAndHandleErrors:(NSData *)data {
    // Parse server response and check possible errors.
    NSError         *error      = nil;
    NSDictionary    *retValue   = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        [self handleError:error.localizedDescription];
        return nil;
    }
    
    // Get and update session Id.
    self.sessionId = retValue[@"id"];
    if (!_sessionId || !_sessionId.length) {
        [self handleError:@"Failed to get valid session id."];
        return nil;
    }
    
    // Check response status.
    NSString *status = retValue[@"status"];
    if ([status isEqualToString:kCommonStateFailed]) {
        [self handleError:retValue[@"state"][@"result"][@"message"]];
        return nil;
    } else if ([status isEqualToString:kCommonStateError]) {
        [self handleError:@"Configuration error. Contact Thales representative."];
        return nil;
    }
    
    
    return retValue;
}

- (void)handleError:(NSString *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.handler(nil, error);
    });
}

- (void)handleResult:(KYCResponse *)result {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.handler(result, nil);
    });
}

@end
