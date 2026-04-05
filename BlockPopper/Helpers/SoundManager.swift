import AudioToolbox
import AVFoundation
import UIKit

/// Manages all game sounds and haptic feedback.
/// Uses iOS system sounds for interactions, synthesized audio for line clears.
class SoundManager {

    static let shared = SoundManager()

    private var fireworkPlayer: AVAudioPlayer?
    private var victoryPlayer: AVAudioPlayer?
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)

    private let pickupSoundID: SystemSoundID = 1057
    private let validDropSoundID: SystemSoundID = 1104
    private let invalidDropSoundID: SystemSoundID = 1103

    private init() {
        self.lightImpact.prepare()
        self.mediumImpact.prepare()
        self.heavyImpact.prepare()
        self.fireworkPlayer = makeFireworkPlayer()
        self.victoryPlayer = makeVictoryPlayer()
    }

    // MARK: - Public API

    func playPickup() {
        self.lightImpact.impactOccurred()
        AudioServicesPlaySystemSound(self.pickupSoundID)
    }

    func playValidDrop() {
        self.mediumImpact.impactOccurred()
        AudioServicesPlaySystemSound(self.validDropSoundID)
    }

    func playInvalidDrop() {
        self.lightImpact.impactOccurred(intensity: 0.4)
        AudioServicesPlaySystemSound(self.invalidDropSoundID)
    }

    func playLineClear() {
        self.heavyImpact.impactOccurred()
        self.fireworkPlayer?.currentTime = 0
        self.fireworkPlayer?.play()
    }

    func playVictory() {
        self.heavyImpact.impactOccurred()
        self.victoryPlayer?.currentTime = 0
        self.victoryPlayer?.play()
    }

    // MARK: - Firework Synthesis

    private func makeFireworkPlayer() -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let duration: Double = 0.35
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)
        let volume: Float = 0.4

        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            let progress = time / duration
            let whistleFrequency = 400.0 + progress * 800.0
            let whistle = sin(2.0 * .pi * whistleFrequency * time)
            let crackle: Double = progress > 0.6
                ? Double.random(in: -1...1) * (1.0 - progress) * 3.0
                : 0
            let envelope: Double = progress < 0.6
                ? progress / 0.6
                : (1.0 - progress) / 0.4
            samples[i] = Float((whistle * 0.5 + crackle * 0.5) * envelope) * volume
        }
        return playerFromSamples(samples, sampleRate: sampleRate)
    }

    // MARK: - Victory Fanfare Synthesis

    private func makeVictoryPlayer() -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let duration: Double = 1.2
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)
        let volume: Float = 0.35

        // Three ascending notes: C5 → E5 → G5, then a sustained chord
        let notes: [(freq: Double, start: Double, end: Double)] = [
            (523.25, 0.0, 0.3),    // C5
            (659.25, 0.2, 0.5),    // E5
            (783.99, 0.4, 0.8),    // G5
            (1046.50, 0.6, 1.2),   // C6 (sustained)
        ]

        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            var value: Double = 0

            for note in notes {
                guard time >= note.start && time < note.end else { continue }
                let noteProgress = (time - note.start) / (note.end - note.start)
                // Attack-sustain-release envelope
                let attack = min(1.0, (time - note.start) / 0.03)
                let release = noteProgress > 0.7 ? (1.0 - noteProgress) / 0.3 : 1.0
                let envelope = attack * release

                // Rich tone: fundamental + harmonics
                let fundamental = sin(2.0 * .pi * note.freq * time)
                let harmonic2 = sin(2.0 * .pi * note.freq * 2.0 * time) * 0.3
                let harmonic3 = sin(2.0 * .pi * note.freq * 3.0 * time) * 0.15
                value += (fundamental + harmonic2 + harmonic3) * envelope * 0.4
            }

            // Add a subtle shimmer/sparkle
            if time > 0.5 {
                let shimmer = sin(2.0 * .pi * 2000.0 * time) * 0.05
                    * sin(2.0 * .pi * 8.0 * time) // tremolo
                    * max(0, 1.0 - (time - 0.5) / 0.7)
                value += shimmer
            }

            samples[i] = Float(value) * volume
        }

        return playerFromSamples(samples, sampleRate: sampleRate)
    }

    // MARK: - WAV Builder

    private func playerFromSamples(_ samples: [Float], sampleRate: Double) -> AVAudioPlayer? {
        let dataSize = samples.count * 2
        var wavData = Data()

        wavData.append(contentsOf: "RIFF".utf8)
        appendUInt32(&wavData, UInt32(36 + dataSize))
        wavData.append(contentsOf: "WAVE".utf8)
        wavData.append(contentsOf: "fmt ".utf8)
        appendUInt32(&wavData, 16)
        appendUInt16(&wavData, 1)
        appendUInt16(&wavData, 1)
        appendUInt32(&wavData, UInt32(sampleRate))
        appendUInt32(&wavData, UInt32(sampleRate) * 2)
        appendUInt16(&wavData, 2)
        appendUInt16(&wavData, 16)
        wavData.append(contentsOf: "data".utf8)
        appendUInt32(&wavData, UInt32(dataSize))

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            appendInt16(&wavData, Int16(clamped * Float(Int16.max)))
        }
        return try? AVAudioPlayer(data: wavData)
    }

    private func appendUInt32(_ data: inout Data, _ value: UInt32) {
        var littleEndian = value.littleEndian
        data.append(Data(bytes: &littleEndian, count: 4))
    }

    private func appendUInt16(_ data: inout Data, _ value: UInt16) {
        var littleEndian = value.littleEndian
        data.append(Data(bytes: &littleEndian, count: 2))
    }

    private func appendInt16(_ data: inout Data, _ value: Int16) {
        var littleEndian = value.littleEndian
        data.append(Data(bytes: &littleEndian, count: 2))
    }
}
