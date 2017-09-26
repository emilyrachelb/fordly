//
//  MainViewController.swift
//  Fordly
//
//  Created by Samantha Emily-Rachel Belnavis on 2017-09-18.
//  Copyright © 2017 Samantha Emily-Rachel Belnavis. All rights reserved.
//

// import required frameworks
import UIKit
import Firebase
import GoogleSignIn
import HealthKit

// start MainViewController class
class HomeViewController: UIViewController, GIDSignInUIDelegate {
  // setup firebase storage
  // create reference to storage service using the default firebase app
  let storage = Storage.storage()
  
  private let dataTypesToRead: NSSet = {
    let healthKitManager = HealthKitManager.sharedInstance
    return NSSet(objects:
        healthKitManager.biologicalSexCharacteristic,
        healthKitManager.dateOfBirthCharacteristic,
        healthKitManager.usersHeight,
        healthKitManager.usersWeight,
        healthKitManager.usersStepCount,
        healthKitManager.usersSleepActivity,
        healthKitManager.usersSexualActivity)
  }()
  
  private enum IdentifyingDataFields: Int {
    case DateOfBirth, BiologicalSex
    
    func data() -> (title: String, value: String?) {
      let healthKitManager = HealthKitManager.sharedInstance
      
      switch self {
      case .DateOfBirth:
        return("Date of Birth", healthKitManager.dateOfBirth)
      case .BiologicalSex:
        return("Gender", healthKitManager.dateOfBirth)
      }
    }
  }
  // import variables
  let appDelegate = UIApplication.shared.delegate as! AppDelegate
  var googleUserId: String?
  var googleUserName: String?
  var googleUserEmail: String?
  var googleUserPhoto: URL!
  var googleUserGender: String?
  
  // HealthKit variables
  var healthStore: HKHealthStore?
  var userHeight: HKQuantity?
  var userWeight: HKQuantity?
  var userBMI: HKQuantity?
  var userSteps: HKQuantity?
  var userSleep: HKCategoryValue?
  var userSexualActvity: HKCategoryValue?
  var userGender: String!
  
  // create firebase references
  var databaseReference: DatabaseReference!
  
  // MARK: Properties
  @IBOutlet weak var userEmail: UILabel!
  @IBOutlet weak var userName: UILabel!
  @IBOutlet weak var userPhoto: UIImageView!
  @IBOutlet weak var userAgeLabel: UILabel!
  @IBOutlet weak var userDOBLabel: UILabel!
  @IBOutlet weak var userGenderIcon: UIImageView!
  
  @IBAction func goToMain(segue:UIStoryboardSegue){
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  // get image from source asynchronously
  func getImageFromUrl(url: URL, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
    URLSession.shared.dataTask(with: url) {
      (data, response, error) in
      completion(data, response, error)
    }.resume()
  }
  
  // download the image
  func downloadUserImage(url: URL) {
    print("Download Started")
    getImageFromUrl(url: url) { (data, response, error) in
      guard let data = data, error == nil else { return }
      print("Download Finished")
      DispatchQueue.main.async { () -> Void in
        self.userPhoto.image = UIImage(data: data)
      }
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
   HealthKitManager.sharedInstance.requestHealthKitAuthorization(dataTypesToWrite: nil, dataTypesToRead: dataTypesToRead)
    
    if (GIDSignIn.sharedInstance().hasAuthInKeychain()) {
      // get user id from current user
      googleUserId = appDelegate.gUserId
      googleUserName = appDelegate.gUserName
      googleUserEmail = appDelegate.gUserEmail
      googleUserPhoto = appDelegate.gUserPhoto
      googleUserGender = appDelegate.gUserGender
      
      // assign values to labels that are passed to ViewController
      userName.text = googleUserName
      userEmail.text = googleUserEmail
      
      // download user's photo
      userPhoto.contentMode = .scaleAspectFit
      downloadUserImage(url: appDelegate.gUserPhoto)
      
      // get the user's gender from HealthKit
      let userAgeAndGender = try? updateUserProfile()
      userGender = userAgeAndGender?.biologicalSex.stringRepresentation
      print("\(userGender)")
      
      // set the user's gender icon
      if (userGender == "female") {
        userGenderIcon.image = UIImage(named: "genderIcon-female")
      }
      
      
      print("User already signed in")
      print("User ID: \(String(describing: googleUserId))")
      print("User's Name: \(String(describing: googleUserName))")
      print("User's Email: \(String(describing: googleUserEmail))")
      print("User's Gender: \(String(describing: googleUserGender))")
      print("User Photo URL: \(String(describing: googleUserPhoto))")
    } else {
      print("User not signed in")
      self.performSegue(withIdentifier: "goToLogin", sender: nil)
    }
  }

  func updateUserProfile() throws -> (age: Int, biologicalSex: HKBiologicalSex){
      
    // database reference
    databaseReference = Database.database().reference()
    let healthKitStore = HKHealthStore()
    do {
      let birthdayComponents = try? healthKitStore.dateOfBirthComponents()
      let biologicalSex = try? healthKitStore.biologicalSex()
      
      let today = Date()
      let calendar = Calendar.current
      let currentDateComponents = calendar.dateComponents([.year], from: today)
      
      let thisYear = currentDateComponents.year!
      let age = thisYear - (birthdayComponents?.year!)!
      
      let unwrappedBiologicalSex = biologicalSex?.biologicalSex
      
      return (age, unwrappedBiologicalSex!)
    }
  }
  
}
