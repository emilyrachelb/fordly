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
  var userHeight: Double!
  var userWeight: Double!
  var userBMI: Double!
  var userSteps: Int!
  var userSleep: HKCategoryType?
  var userSexualActvity: HKCategoryType?
  var userGender: String!
  var userAge: Int!
  
  // create firebase references
  var databaseReference: DatabaseReference!
  
  // MARK: Properties
  @IBOutlet weak var userEmail: UILabel!
  @IBOutlet weak var userName: UILabel!
  @IBOutlet weak var userPhoto: UIImageView!
  @IBOutlet weak var userAgeLabel: UILabel!
  @IBOutlet weak var userDOBLabel: UILabel!
  @IBOutlet weak var userGenderIcon: UIImageView!
  
  // HealthKit Labels
  
  @IBAction func goToMain(segue:UIStoryboardSegue){
  }
  
  override func viewDidLoad() { super.viewDidLoad() }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // create database reference
    databaseReference = Database.database().reference()
    
   HealthKitManager.sharedInstance.requestHealthKitAuthorization(dataTypesToWrite: nil, dataTypesToRead: dataTypesToRead)
    
    if (GIDSignIn.sharedInstance().hasAuthInKeychain()) {
      // get user id from current user
      googleUserId = appDelegate.gUserId
      googleUserName = appDelegate.gUserName
      googleUserEmail = appDelegate.gUserEmail
      googleUserPhoto = appDelegate.gUserPhoto
      userGender = appDelegate.gUserGender
      
      // assign values to labels that are passed to ViewController
      userName.text = googleUserName
      userEmail.text = googleUserEmail
      
      // create/check for userPhotos storage directory
      
      // setup UIImageView for the user's photo
      userPhoto.contentMode = .scaleAspectFit
      userPhoto.layer.borderWidth = 1
      userPhoto.layer.masksToBounds = false
      userPhoto.layer.borderColor = UIColor.black.cgColor
      userPhoto.layer.cornerRadius = userPhoto.frame.height/2
      userPhoto.clipsToBounds = true
      
      // variables for user photo storage
      let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
      let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
      let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
      let dirPath = paths.first
      let imageUrl = URL(fileURLWithPath: dirPath!).appendingPathComponent("\(String(describing: googleUserId)).png")
      
      
      // check internet connection
      if (appDelegate.internetConnected == true) {
        // device is connected to the internet; download, save and set user photo
        if (try? downloadUserImage(url: googleUserPhoto)) != nil {
          userPhoto.image = UIImage(contentsOfFile: imageUrl.path)
        } else {
          // if the file couldn't be downloaded, check for existing photo
          if FileManager.default.fileExists(atPath: dirPath!) {
            // photo exists
            userPhoto.image = UIImage(contentsOfFile: imageUrl.path)
          } else {
            // no existing photo
            userPhoto.image = UIImage(named: "noUserImage")
          }
        }
      } else {
        // the device cannot reach the internet; check for existing photo
        if FileManager.default.fileExists(atPath: dirPath!) {
          // photo exists
          userPhoto.image = UIImage(contentsOfFile: imageUrl.path)
        } else {
          // no existing photo
          userPhoto.image = UIImage(named: "noUserImage")
        }
      }
      
      /*if (try? downloadUserImage(url: googleUserPhoto)) != nil {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first {
          let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent("\(googleUserId).png")
          userPhoto.image = UIImage(contentsOfFile: imageUrl.path)
        }
      } else {
        userPhoto.image = UIImage(named: "noUserImage")
      }*/
      
      // get the user's gender from HealthKit
      let userAgeAndGender = try? updateUserProfile()
      userGender = userAgeAndGender?.biologicalSex.stringRepresentation
      userAge = userAgeAndGender?.age
      print("Gender: \(userGender)")
      print("Age: \(userAge)")
      
      // set user's date of birth and age
      userDOBLabel.text = userAgeAndGender?.birthDate
      userAgeLabel.text = "(\(String(describing: userAgeAndGender!.age)))"
      
      // save values to firebase
      databaseReference.child("user_profiles").child(googleUserId!).child("age").setValue(userAge)
      databaseReference.child("user_profiles").child(googleUserId!).child("birthday").setValue(HealthKitManager.sharedInstance.dateOfBirth)
      
      // set the user's gender icon
      if (userGender == "female") {
        userGenderIcon.image = UIImage(named: "genderIcon-female")
        databaseReference.child("user_profiles").child(googleUserId!).child("gender").setValue(userGender)
      } else if (userGender == "male") {
        userGenderIcon.image = UIImage(named: "genderIcon-male")
        databaseReference.child("user_profiles").child(googleUserId!).child("gender").setValue(userGender)
      } else if (userGender == "other") {
        userGenderIcon.image = UIImage(named: "genderIcon-other")
        databaseReference.child("user_profiles").child(googleUserId!).child("gender").setValue(userGender)
      } else if (userGender == "not set") {
        userGenderIcon.image = UIImage(named: "genderIcon-notSet")
        databaseReference.child("user_profiles").child(googleUserId!).child("gender").setValue(userGender)
      }
      
      // fetch most recent weight data
      guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
        print("Either the height sample doesn't exist, the sample type is no longer available, or there's an error somewhere in the retrieval function")
        return
      }
      
      HealthKitManager.getMostRecentSample(for: weightSampleType, completion: { (sample, error) in
        guard let sample = sample else {
          if let error = error {
            print("Weight sample retrieval error; There's an error in the retrieval function")
          }
          return
        }
        // convert weight sample to kilos
        let weightInKilos = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
        self.userWeight = weightInKilos
        print("Weight: \(self.userWeight) Kg")
      })
      
      // fetch most recent height data
      guard let heightSampleType = HKSampleType.quantityType(forIdentifier: .height) else {
        print("Either the weight sample doesn't exist, the sample type is no longer available, or there's an error somewhere in the retrieval function")
        return
      }
      HealthKitManager.getMostRecentSample(for: heightSampleType, completion: { (sample, error) in
        guard let sample = sample else {
          if let error = error {
            print("Height sample retrieval error; There's an error with the retrieval function")
          }
          return
        }
        // convert height sample into meters
        let heightInMeters = sample.quantity.doubleValue(for: HKUnit.meter())
        self.userHeight = heightInMeters
        print("Height: \(self.userHeight) m")
      })
      
      // fetch BMI data
      guard let bodyMassIndexSampleType = HKSampleType.quantityType(forIdentifier: .bodyMassIndex) else {
        print("Either the weight sample doesn't exist, the sample type is no longer available, or there's an error somewhere in the retrieval function")
        return
      }
      HealthKitManager.getMostRecentSample(for: bodyMassIndexSampleType, completion: { (sample, error) in
        guard let sample = sample else {
          if let error = error {
            print("BMI retrieval error; There's an error with the retrieval function")
          }
          return
        }
        let bmiSample = sample.quantity.doubleValue(for: HKUnit.count())
        self.userBMI = bmiSample
        print("BMI: \(self.userBMI)")
      })
      
      // fetch step data
      guard let stepCountSampleType = HKSampleType.quantityType(forIdentifier: .stepCount) else {
        print("Either the height sample doesn't exist, the sample type is no longer available, or there's an error somewhere in the retrieval function")
        return
      }
      HealthKitManager.getMostRecentSample(for: stepCountSampleType, completion: { (sample, error) in
        guard let sample = sample else {
          if let error = error {
            print ("Step count retrival error; There's an error with the retrieval function")
          }
          return
        }
        let stepCountSample = sample.quantity.doubleValue(for: HKUnit.count())
        self.userSteps = Int(stepCountSample)
        print("Step Count: \(self.userSteps)")
      })
      
      // Debug Information
      print("User already signed in")
      print("User ID: \(String(describing: googleUserId))")
      print("User's Name: \(String(describing: googleUserName))")
      print("User's Email: \(String(describing: googleUserEmail))")
      print("User's Gender: \(String(describing: userGender))")
      print("User Photo URL: \(String(describing: googleUserPhoto))")
    } else {
      print("User not signed in")
      self.performSegue(withIdentifier: "goToLogin", sender: nil)
    }
    
  }

  // update the user profile
  func updateUserProfile() throws -> (age: Int, biologicalSex: HKBiologicalSex, birthDate: String){
      
    // database reference
    databaseReference = Database.database().reference()
    let healthKitStore = HKHealthStore()
    do {
      let dateFormatter = DateFormatter()
      dateFormatter.locale = Locale(identifier: "en_US")
      dateFormatter.setLocalizedDateFormatFromTemplate("MMMd")
      
      let birthdayComponents = try healthKitStore.dateOfBirthComponents()
      let biologicalSex = try healthKitStore.biologicalSex()
      
      let today = Date()
      let calendar = Calendar.current
      let currentDateComponents = calendar.dateComponents([.year], from: today)
      
      let thisYear = currentDateComponents.year!
      let age = thisYear - birthdayComponents.year!
      let dateToDisplay = calendar.date(from: birthdayComponents)!
      let birthDate = dateFormatter.string(from: dateToDisplay)
      
      let unwrappedBiologicalSex = biologicalSex.biologicalSex
      
      return (age, unwrappedBiologicalSex, birthDate)
    }
  }
  
  func getDocumentDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
  }
  
  // get image from source asynchronously
  func getImageFromUrl(url: URL, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
    URLSession.shared.dataTask(with: url) {
      (data, response, error) in
      completion(data, response, error)
      }.resume()
  }
  
  // image download function
  func downloadUserImage(url: URL) {
    print("Download Started")
    getImageFromUrl(url: url) { (data, response, error) in
      guard let data = data, error == nil else { return }
      print("Download Finished")
      DispatchQueue.main.async { () -> Void in
        self.userPhoto.image = UIImage(data: data)
        
        // save to file
        let documentsDirectoryUrl = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        // create filename for the image
        let fileUrl = documentsDirectoryUrl.appendingPathComponent("\(String(describing: self.googleUserId)).png")
        
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
          do {
            try UIImagePNGRepresentation(self.userPhoto.image!)!.write(to: fileUrl)
            print("Image was saved")
          } catch {
            print(error)
          }
        } else {
          print("Image was not saved")
        }
      }
    }
  }
  
}
