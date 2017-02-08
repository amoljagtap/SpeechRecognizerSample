//
//  ViewController.swift
//  SpeechRecognizerProject
//
//  Created by Jagtap, Amol on 2/8/17.
//  Copyright © 2017 Amol Jagtap. All rights reserved.
//

import UIKit
import Speech
import AVKit

class ViewController: UIViewController {
    
    var speechRecognizer:SFSpeechRecognizer!
    var recognitionTask:SFSpeechRecognitionTask!
    
    var audioEngine:AVAudioEngine = AVAudioEngine()
    
//    var requst:SFSpeechRecognitionRequest! //for pre-recorded file
    var requst:SFSpeechAudioBufferRecognitionRequest! //live audio

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var record: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        record.isEnabled = false
    
        //Request for speech recognization access
        SFSpeechRecognizer.requestAuthorization { (status:SFSpeechRecognizerAuthorizationStatus) in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.record.isEnabled = true
                    self.createSpeechRecognizer()
                    break
                case .denied:
                    self.record.isEnabled = false
                    self.record.setTitle("Recording status denied", for: .normal)
                    break
                case .notDetermined:
                    self.record.isEnabled = false
                    self.record.setTitle("Recording status unknown", for: .normal)
                    break
                case .restricted:
                    self.record.isEnabled = false
                    self.record.setTitle("Recording status restricted", for: .normal)
                    break
                }
            }
        }
    }
    
    
    func createSpeechRecognizer(){
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_IN"))
        speechRecognizer.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttonClicked(_ sender: Any) {
        guard let _ = speechRecognizer else { fatalError("Recognizer not available") }
        if audioEngine.isRunning {
            record.setTitle("Start Recording", for: .disabled)
            record.isEnabled = false
            audioEngine.stop()
            requst.endAudio()
        }else{
            startRecording()
            record.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func startRecording(){
        if let task = recognitionTask {
            //cancel running task
            task.cancel()
        }
        
        do {
            
            //get audio seesion
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
            
            //initialized recognition buffer
            requst = SFSpeechAudioBufferRecognitionRequest()
            requst.shouldReportPartialResults = true
            
            
            guard let inputNode = audioEngine.inputNode else {
                fatalError("Audio engine has no input node")
            }
            
            guard let requst = requst else {
                fatalError("unable to create SFSpeechAudioBufferRecognitionRequest object")
            }
            
            //start recognization
            speechRecognizer.recognitionTask(with: requst) { (result, error) in
                var isFinal = false
                //get result text from SFSpeechRecognitionResult
                if let result = result {
                    self.textView.text = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }
                //stop audio engine
                if error != nil || isFinal {
                    self.requst.endAudio()
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    
                    self.requst = nil
                    self.recognitionTask = nil
                    
                    self.record.isEnabled = true
                    self.record.setTitle("Start Recording", for: .normal)
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer:AVAudioPCMBuffer, time:AVAudioTime) in
                self.requst.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            textView.text = "I am listening"
            record.setTitle("Recordning Started", for: .normal)
            
        }catch let error {
            print(error)
            textView.text = error.localizedDescription
        }
    }

}

extension ViewController: SFSpeechRecognizerDelegate {
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
        if available {
            record.isEnabled = true
            record.setTitle("Start Recording", for: .normal)
        }else{
            record.isEnabled = false
            record.setTitle("Recording not available", for: .normal)
        }
        
    }

}

