//
//  UXPhoneNumberInputViewController.swift
//  Pods
//
//  Created by Eddie Hiu-Fung Lau on 15/12/2016.
//
//

import UIKit
import PhoneNumberKit
import AJCountryPicker2

open class UXPhoneNumberInputViewController: UITableViewController {
    
    // MARK: - open variables
    
    // MARK: - open functions
    
    open var TRANS_PHONE                     = "Your Phone Number"
    open var TRANS_INVALID_COUNTRY           = "Invalid country code"
    open var TRANS_SELECT_LIST               = "Select From List"
    open var TRANS_MESSAGE_LABEL             = "Please fill in your phonenumber"
    open var TRANS_ERROR                     = "The phonenumber is incorrect"
    open var TRANS_COUNTRY_CODE_PLACEHOLDER  = "Country code"
    open var TRANS_PHONE_NUMBER_PLACEHOLDER  = "Your phone number"
    open var defaultValue                    = "+3133904562"
    
    open func done(withAction action: @escaping (_ phoneNumber:String)->Void) {
        doneButtonAction = action
    }
    
    // MARK: - Private variables
    @IBOutlet weak var countryCodePlaceholder: UILabel!
    @IBOutlet weak var countryCodeField: UITextField!
    @IBOutlet var phoneNumberPlaceholder: UILabel!
    @IBOutlet weak var phoneNumberField: UITextField!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var MessageLabel: UILabel!
    
    fileprivate let phoneNumberKit = PhoneNumberKit()
    
    fileprivate var selectedRegionCode: String? {
        
        guard let countryCodeText = countryCodeField.text else {
            return nil
        }
        
        guard let countryCode = UInt64(countryCodeText) else {
            return nil
        }
        return phoneNumberKit.mainCountry(forCode:countryCode)
        
    }
    
    
    // UI states
    fileprivate var shouldHideCountryCodePlaceholder: Bool {
        return (countryCodeField.text ?? "").characters.count > 0
    }
    
    fileprivate var shouldHidePhoneNumberPlaceholder: Bool {
        return (phoneNumberField.text ?? "").characters.count > 0
    }
    
    fileprivate var countryNameLabelText: String {
        
        guard let text = countryCodeField.text,!text.isEmpty else {
            return TRANS_SELECT_LIST
        }
        
        guard
            let code = UInt64(text),
            let country = phoneNumberKit.mainCountry(forCode: code),
            let displayName = (Locale.current as NSLocale).displayName(forKey: .countryCode, value: country)
            else {
                return TRANS_INVALID_COUNTRY
        }
        
        return displayName
        
    }
    
    fileprivate var shouldEnableDoneButton: Bool {
        
        guard let countryCodeText = countryCodeField.text,
            !countryCodeText.isEmpty,
            let phoneNumberText = phoneNumberField.text,
            !phoneNumberText.isEmpty,
            let _ = doneButtonAction
            else {
                return false
        }
        
        return true
    }
    
    fileprivate lazy var doneButtonItem: UIBarButtonItem = {
        
        let item = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(UXPhoneNumberInputViewController.didTapDoneButton))
        return item
        
    }()
    
    fileprivate var doneButtonAction: ((_ phoneNumber:String)->Void)? {
        didSet {
            if doneButtonAction != nil {
                
                navigationItem.rightBarButtonItem = doneButtonItem
                
            } else {
                
                navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    // MARK: - ViewController
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        title = NSLocalizedString(TRANS_PHONE, comment: "")
        var code = phoneNumberKit.countryCode(for:PhoneNumberKit.defaultRegionCode()) ?? 1
        var national : UInt64 = 0
        //let phoneNumber = phoneNumberKit.format(defaultValue, toType: .countryCode)
        do {
            let phoneNumber = try phoneNumberKit.parse(defaultValue)
            code = phoneNumber.countryCode
            national = phoneNumber.nationalNumber
            phoneNumberField.text = "\(national)"
        } catch {
            
        }
        
        countryCodeField.text = "+\(code)"
        countryNameLabel.text = countryNameLabelText
        MessageLabel.text = TRANS_MESSAGE_LABEL
        countryCodePlaceholder.isHidden = shouldHideCountryCodePlaceholder
        phoneNumberPlaceholder.isHidden = shouldHidePhoneNumberPlaceholder
        countryCodePlaceholder.text = TRANS_COUNTRY_CODE_PLACEHOLDER
        phoneNumberPlaceholder.text = TRANS_PHONE_NUMBER_PLACEHOLDER
        
        doneButtonItem.isEnabled = shouldEnableDoneButton
        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        phoneNumberField.becomeFirstResponder()
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open override func becomeFirstResponder() -> Bool {
        return phoneNumberField.becomeFirstResponder()
    }
    
    open override func resignFirstResponder() -> Bool {
        
        if countryCodeField.isFirstResponder {
            return countryCodeField.resignFirstResponder()
        }
        if phoneNumberField.isFirstResponder {
            return phoneNumberField.resignFirstResponder()
        }
        return super.resignFirstResponder()
        
    }
    
    
}

// MARK: - private functions
extension UXPhoneNumberInputViewController {
    
    func didTapDoneButton() {
        
        let countryCode = countryCodeField.text!
        let number = phoneNumberField.text!
        
        do {
            let parsedPhoneNumber = try phoneNumberKit.parse(countryCode + number)
            doneButtonAction?(phoneNumberKit.format(parsedPhoneNumber, toType: .e164))
        } catch let e as PhoneNumberError {
            
            let alertController = UIAlertController(title: "Error", message: TRANS_ERROR, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
            }))
            present(alertController, animated: true, completion: nil)
            
        } catch _ {
            
        }
        
        
        
    }
    
    
}

