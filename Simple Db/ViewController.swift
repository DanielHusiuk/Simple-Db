//
//  ViewController.swift
//  Simple Db
//
//  Created by Daniel Husiuk on 06.06.2024.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate {
    
    @IBOutlet weak var ValueTextOutlet: UILabel!
    @IBOutlet weak var SoundsTextOutlet: UILabel!
    @IBOutlet weak var ProgressBarOutlet: ProgressBar!
    
    var audioRecorder: AVAudioRecorder!
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBarSettings()
        setupAudioSession()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    //MARK: - Audio Session
    
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            requestMicrophonePermission()
        } catch {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }
    }
    
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    self.startRecording()
                } else {
                    self.showPermissionAlert()
                }
            }
        }
    }
    
    func showPermissionAlert() {
        let alertController = UIAlertController(title: "Microphone Access Denied",
        message: "Please allow access to the microphone in Settings to measure volume level.",
        preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    //MARK: - Audio Recording
    
    func startRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        let url = URL(fileURLWithPath: "/dev/null")
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
            startMetering()
        } catch {
            print("Audio recording setup failed: \(error)")
        }
    }
    
    func startMetering() {
        timer = Timer.scheduledTimer(timeInterval: 0.8, target: self, selector: #selector(updateMeters), userInfo: nil, repeats: true)
    }
    
    
    //MARK: - dB Measuring
    
    @objc func updateMeters() {
        audioRecorder.updateMeters()
        let averagePower = audioRecorder.averagePower(forChannel: 0)
        let dbA = convertToDecibelsA(averagePower)
        ValueTextOutlet.text = String(format: "%.1f\ndB", dbA)
    }
    
    func convertToDecibelsA(_ averagePower: Float) -> Float {
        let referenceValue: Float = 20.0
        let minDecibels: Float = -80.0
        
        if averagePower < minDecibels {
            return 0.0
        }
        
        let power = pow(10.0, averagePower / 20.0)
        let dbA = 20.0 * log10(power * referenceValue) + 62.0
        
        switch dbA {
        case 0...40:
            SoundsTextOutlet.attributedText = createAttributedText(for: "quiet", with: .normal)
            ProgressBarOutlet.progressShapeColor = .normal
        case 40...80:
            SoundsTextOutlet.attributedText = createAttributedText(for: "normal", with: .normal)
            ProgressBarOutlet.progressShapeColor = .normal
        case 80...100:
            SoundsTextOutlet.attributedText = createAttributedText(for: "loud", with: .loud)
            ProgressBarOutlet.progressShapeColor = .loud
        case 100...:
            SoundsTextOutlet.attributedText = createAttributedText(for: "too loud", with: .tooLoud)
            ProgressBarOutlet.progressShapeColor = .tooLoud
        default:
            print("Sounds Text Error")
        }
        
        let normalizedValue = dbA / 105.0
        ProgressBarOutlet.setProgress(progress: CGFloat(normalizedValue), animated: true)
        
        return dbA
    }
    
    deinit {
        timer?.invalidate()
    }
    
    
    //MARK: - Progress Bar
    
    func progressBarSettings() {
        ProgressBarOutlet.orientation = .bottom
        ProgressBarOutlet.lineCap = .round
        
    }
}


    //MARK: - Sounds Text

    func createAttributedText(for soundDescription: String, with color: UIColor) -> NSAttributedString {
        let fullText = "Sounds: \(soundDescription)"
        let attributedString = NSMutableAttributedString(string: fullText)
    
        let soundsAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white]
        let descriptionAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
    
        attributedString.addAttributes(soundsAttributes, range: NSRange(location: 0, length: 7))
        attributedString.addAttributes(descriptionAttributes, range: NSRange(location: 8, length: soundDescription.count))
    
        return attributedString
    }


//MARK: - Extensions

extension UIColor {
    static var normal: UIColor {
        return UIColor(red: 40/255.0, green: 187/255.0, blue: 69/255.0, alpha: 1.0)
    }
    
    static var loud: UIColor {
        return UIColor(red: 187/255.0, green: 154/255.0, blue: 44/255.0, alpha: 1.0)
    }
    
    static var tooLoud: UIColor {
        return UIColor(red: 187/255.0, green: 15/255.0, blue: 2/255.0, alpha: 1.0)
    }
}
