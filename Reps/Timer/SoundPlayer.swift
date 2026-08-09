//
//  SoundPlayer.swift
//  Reps
//

import AVFoundation

/// Plays the rest-over chime through the media (playback) audio session so it
/// sounds like music and is heard even when the phone's silent switch is on —
/// unlike a notification sound, which the ringer switch mutes.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var player: AVAudioPlayer?

    private init() {}

    func playRestOver() {
        guard let url = Bundle.main.url(forResource: "RestComplete", withExtension: "caf") else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback ignores the silent switch; duck any music briefly.
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            // If the audio session can't start, stay silent rather than crash.
        }
    }
}
