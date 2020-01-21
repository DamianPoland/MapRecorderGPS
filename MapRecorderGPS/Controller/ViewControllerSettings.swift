//
//  ViewControllerInfo.swift
//  MapRecorderGPS
//
//  Created by Wolf on 05/12/2019.
//  Copyright © 2019 WolfMobileApp. All rights reserved.
//

import UIKit
import StoreKit

class ViewControllerSettings: UIViewController, SKPaymentTransactionObserver {

    // views
    @IBOutlet weak var viewUnits: UISegmentedControl!
    @IBOutlet weak var viewStackWithButtonsRemoveAndRestore: UIStackView!
    
    // do płatności
    let productID = "com.wolfmobileapps.MapRecorderGPS.TurnOffAdds" // to jest productID nadany w konsoli jak jest tworzona płatność
    
    // user defaults
    let defaults = UserDefaults.standard
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ustawienie segmented control w zależności od userDefaults
        if defaults.bool(forKey: C.keyToSwitchUnitsOnOff) {
            viewUnits.selectedSegmentIndex = 1
        } else {
            viewUnits.selectedSegmentIndex = 0
        }
        
        // dodanie delegata do protokołu SKPaymentTransactionObserver
        SKPaymentQueue.default().add(self)
        
        // ukryje przyciski: do płacenia i restore jak już zostało zapłacone lub przywrócone
        if defaults.bool(forKey: C.keyToTurnOffAdds) {
            viewStackWithButtonsRemoveAndRestore.isHidden = true
        }

    }
    
    //button to set Units
    @IBAction func buttonUnits(_ sender: UISegmentedControl) {
        
        switch viewUnits.selectedSegmentIndex {
        case 0:
            defaults.set(false, forKey: C.keyToSwitchUnitsOnOff)
        case 1:
            defaults.set(true, forKey: C.keyToSwitchUnitsOnOff)
        default:
            print("Error segmented Selected")
        }
    }
    
    // button do płacenia - w odpoowiedzi odpali metodę paymentQueue
    @IBAction func buttonRemoveAdds(_ sender: UIButton) {
        if SKPaymentQueue.canMakePayments() { // może dokonywać płatności
            let paymentRequest = SKMutablePayment() // stworzenie rządanie zapłaty
            paymentRequest.productIdentifier = productID // przypisanie productID so rządania zapaty
            SKPaymentQueue.default().add(paymentRequest) // wywołanie rządania zapłąty
        } else { // nie może dokkonywać płatności
            print("User can't make payment")
        }
    }
    
    // button do restore - w odpoowiedzi odpali metodę paymentQueue
    @IBAction func buttonRestore(_ sender: UIButton) {
        SKPaymentQueue.default().restoreCompletedTransactions() // zapytanie do apple czy było już płącone
    }
    
    
    // funkcja pochodząca z protokołu SKPaymentTransactionObserver zwraca dane o płatnościach - np czy udana (purchased), czy nie (failed), czy restored
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) { // [SKPaymentTransaction] to tablica z płatnościami bo płatności może być ustawionych więcej niż jedna - nie wiem jak to dziła przy kilku płatnościach
        
        for transaction in transactions { // rozpakowanie tablicy z płatnościami, jak jest tylko jedna płatność ustwiona to bedzie tylko jeden obiekt w tablicy
            if transaction.transactionState == .purchased { // jeśli zakup zrealizowany
                defaults.set(true, forKey: C.keyToTurnOffAdds) // ustawienie tru na usunięcie reklam
                viewStackWithButtonsRemoveAndRestore.isHidden = true // ukrycie przyciskód do płacenia i restore jak już zostało zapłacone
                SKPaymentQueue.default().finishTransaction(transaction) // zakończenie transakcji
                
            } else if transaction.transactionState == .restored { // jeśli zakup był wcześniej i teraz jest restored
                defaults.set(true, forKey: C.keyToTurnOffAdds) // ustawienie tru na usunięcie reklam
                viewStackWithButtonsRemoveAndRestore.isHidden = true // ukrycie przyciskód do płacenia i restore jak już zostało zapłacone
                SKPaymentQueue.default().finishTransaction(transaction) // zakończenie transakcji
                showToast(controller: self, message: "Restored", seconds: 1.5) // pokazać toast że się udało bo user nie dostaje żadnego powiadomienia
                
            }else if transaction.transactionState == .failed { // jeśli zakup nie zrealizowany
                if let error = transaction.error { // jeśli wiadomo jaki był error
                    let errorDescription = error.localizedDescription
                    print("Transaction failed due to error: \(errorDescription)")
                } else { // jeśli nie wiadomo jaki był error
                    print("Transaction failed")
                }
                SKPaymentQueue.default().finishTransaction(transaction) // zakończenie transakcji
                
            }
        }
    }
    
    //toast
    func showToast(controller: UIViewController, message: String, seconds: Double) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = UIColor.black
        alert.view.alpha = 0.6
        alert.view.layer.cornerRadius = 15
        controller.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)        }
    }

}
