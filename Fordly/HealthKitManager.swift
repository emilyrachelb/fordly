//
//  HealthKitManager.swift
//  Fordly
//
//  Created by Samantha Emily-Rachel Belnavis on 2017-09-25.
//  Copyright © 2017 Samantha Emily-Rachel Belnavis. All rights reserved.
//

import HealthKit

class HealthKitManager {
  class var sharedInstance: HealthKitManager {
    struct Singleton {
      static let instance = HealthKitManager()
    }
    return Singleton.instance
  }
  
  var healthStore: HKHealthStore? = {
    if HKHealthStore.isHealthDataAvailable() {
      return HKHealthStore()
    } else {
      return nil
    }
  }()
  
  // HealthKit data types that we want to read from / write to
  let dateOfBirthCharacteristic = HKCharacteristicType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)
  let biologicalSexCharacteristic = HKCharacteristicType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)
  let usersHeight = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)
  let usersWeight = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
  let usersStepCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
  let usersSexualActivity = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sexualActivity)
  let usersSleepActivity = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)
  let activitySummaryType = HKActivitySummaryType.activitySummaryType() 
  
  var dateOfBirth: String? {
    if let dateOfBirth = try? healthStore?.dateOfBirthComponents() {
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .long
      let preferredDateFormat = Calendar.current.date(from: dateOfBirth!)!
      let birthday = dateFormatter.string(from: preferredDateFormat)
      return birthday
    }
    return nil
  }
  
  var biologicalSex: String? {
    if let biologicalSex = try? healthStore?.biologicalSex() {
      switch biologicalSex!.biologicalSex {
      case .female:
        return "Female"
      case .male:
        return "Male"
      case .other:
        return "Other"
      case .notSet:
        return "Not Set"
      }
    }
    return nil
  }
  
  var healthKitAuthorized: Bool? {
    return nil
  }
  
  func requestHealthKitAuthorization(dataTypesToWrite: NSSet?, dataTypesToRead: NSSet?) {
    healthStore?.requestAuthorization(toShare: dataTypesToWrite as? Set<HKSampleType>, read: dataTypesToRead as? Set<HKObjectType>, completion: {(success, error) -> Void in
      if success {
        print ("Successfully authorized HealthKit")
        let healthKitAuthorized = true
      } else {
        print (error?.localizedDescription)
      }
    })
  }
  
  class func getMostRecentSample(for sampleType: HKSampleType, completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
    // use hkquery to load the most recent samples
    let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
    
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    
    let limit = 1
    
    let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
      DispatchQueue.main.async {
        guard let samples = samples, let mostRecentSample = samples.first as? HKQuantitySample else {
          completion(nil, error)
          return
        }
        completion(mostRecentSample, nil)
      }
    }
    HKHealthStore().execute(sampleQuery)
  }
  
}

