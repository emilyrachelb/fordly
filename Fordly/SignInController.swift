//
//  SignInController.swift
//  Fordly
//
//  Created by Samantha Emily-Rachel Belnavis on 2017-09-18.
//  Copyright © 2017 Samantha Emily-Rachel Belnavis. All rights reserved.
//

// import required frameworks
import UIKit
import Firebase
import GoogleSignIn

// start SignInController class
class SignInController: UIViewController, GIDSignInUIDelegate {
  
  // MARK: Properties
  @IBOutlet weak var signInMessage: UILabel!
  @IBOutlet weak var appVersionLabel: UILabel!
  @IBOutlet weak var googleSignInButton: GIDSignInButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Google sign in stuff
    GIDSignIn.sharedInstance().uiDelegate = self
    GIDSignIn.sharedInstance().signInSilently() // check if the user is already signed in
    
    // Get app name, version and build numbers from Info.plist
    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString" as String] as! String
    
    signInMessage.text = "Welcome to\n\(appName)"
    appVersionLabel.text = "Version \(appVersion)"
    
    // Configure Google sign in button
    googleSignInButton.style = GIDSignInButtonStyle.wide
  }
  
  override func viewDidAppear(_ animated: Bool) {
    if (GIDSignIn.sharedInstance().hasAuthInKeychain()) {
      print("User already signed in")
      self.performSegue(withIdentifier: "goToMain", sender: nil)
    } else {
      print("User not signed in")
      // forward after signing in
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}
