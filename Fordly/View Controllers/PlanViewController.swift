//
//  PlanViewController.swift
//  Fordly
//
//  Created by Samantha Emily-Rachel Belnavis on 2017-09-28.
//  Copyright © 2017 Samantha Emily-Rachel Belnavis. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreLocation
import UserNotifications

class PlanViewController: UIViewController, CLLocationManagerDelegate {
  
  // new location manager
  let locationManager = CLLocationManager()
  var startLocation: CLLocation!
  
  // firebase setup
  var databaseRef: DatabaseReference!
  
  // Taxi Copter
  @IBOutlet weak var taxiCopterView: UIView!
  @IBOutlet weak var taxiCopterButton: UIButton!
  @IBOutlet weak var taxiCopterImage: UIImageView!
  @IBAction func showTaxiCopterAlert(_ sender: UIButton) {
    // create alert
    let alert = UIAlertController(title: "Enjoy your flight", message: "A taxi is on it's way to you now.\nEst. Arrival Time: 4 minutes", preferredStyle: UIAlertControllerStyle.alert)
    // add action
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    // show the alert
    self.present(alert, animated: true, completion: nil)
    
    // get user's location
    startLocation = nil
  }
  
  // Blue Pacific Rocket
  @IBOutlet weak var bluePacView: UIView!
  @IBOutlet weak var bluePacButton: UIButton!
  @IBOutlet weak var bluePacImage: UIImageView!
  @IBAction func showBluePacAlert(_ sender: UIButton) {
    // create alert
    let alert = UIAlertController(title: "Booking Confirmed", message: "A message has been sent to you containing your ticket for the train.", preferredStyle: UIAlertControllerStyle.alert)
    // add action
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    // show the alert
    self.present(alert, animated: true, completion: nil)
    
    // get user's location
    startLocation = nil
    
    let notification = UNMutableNotificationContent()
    notification.title = "Blue Pacific Express Booking"
    notification.body = "Your confimation number is #6584733902112353"
    
    let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    let request = UNNotificationRequest(identifier: "notification1", content: notification, trigger: notificationTrigger)
    
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }
  
  // Soma Delivery
  @IBOutlet weak var somaDropView: UIView!
  @IBOutlet weak var somaDropButton: UIButton!
  @IBOutlet weak var somaDropImage: UIImageView!
  @IBAction func showSomaDropAlert(_ sender: UIButton) {
    // create alert
    let alert = UIAlertController(title: "Your order has been recieved", message: "A package of soma is on it's way to you now via drone.\nEst. Arrival Time: 2 minutes", preferredStyle: UIAlertControllerStyle.alert)
    // add action
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    // show the alert
    self.present(alert, animated: true, completion: nil)
    
    // get user's location
    startLocation = nil
  }

  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let latestLocation: CLLocation = locations[locations.count - 1]
    
    if startLocation == nil {
      startLocation = latestLocation
    }
    
    let distanceBetween: CLLocationDistance = latestLocation.distance(from: startLocation)
    
  }
  
  func initNotificationSetupCheck() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
    { (success, error) in
      if success {
        print("Permission Granted")
      } else {
        print("There was a problem!")
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
    startLocation = nil
    
    initNotificationSetupCheck()
    
    databaseRef = Database.database().reference()
    
  }
  
  override func viewDidAppear(_ animated: Bool){
    super.viewDidAppear(animated)
    
    // taxi copter
    taxiCopterView.layer.borderWidth = 1
    taxiCopterView.layer.cornerRadius = 4
    taxiCopterView.layer.borderColor = UIColor(rgb: 0x000000, a: 1).cgColor
    
    taxiCopterImage.layer.borderWidth = 1
    taxiCopterImage.layer.cornerRadius = 10
    taxiCopterImage.clipsToBounds = true
    taxiCopterImage.layer.borderColor = UIColor(rgb: 0xffffff, a: 0).cgColor
    
    taxiCopterButton.layer.borderWidth = 1
    taxiCopterButton.layer.cornerRadius = 4
    taxiCopterButton.layer.borderColor = UIColor(rgb: 0x007AFF, a: 1).cgColor
    
    // blue pacific rocket
    bluePacView.layer.borderWidth = 1
    bluePacView.layer.cornerRadius = 4
    bluePacView.layer.borderColor = UIColor(rgb: 0x000000, a: 1).cgColor
    
    bluePacImage.layer.borderWidth = 1
    bluePacImage.layer.cornerRadius = 10
    bluePacImage.clipsToBounds = true
    bluePacImage.layer.borderColor = UIColor(rgb: 0xffffff, a: 0).cgColor
    
    bluePacButton.layer.borderWidth = 1
    bluePacButton.layer.cornerRadius = 4
    bluePacButton.layer.borderColor = UIColor(rgb: 0x007AFF, a: 1).cgColor
    
    // soma delivery
    somaDropView.layer.borderWidth = 1
    somaDropView.layer.cornerRadius = 4
    somaDropView.layer.borderColor = UIColor(rgb: 0x000000, a: 1).cgColor
    
    somaDropImage.layer.borderWidth = 1
    somaDropImage.layer.cornerRadius = somaDropImage.frame.height/2
    somaDropImage.clipsToBounds = true
    somaDropImage.layer.borderColor = UIColor(rgb: 0xffffff, a: 0).cgColor
    
    somaDropButton.layer.borderWidth = 1
    somaDropButton.layer.cornerRadius = 4
    somaDropButton.layer.borderColor = UIColor(rgb: 0x007AFF, a: 1).cgColor
  }
  
}

