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



#import "KYCFields.h"

@implementation KYCFields

+ (instancetype)createWithJSON:(NSDictionary *)response {
    return [[KYCFields alloc] initWithDocumentJSON:response];
}

- (instancetype)initWithDocumentJSON:(NSDictionary *)response {
    if (response && (self = [super init])) {
        self.ocr        = [KYCFields parseNameValueArray:response key:@"OCR"];
        self.mrz        = [KYCFields parseNameValueArray:response key:@"MRZ"];
        self.magstripe  = [KYCFields parseNameValueArray:response key:@"MAGSTRIPE"];
        self.barcode2d  = [KYCFields parseNameValueArray:response key:@"BARCODE_2D"];
        self.native     = [KYCFields parseNameValueArray:response key:@"NATIVE"];
    }
    
    return self;
}

+ (NSArray<KYCNameValue *> *)parseNameValueArray:(NSDictionary *)response key:(NSString *)key {
    NSMutableArray *retValue = [NSMutableArray new];
    for (NSDictionary *loopNameValue in response[key]) {
        [retValue addObject:[KYCNameValue createWithJSON:loopNameValue]];
    }
    
    return retValue;
}

- (NSString *)description {
    NSMutableString *retValue = [NSMutableString stringWithFormat:@"%@:\n", NSStringFromClass([self class])];
    
    [retValue appendFormat:@"ocr: %@\n", _ocr];
    [retValue appendFormat:@"mrz: %@\n", _mrz];
    [retValue appendFormat:@"magstripe: %@\n", _magstripe];
    [retValue appendFormat:@"barcode2d: %@\n", _barcode2d];
    [retValue appendFormat:@"native: %@\n", _native];

    return retValue;
}

@end