// MARK: UITableViewDelegate
extension UXPhoneNumberInputViewController {
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 && indexPath.row == 1 {
            
            let countryPicker = AJCountryPicker { country, code in
                self.countryNameLabel.text = country
                
                if let countryCode = self.phoneNumberKit.countryCode(for: code) {
                    self.countryCodeField.text = "+\(countryCode)"
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
            
            //countryPicker.customCountriesCode = phoneNumberKit.allCountries()
            countryPicker.showCallingCodes = true
            
            if let countryCodeText = countryCodeField.text, let code = UInt64(countryCodeText) {
                countryPicker.selectedCountryCode = phoneNumberKit.mainCountry(forCode: code)
            }
            
            navigationController?.pushViewController(countryPicker, animated: true)
            
        }
        
    }
    
}

extension UXPhoneNumberInputViewController : UITextFieldDelegate {
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == countryCodeField {
            
            phoneNumberField.becomeFirstResponder()
            
        } else if textField == phoneNumberField {
            
            if shouldEnableDoneButton {
                didTapDoneButton()
            }
            
        }
        return false
    }
    
    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == countryCodeField {
            
            // Use regex to verify the coountry code. The format likes +852
            guard let regex = try? NSRegularExpression(pattern: "^\\+[0-9]{1,4}$", options: []) else {
                return false
            }
            
            guard let text = textField.text else {
                return false
            }
            
            var countryCode = (text as NSString).replacingCharacters(in: range, with: string)
            
            if countryCode == "+" {
                
                textField.text = ""
                
            } else {
                
                if text == "" {
                    countryCode = "+" + countryCode
                }
                
                let matchCount = regex.numberOfMatches(in: countryCode, options: [], range: NSMakeRange(0, countryCode.characters.count))
                if matchCount > 0 {
                    textField.text = countryCode
                }
                
            }
            
            countryCodePlaceholder.isHidden = shouldHideCountryCodePlaceholder
            countryNameLabel.text = countryNameLabelText
            doneButtonItem.isEnabled = shouldEnableDoneButton
            return false
            
        } else if textField == phoneNumberField {
            
            guard let text = textField.text else {
                return false
            }
            
            if !string.isEmpty {
                
                guard let regex = try? NSRegularExpression(pattern: "^[0-9]+$", options: []) else {
                    return false
                }
                guard regex.numberOfMatches(in: string, options: [], range: NSMakeRange(0, string.characters.count)) > 0 else {
                    return false
                }
                
            }
            
            let rawPhoneNumber = (text as NSString).replacingCharacters(in: range, with: string)
            
            let selectedRegion = selectedRegionCode ?? PhoneNumberKit.defaultRegionCode()
            let formatter = PartialFormatter(phoneNumberKit: phoneNumberKit, defaultRegion: selectedRegion, withPrefix:false)
            textField.text = formatter.formatPartial(rawPhoneNumber)
            
            phoneNumberPlaceholder.isHidden = shouldHidePhoneNumberPlaceholder
            doneButtonItem.isEnabled = shouldEnableDoneButton
            return false
            
        }
        
        return true
    }
    
}

extension UXPhoneNumberInputViewController {
    
    open static func instantiate() -> UXPhoneNumberInputViewController {
        
        let bundle = Bundle(for:self)
        
        guard let resourceBundleURL = bundle.url(forResource: "UXPhoneNumberInput", withExtension: "bundle") else {
            fatalError("Couldn't instantiate UXPhoneNumberInputViewController")
        }
        
        guard let resourceBundle = Bundle(url: resourceBundleURL) else {
            fatalError("Couldn't instantiate UXPhoneNumberInputViewController")
        }
        
        let loginStoryboard = UIStoryboard(name: "UXPhoneNumberInputViewController", bundle: resourceBundle)
        guard let viewController = loginStoryboard.instantiateInitialViewController() as? UXPhoneNumberInputViewController else {
            fatalError("Couldn't instantiate UXPhoneNumberInputViewController")
        }
        
        return viewController
    }
    
}
