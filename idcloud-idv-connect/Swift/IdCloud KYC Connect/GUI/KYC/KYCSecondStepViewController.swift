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

class KYCSecondStepViewController: BaseViewController {
    
    // MARK: - Life Cycle
    
    @IBOutlet private weak var buttonIdCard: IdCloudButton!
    @IBOutlet private weak var buttonPassport: IdCloudButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        var delay:CGFloat = 0.0
        IdCloudHelper.animateView(buttonIdCard, inParent: view, withDelay: &delay)
        IdCloudHelper.animateView(buttonPassport, inParent: view, withDelay: &delay)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "segueIdCard") {
            if let destination = segue.destination as? KYCIdCardPassportViewController {
                destination.type = KYCDocumentType.idCard
            }
        } else if (segue.identifier == "segueStandardPassport") {
            if let destination = segue.destination as? KYCIdCardPassportViewController {
                destination.type = KYCDocumentType.passport
            }
        }
    }
}
