//
//  SoundPlayer.swift
//  Reps
//

import AVFoundation

/// Owns the rest-timer audio.
///
/// While a rest is running it keeps a *silent* audio session alive so the app
/// stays awake in the background and can fire the rest-over chime at the exact
/// moment the timer reaches zero — even with the phone backgrounded or the
/// silent switch on. The keep-alive is mixed with other audio, so it never
/// disturbs the user's music. When the timer ends the chime briefly ducks other
/// audio and then hands playback straight back, so music is only lowered for the
/// duration of the chime itself and returns automatically afterwards.
@MainActor
final class SoundPlayer: NSObject {
    static let shared = SoundPlayer()

    /// Silent looping player that keeps the app alive during a rest.
    private var keepAlive: AVAudioPlayer?
    /// The rest-over chime.
    private var chime: AVAudioPlayer?
    /// Whether a rest is currently running (drives interruption recovery).
    private var running = false

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    // MARK: - Keep-alive

    /// Called when a rest starts. Activates a silent, mix-with-others session so
    /// the app keeps running in the background without touching the user's music.
    func beginKeepAlive() {
        running = true
        keepAlive?.stop()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(data: Self.silenceWAV)
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            keepAlive = player
        } catch {
            // If the session can't be held we simply fall back to the scheduled
            // local notification for the backgrounded case.
        }
    }

    /// Plays the rest-over chime, ducking other audio for just its duration and
    /// restoring it as soon as the chime finishes.
    func playRestOver() {
        guard let url = Bundle.main.url(forResource: "RestComplete", withExtension: "caf") else {
            teardown()
            return
        }
        let session = AVAudioSession.sharedInstance()
        do {
            keepAlive?.stop()
            keepAlive = nil
            // .playback ignores the silent switch; .duckOthers lowers other audio
            // only while the chime is playing.
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            chime = player
        } catch {
            teardown()
        }
    }

    /// Called when a rest is stopped or reset without firing.
    func stop() {
        teardown()
    }

    // MARK: - Internals

    private func teardown() {
        running = false
        keepAlive?.stop()
        keepAlive = nil
        chime?.stop()
        chime = nil
        deactivate()
    }

    /// Deactivates the session and lets other apps (music) resume immediately.
    private func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation
        )
    }

    /// After an interruption (e.g. a phone call) ends, resume the keep-alive if a
    /// rest is still running so the chime can still fire in the background.
    @objc private nonisolated func handleInterruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
        Task { @MainActor in
            if self.running, self.keepAlive == nil, self.chime == nil {
                self.beginKeepAlive()
            }
        }
    }

    // MARK: - Silence source

    /// A tiny in-memory silent WAV used to hold the audio session open. Bundling
    /// it in code avoids shipping and wiring up an audio asset. 0.5s of 8 kHz
    /// mono 16-bit PCM silence, looped.
    private static let silenceWAV: Data = makeSilenceWAV()

    private static func makeSilenceWAV() -> Data {
        let sampleRate: UInt32 = 8_000
        let seconds = 0.5
        let frames = Int(Double(sampleRate) * seconds)
        let dataBytes = frames * 2 // 16-bit mono

        func le32(_ v: UInt32) -> [UInt8] {
            [UInt8(v & 0xff), UInt8((v >> 8) & 0xff), UInt8((v >> 16) & 0xff), UInt8((v >> 24) & 0xff)]
        }
        func le16(_ v: UInt16) -> [UInt8] { [UInt8(v & 0xff), UInt8((v >> 8) & 0xff)] }

        var d = Data()
        d.append(contentsOf: Array("RIFF".utf8))
        d.append(contentsOf: le32(UInt32(36 + dataBytes)))
        d.append(contentsOf: Array("WAVE".utf8))
        d.append(contentsOf: Array("fmt ".utf8))
        d.append(contentsOf: le32(16))                     // PCM header size
        d.append(contentsOf: le16(1))                      // PCM format
        d.append(contentsOf: le16(1))                      // mono
        d.append(contentsOf: le32(sampleRate))             // sample rate
        d.append(contentsOf: le32(sampleRate * 2))         // byte rate
        d.append(contentsOf: le16(2))                      // block align
        d.append(contentsOf: le16(16))                     // bits per sample
        d.append(contentsOf: Array("data".utf8))
        d.append(contentsOf: le32(UInt32(dataBytes)))
        d.append(Data(count: dataBytes))                   // silent samples
        return d
    }
}

extension SoundPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.chime = nil
            self.teardown()
        }
    }
}
