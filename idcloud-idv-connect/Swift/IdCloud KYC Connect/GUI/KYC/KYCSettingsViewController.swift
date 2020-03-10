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

let kTableCellHeader = "KYCHeader"

class KYCSettingsViewController: BaseViewController {
    
    // MARK: - Life Cycle
    
    @IBOutlet private weak var tableSettings: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableSettings.delegate = self
        tableSettings.dataSource = self
        
        // Register all cell types.
        for loopOption in IdCloudOptionType.allCases {
            registerCellWithType(loopOption)
        }
        
        // Register headers.
        tableSettings.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: kTableCellHeader)
        
        // Notifications about data layer change to reload table.
        // Unregistration is done in base class.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(UICollectionView.reloadData),
                                               name: Notification.Name.DataLayerChanged,
                                               object: nil)
        
        reloadData()
    }
    
    
    // MARK: - Private Helpers
    
    private func reloadData() {
        tableSettings.reloadData()
    }
    
    private func registerCellWithType(_ type: IdCloudOptionType) {
        let cellId = cellIdWithType(type)!
        tableSettings.register(UINib(nibName: cellId, bundle: Bundle.main), forCellReuseIdentifier: cellId)
    }
    
    private func cellIdWithType(_ type: IdCloudOptionType) -> String! {
        switch (type) { 
        case IdCloudOptionType.checkbox:
            return kTableCellBoolean
        case IdCloudOptionType.version:
            return kTableCellVersion
        case IdCloudOptionType.number:
            return kTableCellNumber
        case IdCloudOptionType.segment:
            return kTableCellSegment
        case IdCloudOptionType.button:
            return kTableCellButton
        case IdCloudOptionType.text:
            return kTableCellText
        }
    }
}

// MARK: - UITableViewDelegate

extension KYCSettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Versions does not need to be that big.
        return indexPath.section == 3 ? 60 : 80
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // Make header orange with black text
        let headerView = view as! UITableViewHeaderFooterView
        headerView.contentView.backgroundColor = UIColor.lightGray
        headerView.textLabel?.textColor = UIColor.init(named: "TextPrimary")
    }
    
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let cell = tableView.cellForRow(at: indexPath) as? IdCloudCellProtocol  {
            // Ignore selection on disabled cells.
            if (cell.enabled) {
                let option = KYCManager.sharedInstance.options[indexPath.section][indexPath.row]
                // Make sure that all cells with inputs are visible on screen.
                // Currently only supported cell is numeric.
                if option.type == IdCloudOptionType.number {
                    tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: true)
                }
                
                // Handle tap instead of selection to prevent different behaviour on different devices.
                cell.onUserTap()
                
                // Call after tap handler to reflect updated values.
                //                if (option.section == IdCloudOptionSection.general) {
                //                    tableView.reloadSections(IndexSet(integer: IdCloudOptionSection.faceCapture.rawValue), with: UITableView.RowAnimation.fade)
                //                }
            }
        }
        
        // Do not allow iOS to handle selection.
        return nil
    }
}

// MARK: - UITableViewDataSource

extension KYCSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return KYCManager.sharedInstance.optionCaptions.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let retValue = self.tableSettings.dequeueReusableCell(withIdentifier: kTableCellHeader)
        
        if (KYCManager.sharedInstance.optionCaptions.count > section) {
            retValue?.textLabel?.text = KYCManager.sharedInstance.optionCaptions[section]
        }
        
        return retValue;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return KYCManager.sharedInstance.options[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var retValue:UITableViewCell! = nil
        
        let option:IdCloudOption! = KYCManager.sharedInstance.options[indexPath.section][indexPath.row]
        retValue = tableView.dequeueReusableCell(withIdentifier: self.cellIdWithType(option.type))
        
        if let cellProtocol = retValue as? IdCloudCellProtocol {
            cellProtocol.updateWithOption(option)
            // Enable face id section only when face id is enabled in the first place.
            if option.section == IdCloudOptionSection.faceCapture {
                cellProtocol.enabled = KYCManager.facialRecognition()
            } else {
                // Cells are reused. Re-enable others.
                cellProtocol.enabled = true
            }
        }
        
        return retValue
    }
}
