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

#define kStateWaiting   @"Waiting"  // Waiting for remaining images.
#define kStateFinished  @"Finished" // All images was uploaded and processed.

typedef void (^RequestBuilder)(NSURLRequest *request, NSError *error);


@implementation KYCCommunication

// MARK: - Public API

+ (void)verifyDocumentFront:(NSData *)docFront
               documentBack:(NSData *)docBack
                     selfie:(NSData *)selfie
          completionHandler:(KYCResponseHandler)handler {
    assert(handler);
    
    // To make code cleaner simple call internal method in different name style
    [KYCCommunication initialRequestPrepareAndSend:docFront
                                      documentBack:docBack
                                            selfie:selfie
                                 completionHandler:handler];
    
}

// MARK: - Private Helpers - Initial request

/**
 Starts the first verification step with the verification backend.

 @param docFront Front side of the document.
 @param docBack Back side of the document.
 @param selfie Selfie image.
 @param handler Callback.
 */
+ (void)initialRequestPrepareAndSend:(NSData *)docFront
                        documentBack:(NSData *)docBack
                              selfie:(NSData *)selfie
                   completionHandler:(KYCResponseHandler)handler {
    // Build and possible send initial request.
    [KYCCommunication initialRequestCreateJSON:docFront
                                  documentBack:docBack
                                        selfie:selfie
                                       handler:^(NSURLRequest *request, NSError *error) {
        // Prepare session.
        KYCSession *session = [KYCSession createWithURL:CFG_IDCLOUD_BASE_URL
                                               portrait:selfie
                                             andHandler:handler];
        if (error) {
            // Failed to build initial request.
            [session handleError:error.localizedDescription];
        } else {
            // Execute request.
            [[[KYCCommunication createUrlSession] dataTaskWithRequest:request
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                // Something went wrong during communication. Return error from SDK.
                if (error) {
                    [session handleError:error.localizedDescription];
                    return;
                }
                
                // Parse server response, update session id and check possible errors.
                if ([session parseResultAndHandleErrors:data]) {
                    // Continue with verify status. We can call it directly without delay. Acuant is fast.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [KYCCommunication performSelector:@selector(verifyDocumentPrepareAndSend:) withObject:session];
                    });
                }
            }] resume];
        }
    }];
}

/**
 Creates the HTTP JSON body for the first verification step.

 @param docFront Front side of document.
 @param docBack Back side of document.
 @param selfie Selfie image.
 @param handler Callback.
 */
+ (void)initialRequestCreateJSON:(NSData *)docFront
                    documentBack:(NSData *)docBack
                          selfie:(NSData *)selfie
                         handler:(RequestBuilder)handler {
    // Input is object containing document and optionaly face.
    NSMutableDictionary *input = [NSMutableDictionary new];
    [input setObject:@"SDK" forKey:@"captureMethod"];
    if (docFront) {
        [input setObject:[docFront base64EncodedStringWithOptions:0] forKey:@"frontWhiteImage"];
    }
    if (docBack) {
        [input setObject:[docBack base64EncodedStringWithOptions:0] forKey:@"backWhiteImage"];
    }
    
    // Optional values for faster evaluation.
    
    // Value: "type"
    // Description: Document type.
    // Possible values are: "Passport", "ID", "DL", "ResidencePermit", "HealthCard", "VISA", "Other"
    
    // Value: "size"
    // Description: Document size.
    // Possible values are: "TD1", "TD2", "TD3"
    
    // Build final JSON.
    NSError *error;
    NSMutableDictionary *json = [KYCCommunication createMassageBase:selfie];
    [json setObject:input forKey:@"input"];
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
    
    // Something went wrong during JSON serialization.
    if (error) {
        handler(nil, error);
    }
    
    // Build request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:CFG_IDCLOUD_BASE_URL]];
    request.HTTPMethod  = @"POST";
    request.HTTPBody    = requestData;
    
    // Return complete request
    handler(request, nil);
}

// MARK: - Private Helpers - Verify Document

