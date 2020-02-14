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



#import "KYCVerificationResult.h"

@implementation KYCVerificationResult

+ (instancetype)createWithJSON:(NSDictionary *)response {
    return [[KYCVerificationResult alloc] initWithDocumentJSON:response];
}

- (instancetype)initWithDocumentJSON:(NSDictionary *)response {
    if (response && (self = [super init])) {
        self.result                     = response[@"result"];
        self.firstName                  = response[@"firstName"];
        self.middleName                 = response[@"middleName"];
        self.surname                    = response[@"surname"];
        self.gender                     = response[@"gender"];
        self.nationality                = response[@"nationality"];
        self.expirationDate             = response[@"expirationDate"];
        self.birthDate                  = response[@"birthDate"];
        self.documentNumber             = response[@"documentNumber"];
        self.documentType               = response[@"documentType"];
        self.totalVerificationsDone     = [response[@"totalVerificationsDone"] integerValue];
        self.fields                     = [KYCFields createWithJSON:response[@"fields"]];
        self.docTemplate                = [KYCTemplate createWithJSON:response[@"template"]];
        self.alerts                     = [NSMutableArray new];
        for (NSDictionary *loopAlert in response[@"alerts"]) {
            [(NSMutableArray *)_alerts addObject:[KYCAlert createWithJSON:loopAlert]];
        }
        self.numberOfImagesProcessed    = [response[@"numberOfImagesProcessed"] integerValue];
    }
    
    return self;
}

- (NSString *)description {
    NSMutableString *retValue = [NSMutableString stringWithFormat:@"%@:\n", NSStringFromClass([self class])];
    
    [retValue appendFormat:@"result: %@\n", _result];
    [retValue appendFormat:@"firstName: %@\n", _firstName];
    [retValue appendFormat:@"middleName: %@\n", _middleName];
    [retValue appendFormat:@"surname: %@\n", _surname];
    [retValue appendFormat:@"gender: %@\n", _gender];
    [retValue appendFormat:@"nationality: %@\n", _nationality];
    [retValue appendFormat:@"expiryDate: %@\n", _expirationDate];
    [retValue appendFormat:@"birthDate: %@\n", _birthDate];
    [retValue appendFormat:@"documentNumber: %@\n", _documentNumber];
    [retValue appendFormat:@"documentType: %@\n", _documentType];
    [retValue appendFormat:@"totalVerificationsDone: %ld\n", (long)_totalVerificationsDone];
    [retValue appendFormat:@"fields: %@\n", _fields];
    [retValue appendFormat:@"docTemplate: %@\n", _docTemplate];
    [retValue appendFormat:@"alerts: %@\n", _alerts];
    [retValue appendFormat:@"numberOfImagesProcessed: %ld\n", (long)_numberOfImagesProcessed];

    return retValue;
}

@end
