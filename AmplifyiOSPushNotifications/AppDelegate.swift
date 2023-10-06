//
//  AppDelegate.swift
//  AmplifyiOSPushNotifications
//
//  Created by David Perez Espino on 04/10/23.
//

import UIKit
import Amplify
import AWSCognitoAuthPlugin
import AWSPinpointPushNotificationsPlugin

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self

        requestPushNotificationPermission()
        
        return true
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            do {
                try await Amplify.Notifications.Push.registerDevice(apnsToken: deviceToken)
                
                let tokenParts = deviceToken.map { data -> String in String(format: "%02.2hhx", data) }
                let token = tokenParts.joined()
                print("Registered with Pinpoint.\nToken: \(token)")
            } catch {
                print("Error registering with Pinpoint: \(error)")
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {
        
        do {
            try await Amplify.Notifications.Push.recordNotificationReceived(userInfo)
        } catch {
            print("Error recording receipt of notification: \(error)")
        }
        
        // TODO: any other process
        
        return .newData
    }
    
    
    func requestPushNotificationPermission() {
        Task {
            let options: UNAuthorizationOptions = [.badge, .alert, .sound]
            
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: options) { granted, error in
                
                if let error = error {
                    print("Permission not granted")
                }
                
                print("Permission granted, thanks!!")
                self.initializeAmplify()
            }
        }
    }
    
    func initializeAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSPinpointPushNotificationsPlugin(options: [.badge, .alert, .sound]))
            try Amplify.configure()
            print("Initialized Amplify");
        } catch {
            print("Could not initialize Amplify: \(error)")
        }
    }
    
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
        // Called when a user opens (taps or clicks) a notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        do {
            try await Amplify.Notifications.Push.recordNotificationOpened(response)
        } catch {
            print("Error recording notification opened: \(error)")
        }
    }
}
