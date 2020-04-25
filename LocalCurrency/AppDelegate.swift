//
//  AppDelegate.swift
//  LocalCurrency
//
//  Created by a1111 on 2020/04/19.
//  Copyright © 2020 SIMPARK. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {


//    func compactRealm() {
//        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
//        let defaultParentURL = defaultURL.deletingLastPathComponent()
//        let compactedURL = defaultParentURL.appendingPathComponent("default-compact")
//
//        autoreleasepool {
//            let realm = try! Realm()
//            try! realm.writeCopy(toFile: compactedURL)
//        }
//        try! FileManager.default.removeItem(at: defaultURL)
//        try! FileManager.default.moveItem(at: compactedURL, to: defaultURL)
//    }
    func compactRealm() {
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
        let defaultParentURL = defaultURL.deletingLastPathComponent()
        let compactedURL = defaultParentURL.appendingPathComponent("default-compact.realm")

        if FileManager.default.fileExists(atPath: compactedURL.path) {
            try! FileManager.default.removeItem(at: compactedURL)
        }

        if FileManager.default.fileExists(atPath: defaultURL.path) {
            autoreleasepool {
                let realm = try! Realm()
                try! realm.writeCopy(toFile: compactedURL)
            }

            try! FileManager.default.removeItem(at: defaultURL)
            try! FileManager.default.moveItem(at: compactedURL, to: defaultURL)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        compactRealm()
        //openRealm() //2
        //compactRealmSize()
        
        // Override point for customization after application launch.
        return true
    }
    
//    func compactSize(){
//        let config = Realm.Configuration(shouldCompactOnLaunch: { totalBytes, usedBytes in
//          // totalBytes refers to the size of the file on disk in bytes (data + free space)
//          // usedBytes refers to the number of bytes used by data in the file
//
//          // Compact if the file is over 100MB in size and less than 50% 'used'
//          let oneHundredMB = 100 * 1024 * 1024
//          return (totalBytes > oneHundredMB) && (Double(usedBytes) / Double(totalBytes)) < 0.5
//        })
//        do {
//          // Realm is compacted on the first open if the configuration block conditions were met.
//          let realm = try Realm(configuration: config)
//        } catch {
//          // handle error compacting or opening Realm
//        }
//        
//        
//    }
    
    func openRealm() {
        let bundlePath = Bundle.main.path(forResource: "default", ofType: "realm")!
        let defaultPath = Realm.Configuration.defaultConfiguration.fileURL!.path
        let fileManager = FileManager.default

        // Only need to copy the prepopulated `.realm` file if it doesn't exist yet
        if !fileManager.fileExists(atPath: defaultPath){
            print("use pre-populated database")
            do {
                try fileManager.copyItem(atPath: bundlePath, toPath: defaultPath)
                print("Copied")
            } catch {
                print(error)
            }
        }

    }
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

