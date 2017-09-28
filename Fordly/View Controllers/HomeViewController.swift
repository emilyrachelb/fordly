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
  var userSteps: Double!
  var userSleep: HKCategoryType?
  var lastSexualActivityWith: String!
  var lastSexualActivityDate: String!
  var timeSinceLastSexualActivity: String!
  var timeSinceLastSexualActivityAsNum: Int!
  var userGender: String!
  var userAge: Int!
  var caste = "Beta"
  
  // internet connectivity
  var couldConnect: Bool!
  
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
  
  //KDCircularProgress variable
  var stepCountProgress: KDCircularProgress!
  var stepCountAngle: Double = -90.0
  @IBOutlet weak var messageToUserAboutStepCount: UILabel!
  //@IBOutlet weak var stepCountLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    GIDSignIn.sharedInstance().uiDelegate = self
    GIDSignIn.sharedInstance().signInSilently()
    
    // step count activity ring
    stepCountProgress = KDCircularProgress(frame: CGRect(x: 16, y: 170, width: 150, height: 150))
    stepCountProgress.startAngle = -90
    stepCountProgress.progressThickness = 0.1
    stepCountProgress.trackThickness = 0.05
    stepCountProgress.clockwise = true
    stepCountProgress.roundedCorners = true
    stepCountProgress.trackColor = UIColor(rgb: 0xFF000A, a: 0.15)
    stepCountProgress.set(colors: UIColor(rgb: 0xE10014, a: 1), UIColor(rgb: 0xFF000A, a: 1))
    view.addSubview(stepCountProgress)
    
    let stepCountPVHorizontalConstraint = NSLayoutConstraint(item: stepCountProgress, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
    let stepCountPVVerticalConstraint = NSLayoutConstraint(item: stepCountProgress, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
    let stepCountPVWidthConstraint = NSLayoutConstraint(item: stepCountProgress, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 150)
    let stepCountPVHeightConstraint = NSLayoutConstraint(item: stepCountProgress, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 150)
    
    view.addConstraints([stepCountPVHorizontalConstraint, stepCountPVVerticalConstraint, stepCountPVWidthConstraint, stepCountPVHeightConstraint])
    
    
  }
  
  func checkInternet() {
    guard let status = Network.reachability?.status else { return }
    switch status {
    case .unreachable:
      print ("Internet Unreachable")
      return couldConnect = false
    case .wifi:
      print ("Internet Reachable")
      return couldConnect = true
    case .wwan:
      print ("Internet Reachable")
      return couldConnect = true
    }
  }
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // create database reference
    databaseReference = Database.database().reference()
    
    
    if (GIDSignIn.sharedInstance().hasAuthInKeychain()) {
      // get user id from current user
      googleUserId = appDelegate.gUserId
      print(googleUserId)
      googleUserName = appDelegate.gUserName
      print(googleUserName)
      googleUserEmail = appDelegate.gUserEmail
      print(googleUserEmail)
      googleUserPhoto = appDelegate.gUserPhoto
      print(googleUserPhoto)
      userGender = appDelegate.gUserGender
      // assign values to labels that are passed to ViewController
      userName.text = googleUserName
      userEmail.text = googleUserEmail
      
      
      // setup UIImageView for the user's photo
      userPhoto.contentMode = .scaleAspectFit
      userPhoto.layer.borderWidth = 1
      userPhoto.layer.masksToBounds = false
      userPhoto.layer.borderColor = UIColor(rgb: 0xFFFFFF, a: 0.0).cgColor
      userPhoto.layer.cornerRadius = userPhoto.frame.height/2
      userPhoto.clipsToBounds = true
      
      // variables for user photo storage
      let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
      let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
      let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
      let dirPath = paths.first
      let imageUrl = URL(fileURLWithPath: dirPath!).appendingPathComponent("\(String(describing: googleUserId)).png")
      
      
      // check internet connection
      delay(1.0){
        //self.checkInternet()
      }
      
      if (couldConnect == true) {
        // device is connected to the internet; download, save and set user photo
        if (try? downloadUserImage(url: googleUserPhoto)) != nil {
          userPhoto.image = UIImage(contentsOfFile: imageUrl.path)
        } else {
          // no existing photo
          userPhoto.image = UIImage(named: "noUserImage")
        }
      } else {
        // the device cannot reach the internet; check for existing photo
        print("Could not connect to the internet")
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
      databaseReference.child("user_profiles").child(googleUserId!).child("name").setValue(googleUserName)
      databaseReference.child("user_profiles").child(googleUserId!).child("email").setValue(googleUserEmail)
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
      
      // write example data
      //databaseReference.child("user_health_data").child(googleUserId!).child("sexual_activity").child(date).child("last_instance_date").setValue(date)
      //databaseReference.child("user_health_data").child(googleUserId!).child("sexual_activity").child(date).child("last_instance_with").setValue("******")
      
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
        self.userSteps = stepCountSample
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd-yyyy"
        let date = formatter.string(from: currentDate)
        formatter.dateFormat = "MMM-dd-yyyy"
        self.databaseReference.child("user_health_data").child(self.googleUserId!).child("step_count").child(date).child("steps").setValue(self.userSteps)
        if (((self.userSteps/10000)*100) >= 75) {
          self.stepCountAngle = 365
          self.messageToUserAboutStepCount.text = "You've been very active today. Remember, a healthy \(self.caste), is a happy \(self.caste)"
        } else {
          self.stepCountAngle = (self.userSteps / 10000) * 360
          self.messageToUserAboutStepCount.text = "You haven't been very active today. Remember, a healthy \(self.caste), is a happy \(self.caste)"
        }
        self.stepCountProgress.animate(fromAngle: 0, toAngle: self.stepCountAngle, duration: 1) { completed in
          if completed {
            print("animation stopped, completed")
          } else {
            print("animation stopped, was interrupted")
          }
        }
        print("Step Count: \(self.userSteps)")
      })
      
      // get most recent sexual activity
      //retrieveSexualActivity()
      
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
        
        do {
          try UIImagePNGRepresentation(self.userPhoto.image!)!.write(to: fileUrl)
          print("Image was saved")
        } catch {
          print(error)
        }
      }
    }
  }
  
  // func retrieve sexual activity
  func retrieveSexualActivity() {
    let currentDate = Date()
    let elapsedTime = DateComponentsFormatter()
    elapsedTime.unitsStyle = .full
    elapsedTime.allowedUnits = [.year, .month, .day, .hour]
    elapsedTime.maximumUnitCount = 1
    
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM-dd-yyyy-HH"
    
    let date = formatter.string(from: currentDate)
    
    
    let sexualActivityReference = Database.database().reference().child("user_health_data").child(self.googleUserId!).child("sexual_activity")
    
    sexualActivityReference.observeSingleEvent(of: .value, with: { snapshot in
      if !snapshot.exists() { return }
      let getData = snapshot.value as? [String:Any]
      if let lastDateFromRecord = getData!["last_instance_date"] as? String {
        self.lastSexualActivityDate = lastDateFromRecord as String!
        let timeSinceLastSexualActivityAsDate = formatter.date(from: lastDateFromRecord)
        self.lastSexualActivityDate = elapsedTime.string(from: timeSinceLastSexualActivityAsDate!, to: currentDate)
        print("time since last encounter: \(self.lastSexualActivityDate)")
      }
      
      if let lastInstanceWith = getData!["last_instance_with"] as? String {
        self.lastSexualActivityWith = lastInstanceWith as! String?
        print("it was with: \(self.lastSexualActivityWith)")
      }
    })
    
    // convert lastDate to a difference between 2 times
    
    /*self.databaseReference.queryOrdered(byChild: "user_health_data").observeSingleEvent(of: .childAdded, with: { snapshot in
      if let getData = snapshot.value as? [String:Any] {
        let lastDateFromRecord = getData["last_instance_date"] as! String
        let formattedTimeSinceLastSexualActivity = formatter.date(from: lastDateFromRecord)
        self.lastSexualActivityDate = Calendar.current.date(from: currentDateComponents)!.offsetFrom(date: formattedTimeSinceLastSexualActivity!)
        print (self.lastSexualActivityDate)
        self.lastSexualActivityWith = getData["last_instance_with"] as! String
      }
    })*/
  }
}



