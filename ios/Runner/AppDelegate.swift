import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller = window?.rootViewController as! FlutterViewController
    let videoChannel = FlutterMethodChannel(name: "com.app.more/video_utils", binaryMessenger: controller.binaryMessenger)
    videoChannel.setMethodCallHandler { (call, result) in
        if call.method == "stripAudio" {
            guard let args = call.arguments as? [String: Any],
                  let inputPath = args["inputPath"] as? String,
                  let outputPath = args["outputPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments must be inputPath and outputPath", details: nil))
                return
            }
            self.stripAudio(inputPath: inputPath, outputPath: outputPath) { success, errorMsg in
                if success {
                    result(outputPath)
                } else {
                    result(FlutterError(code: "EXPORT_FAILED", message: errorMsg ?? "Unknown error", details: nil))
                }
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    let badgeChannel = FlutterMethodChannel(name: "com.app.more/badge_utils", binaryMessenger: controller.binaryMessenger)
    badgeChannel.setMethodCallHandler { (call, result) in
        if call.method == "setBadgeCount" {
            guard let args = call.arguments as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Argument must be an integer", details: nil))
                return
            }
            if #available(iOS 16.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(args) { error in
                    if let error = error {
                        print("Error setting badge count: \(error)")
                        result(FlutterError(code: "IOS_ERROR", message: error.localizedDescription, details: nil))
                    } else {
                        result(true)
                    }
                }
            } else {
                UIApplication.shared.applicationIconBadgeNumber = args
                result(true)
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func stripAudio(inputPath: String, outputPath: String, completion: @escaping (Bool, String?) -> Void) {
    let inputURL = URL(fileURLWithPath: inputPath)
    let outputURL = URL(fileURLWithPath: outputPath)
    
    try? FileManager.default.removeItem(at: outputURL)
    
    let asset = AVAsset(url: inputURL)
    let videoTracks = asset.tracks(withMediaType: .video)
    if videoTracks.isEmpty {
        completion(false, "No video track found")
        return
    }
    
    let mixComposition = AVMutableComposition()
    guard let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        completion(false, "Failed to add video track to composition")
        return
    }
    
    do {
        for track in videoTracks {
            try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: track, at: .zero)
        }
        
        guard let finalExport = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(false, "Failed to create final export session")
            return
        }
        
        finalExport.outputURL = outputURL
        finalExport.outputFileType = .mp4
        finalExport.shouldOptimizeForNetworkUse = true
        
        finalExport.exportAsynchronously {
            switch finalExport.status {
            case .completed:
                completion(true, nil)
            case .failed:
                completion(false, finalExport.error?.localizedDescription ?? "Export failed")
            case .cancelled:
                completion(false, "Export cancelled")
            default:
                completion(false, "Unknown export status")
            }
        }
    } catch {
        completion(false, error.localizedDescription)
    }
  }
}
