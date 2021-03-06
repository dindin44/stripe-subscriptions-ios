//
//  ViewController.swift
//  Stripe-Subscription-Example
//
//  Created by Dinesh Vijaykumar on 17/11/2021.
//

import UIKit
import Stripe

class ViewController: UIViewController {
    @IBOutlet private var fetchPaymentIntentButton: UIButton!
    @IBOutlet private var subscribeButton: UIButton!
    @IBOutlet private var statusTextView: UITextView!
    
    private var spinnerView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
    private var paymentIntentClientSecret: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchPaymentIntentButton.isHidden = false
        subscribeButton.isHidden = true
        
        spinnerView.hidesWhenStopped = true
        spinnerView.color = UIColor.black.withAlphaComponent(0.7)
        view.addSubview(spinnerView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        spinnerView.center = view.center
    }
    
    @IBAction private func fetchPaymentIntent(_ sender: Any) {
        guard let url = URL(string: Constants.backendUrl)?.appendingPathComponent("/subscribe") else { return }
        
        self.showSpinner()
        
        let body: [String: Any] = [
            "email": "testUser@example.com",
            "priceID": Constants.priceID
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            self?.hideSpinner()
            guard
                let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                let customer = json["customer"] as? String,
                let clientSecret = json["paymentIntent"] as? String
            else {
                let message = error?.localizedDescription ?? "Failed to decode response from server."
                self?.statusTextView.text.append(contentsOf: "Error loading page - message: \(message)")
                return
            }
            
            DispatchQueue.main.async {
                self?.fetchPaymentIntentButton.isHidden = true
                self?.subscribeButton.isHidden = false
                
                let message = "Customer \(customer) has been created"
                self?.statusTextView.text.append(contentsOf: "\n\(message)")
                
                self?.paymentIntentClientSecret = clientSecret
                self?.statusTextView.text.append(contentsOf: "\nClient Secret: \(clientSecret)")
            }
        })
        
        task.resume()
    }
    
    @IBAction private func pay(_ sender: Any) {
        guard let paymentIntentClientSecret = self.paymentIntentClientSecret else {
            return
        }
        
        var configuration = PaymentSheet.Configuration()
        configuration.allowsDelayedPaymentMethods = true
        
        let paymentSheet = PaymentSheet(
            paymentIntentClientSecret: paymentIntentClientSecret,
            configuration: configuration)
        
        paymentSheet.present(from: self) { [weak self] (paymentResult) in
            switch paymentResult {
            case .completed:
                self?.statusTextView.text.append(contentsOf: "\nPayment Complete. User subscribed!")
            case .canceled:
                self?.statusTextView.text.append(contentsOf: "\nPayment canceled!")
            case .failed(let error):
                self?.statusTextView.text.append(contentsOf: "\nPayment failed, message: \(error.localizedDescription)")
            }
        }
    }
    
    private func showSpinner() {
        DispatchQueue.main.async {
            self.spinnerView.startAnimating()
        }
    }
    
    private func hideSpinner() {
        DispatchQueue.main.async {
            self.spinnerView.stopAnimating()
        }
    }
}

