//
//  SpeechRecorder.swift
//  SpeechRecognizingDemo
//
//  Created by Yuan Cao on 2024/2/5.
//

import Foundation
import AVFoundation
import Speech
import UIKit

// MARK: For audio recording control
protocol AudioControlProtocol {
    func startRecordingAudio()
    func stopRecodingAudio()
    func pauseRecodingAudio()
    func resumeRecordingAudio()
    func playAudioRecording()
}

// MARK: For speech recognizing control
protocol SpeechRecognizingControlProtocol {
    func startRecognizingSpeech()
    func stopRecognizingSpeech()
    func pauseRecognizingSpeech()
    func resumeRecognizingSpeech()
}

protocol SpeechRecorderProtocol: SpeechRecognizingControlProtocol, AudioControlProtocol {
    var isRecording: Bool { get }
    var isPlaying: Bool { get }
}

/**
 An internal class to deal with audio recording and speech recognizing, usually do not need to touch this class, use `SpeechRecorderManager`
 */
internal class SpeechRecorder: NSObject, SpeechRecorderProtocol {

    var isRecording: Bool = false
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    var getRecordedText: ((_ text: String) -> Void)?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()

    // If encounter an interruption, the previous one is saved here
    private var backupRecordedText: String = ""
    // This is where the results of each speech recognization was stored
    private var currentRecordedText: String = ""

    private let recordFile: URL

    init(recordFile: URL) {
        self.recordFile = recordFile
        super.init()
        requestSpeechAuthorization()
    }
}

extension SpeechRecorder: SFSpeechRecognitionTaskDelegate {

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        let hypothesizedText = transcription.formattedString
        if currentRecordedText != hypothesizedText {
            currentRecordedText = hypothesizedText
            getRecordedText?(hypothesizedText)
        }
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        let finalText = recognitionResult.bestTranscription.formattedString
        if !finalText.isEmpty {
            self.backupRecordedText += finalText
            getRecordedText?(self.backupRecordedText)
        }
    }

    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        getRecordedText?(self.backupRecordedText + self.currentRecordedText)
    }

    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        self.backupRecordedText += currentRecordedText
    }
}


// MARK: audio recorder control methods
extension SpeechRecorder: AudioControlProtocol {

    func startRecordingAudio() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            audioRecorder = try setupAudioRecorder()
            audioRecorder?.record()
        } catch {
            print(error)
        }
        isRecording = true
    }

    func stopRecodingAudio() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
    }

    func pauseRecodingAudio() {
        audioRecorder?.pause()
        isRecording = false
    }

    func resumeRecordingAudio() {
        audioRecorder?.record()
        isRecording = true
    }

    func playAudioRecording() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            audioPlayer = try AVAudioPlayer(contentsOf: recordFile)
            audioPlayer?.play()
        } catch {
            print("Error playing recording: \(error)")
        }
    }
}

// MARK: speech recognizing control methods
extension SpeechRecorder: SpeechRecognizingControlProtocol {

    func startRecognizingSpeech() {
        guard let recognizer = speechRecognizer else {
            return
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!, delegate: self)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print(error)
        }
        isRecording = true
    }

    func stopRecognizingSpeech() {
        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
    
    func pauseRecognizingSpeech() {
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
    }
    
    func resumeRecognizingSpeech() {
        startRecognizingSpeech()
        isRecording = true
    }
}

// MARK: private methods
extension SpeechRecorder {

    private func setupAudioRecorder() throws -> AVAudioRecorder {

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        return try AVAudioRecorder(url: recordFile, settings: settings)
    }

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus == .authorized {
                print("Speech recognition authorized")
            }
        }
    }
}
