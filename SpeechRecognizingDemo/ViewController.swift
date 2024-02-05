//
//  ViewController.swift
//  SpeechRecognizingDemo
//
//  Created by Yuan Cao on 2024/2/5.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController {

    lazy var recorderManager = SpeechRecorderManager(textView: self.textView)
    @IBOutlet weak var textView: UITextView!

    // MARK: button action
    @IBAction func recordAction(_ sender: Any) {
        recorderManager.start()
    }

    @IBAction func stopAction(_ sender: Any) {
        recorderManager.stop()
    }

    @IBAction func playAction(_ sender: Any) {
        recorderManager.play()
    }

    @IBAction func pauseAction(_ sender: Any) {
        recorderManager.pause()
    }

    @IBAction func resumeAction(_ sender: Any) {
        recorderManager.resume()
    }

    // ViewController life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        registerInterruption()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
    }
}


// MARK: private methods
extension ViewController {
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        switch interruptionType {
        case .began:
            recorderManager.pause()
        case .ended:
            LocalNotificationHelper.shared.showMessage(title: "Recording interrupted", body: "It has now been restored.")
            recorderManager.resume()
        @unknown default:
            break
        }
    }

    private func registerInterruption() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
}
