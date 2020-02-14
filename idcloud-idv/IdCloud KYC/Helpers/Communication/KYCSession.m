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

@implementation KYCSession

// MARK: - Life Cycle

+ (instancetype)createWithURL:(NSString *)urlBase andHandler:(KYCResponseHandler)handler {
    return [[KYCSession alloc] initWithURL:urlBase andHandler:handler];
}

- (instancetype)initWithURL:(NSString *)urlBase andHandler:(KYCResponseHandler)handler {
    if (self = [super init]) {
        self.urlBase    = urlBase;
        self.handler    = handler;
        self.tryCount   = 1;
    }
    
    return self;
}

// MARK: - Public Methods

- (NSURL *)url {
    return [NSURL URLWithString:_urlBase];
}

- (NSURL *)urlWithSessionId {
    return [NSURL URLWithString:[_urlBase stringByAppendingPathComponent:_sessionId]];
}

- (void)updateWithSessionId:(NSString *)sessionId {
    self.sessionId = sessionId;
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
