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
#import "KYCCommunication.h"
#import "KYCSession.h"

@implementation KYCCommunication

// MARK: - Public API

+ (void)verifyDocumentFront:(NSData *)docFront
               documentBack:(NSData *)docBack
                     selfie:(NSData *)selfie
          completionHandler:(KYCResponseHandler)handler {
    assert(handler);
    
    // Prepare session.
    KYCSession *session = [KYCSession createWithURL:CFG_IDCLOUD_BASE_URL andHandler:handler];
    
    // Build request.
    NSError *error;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:session.url];
    request.HTTPMethod  = @"POST";
    request.HTTPBody    = [KYCCommunication createVerificationJSON:docFront
                                                      documentBack:docBack
                                                            selfie:selfie
                                                             error:&error];
    
    // Failed to build verification JSON. No reason to continue.
    if (error) {
        [session handleError:error.localizedDescription];
        return;
    }
    
    // Execute request.
    [[[KYCCommunication createUrlSession] dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // Something went wrong during communication. Return error from SDK.
        if (error) {
            [session handleError:error.localizedDescription];
            return;
        }
        
        // Parse server response and get session id.
        NSDictionary    *res        = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSString        *sessionId  = [res objectForKey:@"id"];
        
        // Failed to get valid operation session id.
        if (!sessionId || !sessionId.length) {
            [session handleError:@"Failed to get valid session id."];
            return;
        }
    
        // Pass getted session id to current session and continue.
        [session updateWithSessionId:sessionId];
        dispatch_async(dispatch_get_main_queue(), ^{
            [KYCCommunication performSelector:@selector(verifyDocumentSecondStep:) withObject:session afterDelay:CFG_IDCLOUD_RETRY_DELAY_SEC];
        });
        
    }] resume];
}

// MARK: - Private Helpers

+ (void)verifyDocumentSecondStep:(KYCSession *)session {
    // Build request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:session.urlWithSessionId];
    request.HTTPMethod = @"GET";
    
    // Execute request.
    [[[KYCCommunication createUrlSession] dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary    *res    = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSString        *status = res[@"status"];
        
        // Server operation is still running.
        if ([status isEqualToString:@"Running"]) {
            // Make sure we will not create infinite loop.
            if (session.tryCount <= CFG_IDCLOUD_NUMBER_OF_RETRIES) {
                session.tryCount++;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [KYCCommunication performSelector:@selector(verifyDocumentSecondStep:) withObject:session afterDelay:CFG_IDCLOUD_RETRY_DELAY_SEC];
                });
            } else {
                // Already pass number of retries. We can end here.
                [session handleError:@"Failed to get server response in time."];
            }
        } else if ([status isEqualToString:@"Finished"]) {
            // Server operation finished.
            KYCResponse *response = [KYCResponse responseWithJSON:[[res objectForKey:@"state"] objectForKey:@"result"]];
            if (response) {
                [session handleResult:response];
            } else {
                [session handleError:@"Failed to parse server response."];
            }
        } else if ([status isEqualToString:@"Failure"]) {
            // Server operation failed.
            NSDictionary    *result     = res[@"state"][@"result"];
            NSString        *message    = result[@"message"];
            NSInteger       code        = [result[@"code"] integerValue];
            
            // Messages looks like "[5eb47d75-71f7-4b36-a273-8ddfe7e985bc] Internal service error". Strip down first ID part.
            NSRange range = [message rangeOfString:@"] "];
            if (range.length == 2) {
                message = [message substringFromIndex:range.location + 2];
            }
            
            // Return to handler.
            [session handleError:[NSString stringWithFormat:@"Error Code: %ld, Error Message: %@", (long)code, message]];
        } else {
            // Unknown state. Not handled response type.
            [session handleError:@"Unexpected server response."];
        }
        
    }] resume];
}

+ (NSURLSession *)createUrlSession {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = @{
        @"Accept"           : @"application/json",
        @"Content-Type"     : @"application/json",
        @"Authorization"    : [NSString stringWithFormat:@"Bearer %@", [KYCManager sharedInstance].jsonWebToken],
        @"X-API-KEY"        : [KYCManager sharedInstance].apiKey
    };
    return [NSURLSession sessionWithConfiguration:configuration];
}

+ (NSData *)createVerificationJSON:(NSData *)docFront
                      documentBack:(NSData *)docBack
                            selfie:(NSData *)selfie
                             error:(NSError **)error {
    // Build document node with front and back side.
    NSMutableDictionary *document = [NSMutableDictionary new];
    [document setObject:@"SDK" forKey:@"captureMethod"];
    [document setObject:@"Residence_Permit" forKey:@"type"];
    [document setObject:@"TD1" forKey:@"size"];
    if (docFront) {
        [document setObject:[docFront base64EncodedStringWithOptions:0] forKey:@"front"];
    }
    if (docBack) {
        [document setObject:[docBack base64EncodedStringWithOptions:0] forKey:@"back"];
    }
        
    // Input is object containing document and optionaly face.
    NSMutableDictionary *input = [NSMutableDictionary new];
    [input setObject:document forKey:@"document"];
    
    // Build selfie node.
    if (selfie) {
        NSMutableDictionary *face = [NSMutableDictionary new];
        [face setObject:[selfie base64EncodedStringWithOptions:0] forKey:@"image"];
        [input setObject:face forKey:@"face"];
    }
    
    // Build final JSON.
    NSMutableDictionary *json = [NSMutableDictionary new];
    [json setObject:selfie ? @"Verify_Document_Face" : @"Verify_Document" forKey:@"name"];
    [json setObject:input forKey:@"input"];
    
    return [NSJSONSerialization dataWithJSONObject:json options:0 error:error];
}

@end
