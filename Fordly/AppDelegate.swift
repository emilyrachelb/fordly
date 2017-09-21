//
//  AppDelegate.swift
//  Fordly
//
//  Created by Samantha Emily-Rachel Belnavis on 2017-09-18.
//  Copyright © 2017 Samantha Emily-Rachel Belnavis. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
  
  var window: UIWindow?
  var gUserId = String()
  var gUserName =  String()
  var gUserEmail = String()
  var gUserPhoto: URL!
  var gUserGender = String()
  var databaseRef: DatabaseReference!
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Initialize FirebaseApp
    FirebaseApp.configure()
    
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    GIDSignIn.sharedInstance().delegate = self
    
    return true
  }
  
  @available(iOS 9.0, *)
  func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
    return GIDSignIn.sharedInstance().handle(url, sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: [:])
  }
  
  // start signin_handler
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
    if error != nil {
      return
    }
    
    guard let authentication = user.authentication else { return }
    let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
    
    // retrieved from the user's google profile
    gUserId = user.userID
    gUserName = user.profile.name
    gUserEmail = user.profile.email
    gUserPhoto = user.profile.imageURL(withDimension: 100 * UInt(UIScreen.main.scale))
    
    // retrieve user's gender
    let gplusapi = "https://www.googleapis.com/oauth2/v3/userinfo?access_token=\(user.authentication.accessToken!)"
    let url = NSURL(string: gplusapi)!
    
    
    let request = NSMutableURLRequest(url: url as URL)
    request.httpMethod = "GET"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    
    let session = URLSession.shared
    
    
    session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
      UIApplication.shared.isNetworkActivityIndicatorVisible = false
      do {
        let userData = try JSONSerialization.jsonObject(with: data!, options:[]) as? [String:AnyObject]
        self.gUserGender = userData!["gender"] as! String
      } catch {
        NSLog("Account Information could not be loaded")
      }
      
    }).resume()
    
    self.databaseRef = Database.database().reference()
    self.databaseRef.child("user_profiles").child(user!.userID).observeSingleEvent(of: .value, with: { (snapshot) in
      
      let snapshot = snapshot.value as? NSDictionary
      
      if(snapshot == nil)
      {
        self.databaseRef.child("user_profiles").child(user!.userID).child("name").setValue(user?.profile.name)
        self.databaseRef.child("user_profiles").child(user!.userID).child("email").setValue(user?.profile.email)
        self.databaseRef.child("user_profiles").child(user!.userID).child("gender").setValue(self.gUserGender)
      }
    })
  
    Auth.auth().signIn(with: credential) { (user, error) in
      if error != nil {
        return
      }
    }
    return
    
  } // end signin_handler
  
  // start disconnect_handler
  func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    // Perform any operations when the user disconnects from the app here
    let firebaseAuth = Auth.auth()
    do {
      try firebaseAuth.signOut()
    } catch let signOutError as NSError {
      print("Error signing out: %@", signOutError)
    }
  } //end disconnect_handler
  
  // Core Data Stack
  @available(iOS 10.0, *)
  lazy var persistentContainer: NSPersistentContainer = {
    //Persistent container for the application.
    
    let container = NSPersistentContainer(name: "SomaDrop")
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()
  
  // Core Data Saving support
  func saveContext() {
    if #available(iOS 10.0, *) {
      let context = persistentContainer.viewContext
      
      if context.hasChanges {
        do {
          try context.save()
        } catch {
          let nserror = error as NSError
          fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
      }
    } else {
      
    }
  }
  
  static func shared() -> AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
}

