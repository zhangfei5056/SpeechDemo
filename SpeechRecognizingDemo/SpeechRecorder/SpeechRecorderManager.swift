//
//  SpeechRecorderManager.swift
//  SpeechRecognizingDemo
//
//  Created by Yuan Cao on 2024/2/5.
//

import UIKit
import AVFoundation

/**
 This class is a speech recorder manager, which can implement the following functions:
 - Initialize a speech recorder, specify a file path and a callback function to update text
 - Through the textView parameter, you can display the speech recognition result in a text view
 - Call the start method to start recording and recognizing speech, provided that the user has authorized the recording permission
 - Call the stop method to stop recording and recognizing speech, and save the recording file to the specified path
 - Call the pause method to pause recording and recognizing speech, but not save the recording file
 - Call the resume method to resume recording and recognizing speech, and continue the previous recording file
 - Call the play method to play the recording file
 */
public class SpeechRecorderManager {

    private let textView: UITextView?

    lazy var recorder: SpeechRecorderProtocol = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let recordFile = paths[0].appendingPathComponent("recording.wav")
        let recorder = SpeechRecorder(recordFile: recordFile)
        recorder.getRecordedText = { [weak self] text in
            guard let self = self else { return }
            self.textView?.text = text
        }
        return recorder
    }()

    public init(textView: UITextView? = nil) {
        self.textView = textView
    }

    public func start() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                if !self.recorder.isRecording && !recorder.isPlaying {
                    DispatchQueue.main.async {
                        self.textView?.text = "Recording started"
                    }
                    self.recorder.startRecordingAudio()
                    self.recorder.startRecognizingSpeech()
                }
            } else {
                LocalNotificationHelper.shared.showMessage(title: "No recording permission", body: "Please allow sound recording")
            }
        }
    }

    public func stop() {
        if recorder.isRecording {
            recorder.stopRecodingAudio()
            recorder.stopRecognizingSpeech()
        }
    }

    public func pause() {
        if recorder.isRecording {
            self.textView?.text = "Recording paused"
            recorder.pauseRecodingAudio()
            recorder.pauseRecognizingSpeech()
        }
    }

    public func resume() {
        if !recorder.isRecording && !recorder.isPlaying {
            self.textView?.text = "Recording resumed"
            recorder.resumeRecordingAudio()
            recorder.resumeRecognizingSpeech()
        }
    }

    public func play(){
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                if !self.recorder.isRecording {
                    self.recorder.playAudioRecording()
                }
            } else {
                LocalNotificationHelper.shared.showMessage(title: "No playing permission", body: "Please allow sound recording")
            }
        }
    }
}
