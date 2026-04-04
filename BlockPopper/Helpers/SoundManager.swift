import AVFoundation
import UIKit

/// Manages all game sounds and haptic feedback.
class SoundManager {

    static let shared = SoundManager()

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)

    private init() {
        self.lightImpact.prepare()
        self.mediumImpact.prepare()
        self.heavyImpact.prepare()
        generateSounds()
    }

    // MARK: - Public API

    func playPickup() {
        self.lightImpact.impactOccurred()
        playSound(named: "pickup")
    }

    func playValidDrop() {
        self.mediumImpact.impactOccurred()
        playSound(named: "validDrop")
    }

    func playInvalidDrop() {
        self.lightImpact.impactOccurred(intensity: 0.4)
        playSound(named: "invalidDrop")
    }

    func playLineClear() {
        self.heavyImpact.impactOccurred()
        playSound(named: "firework")
    }

    // MARK: - Sound Generation

    private func generateSounds() {
        self.audioPlayers["pickup"] = makeWoodenSlidePlayer()
        self.audioPlayers["validDrop"] = makeSoftThudPlayer()
        self.audioPlayers["invalidDrop"] = makeCardboardSetPlayer()
        self.audioPlayers["firework"] = makeFireworkPlayer()
    }

    // Wooden slide: short scrape of wood dragging across a surface
    private func makeWoodenSlidePlayer() -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let duration: Double = 0.12
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)
        let volume: Float = 0.3

        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            let progress = time / duration
            let envelope = (1.0 - progress) * (1.0 - progress)
            let noise = Double.random(in: -1...1)
            let filtered = noise * 0.6 + sin(2.0 * .pi * 320 * time) * 0.4
            samples[i] = Float(filtered * envelope) * volume
        }
        return playerFromSamples(samples, sampleRate: sampleRate)
    }

    // Soft thud: muted warm landing on padded surface
    private func makeSoftThudPlayer() -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let duration: Double = 0.15
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)
        let volume: Float = 0.45

        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            let progress = time / duration
            // Fast exponential decay for thud character
            let envelope = exp(-progress * 12.0)
            // Low frequency body + slight noise for texture
            let body = sin(2.0 * .pi * 80 * time) * 0.7
            let overtone = sin(2.0 * .pi * 160 * time) * 0.2
            let texture = Double.random(in: -1...1) * 0.1 * (1.0 - progress)
            samples[i] = Float((body + overtone + texture) * envelope) * volume
        }
        return playerFromSamples(samples, sampleRate: sampleRate)
    }

    private func makeCardboardSetPlayer() -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let duration: Double = 0.10
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)
        let volume: Float = 0.25

        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            let progress = time / duration
            let envelope = exp(-progress * 18.0)
            // Very low thump + muffled noise
            let thump = sin(2.0 * .pi * 60 * time) * 0.6
            let muffle = Double.random(in: -1...1) * 0.4 * exp(-progress * 25.0)
            samples[i] = Float((thump + muffle) * envelope) * volume
        }
        return playerFromSamples(samples, sampleRate: sampleRate)
    }

    private func playSound(named name: String) {
        guard let player = self.audioPlayers[name] else { return }
        player.currentTime = 0
        player.play()
    }

    private func makeFireworkPlayer() -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let duration: Double = 0.35
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)
        let volume: Float = 0.4

        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            let progress = time / duration

            // Rising whistle (frequency sweep 400 -> 1200 Hz)
            let whistleFrequency = 400.0 + progress * 800.0
            let whistle = sin(2.0 * .pi * whistleFrequency * time)

            // Crackle noise burst in last 40%
            let crackle: Double
            if progress > 0.6 {
                let noisePhase = Double.random(in: -1...1)
                crackle = noisePhase * (1.0 - progress) * 3.0
            } else {
                crackle = 0
            }

            // Envelope: rise then sharp fall
            let envelope: Double
            if progress < 0.6 {
                envelope = progress / 0.6
            } else {
                envelope = (1.0 - progress) / 0.4
            }

            samples[i] = Float((whistle * 0.5 + crackle * 0.5) * envelope) * volume
        }

        return playerFromSamples(samples, sampleRate: sampleRate)
    }

    // MARK: - WAV Builder

    private func playerFromSamples(_ samples: [Float], sampleRate: Double) -> AVAudioPlayer? {
        let dataSize = samples.count * 2  // 16-bit samples
        var wavData = Data()

        // WAV header
        wavData.append(contentsOf: "RIFF".utf8)
        appendUInt32(&wavData, UInt32(36 + dataSize))
        wavData.append(contentsOf: "WAVE".utf8)
        wavData.append(contentsOf: "fmt ".utf8)
        appendUInt32(&wavData, 16)          // chunk size
        appendUInt16(&wavData, 1)           // PCM format
        appendUInt16(&wavData, 1)           // mono
        appendUInt32(&wavData, UInt32(sampleRate))
        appendUInt32(&wavData, UInt32(sampleRate) * 2)  // byte rate
        appendUInt16(&wavData, 2)           // block align
        appendUInt16(&wavData, 16)          // bits per sample
        wavData.append(contentsOf: "data".utf8)
        appendUInt32(&wavData, UInt32(dataSize))

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let intSample = Int16(clamped * Float(Int16.max))
            appendInt16(&wavData, intSample)
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
