//
//  ViewController.swift
//  RecordPlay
//
//  Created by Sina Rabiei on 5/20/21.
//

import UIKit
import AVKit
import MediaPlayer

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet var recordingTimeLabel: UILabel!
    @IBOutlet var recordBtn: UIButton!
    @IBOutlet var playBtn: UIButton!
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer : AVAudioPlayer!
    var audioSession = AVAudioSession.sharedInstance()
    var meterTimer:Timer!
    var isAudioRecordingGranted: Bool!
    var isRecording = false
    var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkRecordPermission()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
        } catch {
            print("Can't Set Audio Session Category: \(error)")
        }
        do {
            try audioSession.setMode(AVAudioSession.Mode.videoRecording)
        } catch {
            print("Can't Set Audio Session Mode: \(error)")
        }
        do {
            try audioSession.setActive(true)
        } catch {
            print("Can't Start Audio Session: \(error)")
        }
    }
    
    func checkRecordPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            isAudioRecordingGranted = true
            break
        case AVAudioSession.RecordPermission.denied:
            isAudioRecordingGranted = false
            break
        case AVAudioSession.RecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (allowed) in
                if allowed {
                    self.isAudioRecordingGranted = true
                } else {
                    self.isAudioRecordingGranted = false
                }
            })
            break
        default:
            break
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getFileUrl() -> URL {
        let filename = "myRecording.m4a"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
        return filePath
    }
    
    func getFileUrlForLocalMusic() -> URL {
        let filename = "music"
        let filePath = Bundle.main.url(forResource: filename, withExtension: "mp3")!
        return filePath
    }
    
    func setupRecorder() {
        if isAudioRecordingGranted {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(AVAudioSession.Category.playAndRecord, options: [.allowBluetoothA2DP, .allowBluetooth])
                try session.setActive(true)
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
                ]
                audioRecorder = try AVAudioRecorder(url: getFileUrl(), settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                audioRecorder.prepareToRecord()
                audioRecorder.record()
                playSound()
                meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
                recordBtn.setTitle("Stop", for: .normal)
                isRecording = true
            } catch let error {
                displayAlert(msgTitle: "Error", msgDesc: error.localizedDescription, actionTitle: "OK")
            }
        } else {
            displayAlert(msgTitle: "Error", msgDesc: "Don't have access to use your microphone.", actionTitle: "OK")
        }
    }
    
    @IBAction func startRecording(_ sender: UIButton) {
        if (isRecording) {
            finishAudioRecording(success: true)
            recordBtn.setTitle("Record", for: .normal)
            isRecording = false
            audioPlayer.stop()
        } else {
            setupRecorder()
        }
    }
    
    @objc func updateAudioMeter(timer: Timer) {
        if audioRecorder.isRecording {
            let hr = Int((audioRecorder.currentTime / 60) / 60)
            let min = Int(audioRecorder.currentTime / 60)
            let sec = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
            let totalTimeString = String(format: "%02d:%02d:%02d", hr, min, sec)
            recordingTimeLabel.text = totalTimeString
            audioRecorder.updateMeters()
        }
    }
    
    func finishAudioRecording(success: Bool) {
        if success {
            audioRecorder.stop()
            audioRecorder = nil
            meterTimer.invalidate()
            print("recorded successfully.")
        } else {
            displayAlert(msgTitle: "Error", msgDesc: "Recording failed.", actionTitle: "OK")
        }
    }
    
    func preparePlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileUrl())
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
        } catch {
            print("Error")
        }
    }
    
    @IBAction func playRecorded(_ sender: Any) {
        if (isPlaying) {
            audioPlayer.stop()
            playBtn.setTitle("Play", for: .normal)
            isPlaying = false
        } else {
            if FileManager.default.fileExists(atPath: getFileUrl().path) {
                playBtn.setTitle("Pause", for: .normal)
                preparePlayer()
                audioPlayer.play()
                isPlaying = true
            } else {
                displayAlert(msgTitle: "Error", msgDesc: "Audio file is missing.", actionTitle: "OK")
            }
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishAudioRecording(success: false)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordBtn.isEnabled = true
    }
    
    func displayAlert(msgTitle: String, msgDesc: String, actionTitle: String) {
        let ac = UIAlertController(title: msgTitle, message: msgDesc, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: actionTitle, style: .default) {
            (result : UIAlertAction) -> Void in
            self.navigationController?.popViewController(animated: true)
        })
        present(ac, animated: true)
    }
}

extension ViewController {
    func playSound() {
        guard Bundle.main.url(forResource: "music", withExtension: "mp3") != nil else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileUrlForLocalMusic())
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } catch {
            displayAlert(msgTitle: "Error2", msgDesc: error.localizedDescription, actionTitle: "OK")
        }
    }
}
