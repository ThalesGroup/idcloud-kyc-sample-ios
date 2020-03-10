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

enum IdCloudOptionSection {
    case general
    case riskManagement
    case identityDocumentScan
    case faceCapture
    case version
}

enum IdCloudOptionType {
    case checkbox
    case number
    case version
    case segment
    case button
    case text
    
    static var allCases: [IdCloudOptionType] {
        return [.checkbox, .number, .version, .segment, .button, .text]
    }

}

enum KYCDocumentType {
    case idCard
    case passport
    case passportBiometric
}

class IdCloudOption : NSObject {
    
    private var _section: IdCloudOptionSection
    var section: IdCloudOptionSection {
        get { return _section }
    }
    private var _type: IdCloudOptionType
    var type: IdCloudOptionType {
        get { return _type }
    }
    private var _methodGet: Any!
    var methodGet: Any! {
        get { return _methodGet }
    }
    private var _methodSet: Any!
    var methodSet: Any! {
        get { return _methodSet }
    }
    private var _titleCaption: String!
    var titleCaption: String! {
        get { return _titleCaption }
    }
    private var _titleDescription: String!
    var titleDescription: String! {
        get { return _titleDescription }
    }
    private var _minValue: Int
    var minValue: Int {
        get { return _minValue }
    }
    private var _maxValue: Int
    var maxValue: Int {
        get { return _maxValue }
    }
    private var _options: [String: String]!
    var options: [String: String]! {
        get { return _options }
    }
    private var _methodButton: Any!
    var methodButton: Any! {
        get { return _methodButton }
    }
    
    class func number(caption: String,
                      description: String!,
                      section: IdCloudOptionSection,
                      methodGet: @escaping () -> Int,
                      methodSet: @escaping (Int) -> (),
                      minValue: Int,
                      maxValue: Int) -> IdCloudOption {
        return IdCloudOption(type: IdCloudOptionType.number,
                             caption: caption,
                             section: section,
                             description: description,
                             methodGet: methodGet,
                             methodSet: methodSet,
                             minValue: minValue,
                             maxValue: maxValue)
    }
    
    class func checkbox(caption: String,
                        description: String!,
                        section: IdCloudOptionSection,
                        methodGet: @escaping () -> Bool,
                        methodSet: Any) -> IdCloudOption {
        return IdCloudOption(type: IdCloudOptionType.checkbox,
                             caption: caption,
                             section: section,
                             description: description,
                             methodGet: methodGet,
                             methodSet: methodSet)
    }
    
    class func version(caption: String,
                       description: String!) -> IdCloudOption {
        return IdCloudOption(type: IdCloudOptionType.version,
                             caption: caption,
                             section: IdCloudOptionSection.version,
                             description: description)
    }
    
    class func text(caption: String,
                    section: IdCloudOptionSection,
                    methodGet: @escaping() -> (String)) -> IdCloudOption {
        return IdCloudOption(type: IdCloudOptionType.text,
                             caption: caption,
                             section: section,
                             description: nil,
                             methodGet: methodGet)
    }
    
    class func segment(caption: String,
                       section: IdCloudOptionSection,
                       options: [String: String],
                       methodGet: @escaping () -> Int,
                       methodSet: @escaping (Int) -> ()) -> IdCloudOption {
        return IdCloudOption(type: IdCloudOptionType.segment,
                             caption: caption,
                             section: section,
                             methodGet: methodGet,
                             methodSet: methodSet,
                             options: options)
    }
    
    class func button(caption: String,
                      section: IdCloudOptionSection,
                      method: @escaping () -> ()) -> IdCloudOption {
        return IdCloudOption(type: IdCloudOptionType.button,
                             caption: caption,
                             section: section,
                             methodButton: method)
    }
    
    init(type: IdCloudOptionType,
         caption: String,
         section: IdCloudOptionSection,
         description: String! = nil,
         methodGet: Any! = nil,
         methodSet: Any! = nil,
         minValue: Int! = 0,
         maxValue: Int! = 0,
         options: [String: String]! = nil,
         methodButton: Any! = nil) {
        _type               = type
        _titleCaption       = caption
        _titleDescription   = description
        _section            = section
        _methodGet          = methodGet
        _methodSet          = methodSet
        _minValue           = minValue
        _maxValue           = maxValue
        _options            = options
        _methodButton     = methodButton
    }
}
