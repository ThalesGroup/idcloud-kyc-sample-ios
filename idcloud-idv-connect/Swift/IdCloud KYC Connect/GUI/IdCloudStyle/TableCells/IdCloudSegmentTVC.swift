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

let kTableCellSegment = "IdCloudSegmentTVC"

class IdCloudSegmentTVC : UITableViewCell {
    internal var enabled: Bool = false
    
    @IBOutlet private weak var labelTitle: UILabel!
    @IBOutlet private weak var segmentValue: UISegmentedControl!
    
    private var currentOption: IdCloudOption!
    
    // MARK: - Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.clear
        backgroundView?.backgroundColor = UIColor.clear
        
        enabled = true
    }
    
    // MARK: - User Interface
    
    @IBAction func onSegmentChanged(_ sender: UISegmentedControl) {
        if currentOption != nil, let method = currentOption.methodSet as? (Int) -> () {
            method(sender.selectedSegmentIndex)
        } else {
            // Incorrect selector configuration in KYCManager.init
            fatalError()
        }
    }
    
}

// MARK: - KYCCellProtocol

extension IdCloudSegmentTVC: IdCloudCellProtocol {
    func onUserTap() {
        // Ignore
    }
    
    func updateWithOption(_ option: IdCloudOption) {
        currentOption = option
        
        labelTitle.text = option.titleCaption
        
        // Reload segments
        segmentValue.removeAllSegments()
        for loopItem in currentOption.options {
            segmentValue.insertSegment(withTitle: loopItem.value, at: segmentValue.numberOfSegments, animated: false)
        }
        
        if let method = option.methodGet as? () -> Int {
            segmentValue.selectedSegmentIndex = method()
        } else {
            // Incorrect selector configuration in KYCManager.init
            fatalError()
        }
    }
    
    func setEnabled(_ newValue: Bool) {
        enabled = newValue
        
        labelTitle.isEnabled = newValue
        segmentValue.isEnabled = newValue
    }
}
