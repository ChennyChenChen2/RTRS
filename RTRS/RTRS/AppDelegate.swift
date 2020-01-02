//
//  AppDelegate.swift
//  RTRS
//
//  Created by Jonathan Chen on 4/14/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import AVFoundation
import UIKit
import WebKit
import Firebase
import MediaPlayer

extension Notification.Name {
    static let WillEnterForeground = Notification.Name("WillEnterForeground")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    let firstLaunchFinishedKey = "kRTRSFirstLaunchFinishedKey"

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        setRootViewController()
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notification.Name.WillEnterForeground, object: nil)
    }
    
    fileprivate func registerForPushNotifications(vc: UIViewController) {
        let firstLaunchFinished = UserDefaults.standard.bool(forKey: firstLaunchFinishedKey)
        if !firstLaunchFinished {
            UserDefaults.standard.set(true, forKey: firstLaunchFinishedKey)
            let alert = UIAlertController(title: "Welcome to the Ricky app!", message: "Please trust the processor as the app loads for the first time.\nWould you like to receive notifications for all Ricky-related updates, including new pods, articles, and events?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                if #available(iOS 10.0, *) {
                    // For iOS 10 display notification (sent via APNS)
                    UNUserNotificationCenter.current().delegate = self
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    let settings: UIUserNotificationSettings =
                    UIUserNotificationSettings(types: [.alert], categories: nil)
                    UIApplication.shared.registerUserNotificationSettings(settings)
                }
            }))
            
            DispatchQueue.main.async {
                vc.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("**** FCM TOKEN: \(fcmToken)")
    }
    
    fileprivate func setRootViewController() {
        self.window?.rootViewController?.view.removeFromSuperview()
        
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: LoadingViewController.storyboardId)
        let navController = RTRSNavigationController(rootViewController: vc)
        self.window?.rootViewController = navController
        
        registerForPushNotifications(vc: navController)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (success, error) in
            
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("HERE")
        completionHandler(.alert)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        print("HERE")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let link = response.notification.request.content.userInfo["deepLink"] as? String, let url = URL(string: link), let title = response.notification.request.content.userInfo["deepLinkTitle"] as? String, let rootVC = self.window?.rootViewController as? RTRSNavigationController {
            let payload = RTRSDeepLinkPayload(baseURL: url, title: title)
            RTRSDeepLinkHandler.route(payload: payload, navController: rootVC)
        }
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("HERE")
    }
}

