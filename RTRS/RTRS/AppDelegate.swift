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

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        LoadingManager.shared.executeStartup()
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notification.Name.WillEnterForeground, object: nil)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("**** FCM TOKEN: \(fcmToken)")
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