func delay(_ delay: Double, closure: @escaping ()->()) {
  DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

extension UIColor {
  convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
    assert(red >= 0 && red <= 255, "Invalid red component")
    assert(green >= 0 && green <= 255, "Invalid green component")
    assert(blue >= 0 && blue <= 255, "Invalid blue component")
    
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha:(a))
  }
  
  convenience init(rgb: Int, a: CGFloat = 1.0) {
    self.init(
      red: (rgb >> 16) & 0xFF,
      green: (rgb >> 8) & 0xFF,
      blue: rgb & 0xFF,
      a: a
    )
  }
}

extension Date {
  func offsetFrom(date: Date) -> String {
    let yearMonthDayHour: Set<Calendar.Component> = [.year, .month, .day, .hour]
    let difference = NSCalendar.current.dateComponents(yearMonthDayHour, from: date, to: self)
    
    let hours = "\(difference.hour ?? 0)"
    let days = "\(difference.day ?? 0) days"
    let months = "\(difference.month ?? 0)" + " " + days
    let years = "\(difference.year ?? 0)" + " " + months
    
    if let hour = difference.hour, hour > 0 {return hours}
    if let day = difference.day, day > 0 { return days}
    if let month = difference.month, month > 0 { return months}
    if let year = difference.year, year > 0 { return years }
    return ""
  }
}
