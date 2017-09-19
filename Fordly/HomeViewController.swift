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

// start MainViewController class
class HomeViewController: UIViewController, GIDSignInUIDelegate {
  
  let appDelegate = UIApplication.shared.delegate as! AppDelegate
  var googleUserId: String?
  var googleUserName: String?
  var googleUserEmail: String?
  var googleUserPhoto: URL!
  
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
    } else {
      print("User not signed in")
      self.performSegue(withIdentifier: "goToLogin", sender: nil)
    }
  }
}
