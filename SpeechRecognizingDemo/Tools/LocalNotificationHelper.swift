//
//  LocalNotificationHelper.swift
//  SpeechRecognizingDemo
//
//  Created by Yuan Cao on 2024/2/5.
//

import Foundation
import UserNotifications

class LocalNotificationHelper {
    
    static let shared = LocalNotificationHelper()

    func showMessage(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.badge = 0
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: String(describing: Self.self), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
}
