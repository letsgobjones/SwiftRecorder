//
//  AudioRoute.swift
//  SwiftRecorder
//
//  Created by Brandon Jones on 7/6/25.
//

import Foundation
import AVFoundation

// MARK: - Supporting Types

enum AudioRoute {
    case builtInMicrophone
    case headphones
    case bluetoothHFP
    case usbAudio
    case airPlay
    case none
    case other(String)
    
    static func from(portType: AVAudioSession.Port) -> AudioRoute {
        switch portType {
        case .builtInMic:
            return .builtInMicrophone
        case .headphones:
            return .headphones
        case .bluetoothHFP:
            return .bluetoothHFP
        case .usbAudio:
            return .usbAudio
        case .airPlay:
            return .airPlay
        default:
            return .other(portType.rawValue)
        }
    }
    
    var displayName: String {
        switch self {
        case .builtInMicrophone: return "Built-in Microphone"
        case .headphones: return "Headphones"
        case .bluetoothHFP: return "Bluetooth"
        case .usbAudio: return "USB Audio"
        case .airPlay: return "AirPlay"
        case .none: return "No Input"
        case .other(let name): return name
        }
    }
    
    var isWired: Bool {
        switch self {
        case .headphones, .usbAudio:
            return true
        default:
            return false
        }
    }
    
    var isWireless: Bool {
        switch self {
        case .bluetoothHFP, .airPlay:
            return true
        default:
            return false
        }
    }
}
