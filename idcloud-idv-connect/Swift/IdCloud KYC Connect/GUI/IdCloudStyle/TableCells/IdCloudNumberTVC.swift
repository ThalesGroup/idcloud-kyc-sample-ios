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

let kTableCellNumber = "IdCloudNumberTVC"

class IdCloudNumberTVC : UITableViewCell {
    internal var enabled: Bool = false
    
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelSubtitle: UILabel!
    @IBOutlet weak var value: UITextField!
    
    private var currentOption: IdCloudOption!
    
    // MARK: - Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.clear
        backgroundView?.backgroundColor = UIColor.clear
        
        value.layer.cornerRadius = 8.0
        value.layer.borderColor = UIColor.gray.cgColor
        value.layer.borderWidth = 1.0
        value.isUserInteractionEnabled = false
        
        // Add apply + cancel button to number cell text input.
        let numberToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        numberToolbar.isTranslucent = true
        numberToolbar.items = [
            UIBarButtonItem(title: TRANSLATE("STRING_COMMON_CANCEL"),
                            style: UIBarButtonItem.Style.plain,
                            target: self, action: #selector(onButtonPressedCancel)),
            
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil),
            
            UIBarButtonItem(title: TRANSLATE("STRING_COMMON_OK"),
                            style: UIBarButtonItem.Style.plain,
                            target: self, action: #selector(onButtonPressedOk))
        ]
        numberToolbar.sizeToFit()
        value.inputAccessoryView = numberToolbar
        
        enabled = true
    }
    
    // MARK: - Private Helpers
  
    override var isUserInteractionEnabled: Bool{
        willSet {
            // Textfiled should be disabled so we will handle cell select on one place.
            // But also must be reanabled to allow keyboard at all.
            value.isUserInteractionEnabled = !newValue
        }
    }
        
    // MARK: - User Interface
    
    @objc private func onButtonPressedCancel() {
        isUserInteractionEnabled = true
        value.resignFirstResponder()
        
        // Reload original value.
        if (currentOption != nil) {
            updateWithOption(currentOption)
        }
    }
    
    @objc private func onButtonPressedOk() {
        isUserInteractionEnabled = true
        value.resignFirstResponder()
        if (currentOption != nil) {
            // Fit value to defined range.
            var intValue = Int(value?.text ?? "") ?? 0
            intValue = max(min(currentOption.maxValue, intValue), currentOption.minValue)
            if let method = currentOption.methodSet as? (Int) -> () {
                method(intValue)
            } else {
                // Incorrect selector configuration in KYCManager.init
                fatalError()
            }
            
            // Reload saved value to ensure correct parsing.
            updateWithOption(currentOption)
        }
    }
}

// MARK: - KYCCellProtocol

extension IdCloudNumberTVC: IdCloudCellProtocol {
    func onUserTap() {
        if enabled {
            isUserInteractionEnabled = false
            value.becomeFirstResponder()
        }
    }
    
    func updateWithOption(_ option: IdCloudOption) {
        currentOption = option
        
        labelTitle.text = option.titleCaption
        labelSubtitle.text = option.titleDescription
        
        if let method = option.methodGet as? () -> Int {
            value.text = "\(method())"
        } else {
            // Incorrect selector configuration in KYCManager.init
            fatalError()
        }
    }
    
    func setEnabled(_ newValue:Bool) {
        enabled = newValue
        
        labelTitle.isEnabled = newValue
        labelSubtitle.isEnabled = newValue
        value.isEnabled = newValue
    }
}
