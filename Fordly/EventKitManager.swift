//
//  EventKitManager.swift
//  Fordly
//
//  Created by Samantha Emily-Rachel Belnavis on 2017-09-26.
//  Copyright © 2017 Samantha Emily-Rachel Belnavis. All rights reserved.
//

import Foundation
import UIKit
import EventKit
import Firebase

class EventKitManager {
  // make instance accessible from all files
  class var sharedInstance: EventKitManager {
    struct Singleton {
      static let instance = EventKitManager()
    }
     return Singleton.instance
  }
  
  // create EventStore instance
  let eventStore = EKEventStore()
  
  // use event store to create new calendar instance
  
  // prevent
}