/**
 Starts the second verification step with the verification backend - document verification.

 @param session Session.
 */
+ (void)verifyDocumentPrepareAndSend:(KYCSession *)session {
    // Build request.
    NSError *error;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:session.urlDocument];
    request.HTTPMethod = @"PATCH";
    request.HTTPBody    = [KYCCommunication verifyDocumentCreateJSON:session.portrait
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
        
        // Parse server response, update session id and check possible errors.
        NSDictionary *res = [session parseResultAndHandleErrors:data];
        if (!res) {
            return;
        }
        
        NSString *status= res[@"status"];
        if (session.portrait && [status isEqualToString:kStateWaiting]) {
            // Face identification is included in next step.
            dispatch_async(dispatch_get_main_queue(), ^{
                [KYCCommunication performSelector:@selector(verifySelfiePrepareAndSend:session:) withObject:response withObject:session];
            });
        } else if (!session.portrait && [status isEqualToString:kStateFinished]) {
            KYCResponse *response = [KYCResponse createWithJSON:res[@"state"][@"result"]];
            if (response) {
                [session handleResult:response];
            } else {
                [session handleError:@"Failed to parse server response."];
            }
        } else {
            [session handleError:@"Unexpected server state."];
        }
    }] resume];
}

/**
 Creates the JSON body for document verification.
 
 @param isPortraitIncluded {@code True} if selfie image is included, else {@code false}.
 */
+ (NSData *)verifyDocumentCreateJSON:(BOOL)isPortraitIncluded
                               error:(NSError **)error {
    NSMutableDictionary *json = [KYCCommunication createMassageBase:isPortraitIncluded];
    return [NSJSONSerialization dataWithJSONObject:json options:0 error:error];
}

// MARK: - Private Helpers - Verify selfie

/**
 Starts the third verification step with the verification backend - selfie verification.

 @param session Session.
 */
+ (void)verifySelfiePrepareAndSend:(KYCResponse *)response1 session:(KYCSession *)session {
    // Build request.
    NSError *error;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:session.urlSelfie];
    request.HTTPMethod = @"PATCH";
    request.HTTPBody    = [KYCCommunication verifySlefieCreateJSON:session.portrait
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
        
        // Parse server response, update session id and check possible errors.
        NSDictionary *res = [session parseResultAndHandleErrors:data];
        if (!res) {
            return;
        }
        
        if ([res[@"status"] isEqualToString:kStateFinished]) {
            KYCResponse *response = [KYCResponse createWithJSON:res[@"state"][@"result"]];
            if (response) {
                [session handleResult:response];
            } else {
                [session handleError:@"Failed to parse server response."];
            }
        } else {
            // Unknown state. Not handled response type.
            [session handleError:@"Unexpected server response."];
        }
    }] resume];
}

/**
 Creates the JSON body for document verification.

 @param portrait Selfie image.
 @param error Error object.
*/
+ (NSData *)verifySlefieCreateJSON:(NSData *)portrait
                             error:(NSError **)error {
    NSMutableDictionary *json = [KYCCommunication createMassageBase:YES];
    
    NSMutableDictionary *input = [NSMutableDictionary new];
    [input setObject:[portrait base64EncodedStringWithOptions:0] forKey:@"face"];
    [json setObject:input forKey:@"input"];
    
    return [NSJSONSerialization dataWithJSONObject:json options:0 error:error];
}

// MARK: - Private Helpers - Common

/**
 Creates the url session for all verification steps.
 
 @return {@code NSURLSession} for the verification steps.
 */
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

/**
 Creates the JSON body based on if the selfie image is included.
 
 @param selfie {@code True} if selfie image is included, else {@code false}.
 
 @return JSON body.
 */
+ (NSMutableDictionary *)createMassageBase:(BOOL)selfie {
    NSMutableDictionary *json = [NSMutableDictionary new];
    [json setObject:selfie ? @"Connect_Verify_Document_Face" : @"Connect_Verify_Document" forKey:@"name"];
    
    return json;
}

@end
