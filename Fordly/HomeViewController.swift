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

enum ProfileKeys: String {
  case Age = "age"
  case Gender = "gender"
  case Steps = "steps"
  case Sleep = "sleep"
  case SexualActivity = "sexualactivity"
}

// start MainViewController class
class HomeViewController: UIViewController, GIDSignInUIDelegate {
  
  private let kProfileUnit = 0
  private let kProfileDetail = 1
  
  private var userProfiles: [ProfileKeys: [String]]?
  
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
  
  // MARK: Properties
  @IBOutlet weak var userEmail: UILabel!
  @IBOutlet weak var userName: UILabel!
  @IBOutlet weak var userPhoto: UIImageView!
  
  @IBAction func goToMain(segue:UIStoryboardSegue){
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    GIDSignIn.sharedInstance().uiDelegate = self
    GIDSignIn.sharedInstance().signInSilently()
    
    
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
    if (GIDSignIn.sharedInstance().hasAuthInKeychain()) {
      // populate signin values
      googleUserId = appDelegate.gUserId
      googleUserName = appDelegate.gUserName
      googleUserEmail = appDelegate.gUserEmail
      googleUserPhoto = appDelegate.gUserPhoto
      googleUserGender = appDelegate.gUserGender
      
      // assign values to labels that are passed to ViewController
      userName.text = appDelegate.gUserName
      userEmail.text = appDelegate.gUserEmail
      
      // Download and set profile photo
      userPhoto.contentMode = .scaleAspectFit
      downloadUserImage(url: googleUserPhoto)
      
      print("User already signed in")
      print("User ID: \(String(describing: googleUserId))")
      print("User's Name: \(String(describing: googleUserName))")
      print("User's Email: \(String(describing: googleUserEmail))")
      print("User's Gender: \(String(describing: googleUserGender))")
    } else {
      print("User not signed in")
      self.performSegue(withIdentifier: "goToLogin", sender: nil)
    }
    
    // Set up HKHealthStore and ask for read permissions
    guard HKHealthStore.isHealthDataAvailable() else {
      return
    }
    
    let readDataTypes: Set<HKSampleType> = self.dataTypesToRead()
    
    let completion: ((Bool, Error?) -> Void)! = {
      (success, error) -> Void in
      
      if !success {
        print("You didn't allow HealthKit to access the data types!")
        return
      }
      
      DispatchQueue.main.async {
        // update the ui based on the current user's health information.
        self.updateUserAge()
        //self.updateUserGender()
        self.updateUserSteps()
        self.updateUserSleep()
        self.updateUserSexualActivity()
      }
    }
    if let healthStore = self.healthStore {
      healthStore.requestAuthorization(toShare: [], read: readDataTypes, completion: completion)
    }
  }
  
  // MARK: Private Method
  // MARK: HealthKit Permissions
  private func dataTypesToRead() -> Set<HKSampleType> {
    let heightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
    let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
    let bmiType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)!
    let stepsType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
    
    let sleepType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
    let sexualActivityType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sexualActivity)!
    
    let readDataTypes: Set<HKSampleType> = [heightType, weightType, bmiType, stepsType, sleepType, sexualActivityType]
    
    return readDataTypes
  }
  
  // MARK: reading healthkit data
  private func updateUserAge() -> Void {
    var dateOfBirth: Date! = nil
    do {
      dateOfBirth = try self.healthStore?.dateOfBirth()
    } catch {
      print ("Either an error occurred or there isn't any age information available")
      return
    }
    
    let now = Date()
    let ageComponents: DateComponents = Calendar.current.dateComponents([.year], from: dateOfBirth, to: now)
    let userAge: Int = ageComponents.year!
    let ageValue: String = NumberFormatter.localizedString(from: userAge as NSNumber, number: NumberFormatter.Style.none)
    if var userProfiles = self.userProfiles {
      var age: [String] = userProfiles[ProfileKeys.Age] as [String]!
      age[kProfileDetail] = ageValue
      userProfiles[ProfileKeys.Age] = age
      self.userProfiles = userProfiles
    }
  }
  
  /*private func updateUserGender() -> Void {
    /*var userGender: String? {
      if let biologicalSex = healthStore?.biologicalSex() {
        switch biologicalSex.biologicalSex {
        case .female:
          return "Female"
        case .male:
          return "Male"
        case .other:
          return "Other"
        case .notSet:
          return "Not Set"
        }
      }*/
    var userGender: String? = nil
    do {
      if let biologicalSex = try healthStore?.biologicalSex() {
        switch biologicalSex.biologicalSex {
        case .female:
          userGender = "Female"
          appDelegate.databaseRef = Database.database().reference()
        case .male:
          userGender = "Male"
        case .other:
          userGender = "Other"
        case .notSet:
          userGender = "Not Set"
        }
      }
    } catch let error {
      print("Either an error occurred or there isn't any gender information available")
      return
    }
    
    if var userProfiles = self.userProfiles {
      var gender: [String] = userProfiles[ProfileKeys.Gender] as [String]!
      userProfiles[ProfileKeys.Gender] = gender
      self.userProfiles = userProfiles
    }
  }*/
  
  private func updateUserSteps() -> Void {
    
  }
  
  private func updateUserSleep() -> Void {
    
  }
  
  private func updateUserSexualActivity() -> Void {
    
  }
}
