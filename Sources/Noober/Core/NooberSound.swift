import AVFoundation

@MainActor
enum NooberSound {

    private static var player: AVAudioPlayer?

    private static let mutedKey = "com.noober.sound.muted"

    static var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: mutedKey) }
        set { UserDefaults.standard.set(newValue, forKey: mutedKey) }
    }

    /// Play the "faaa" sound — used for mock/intercept rule toggles.
    static func playFaaa() {
        play("faaa")
    }

    /// Play the "are baap re" sound — used for env changes and custom actions.
    static func playAreBaapRe() {
        play("are_baap_re")
    }

    private static func play(_ resource: String) {
        guard !isMuted else { return }
        guard let url = Bundle.module.url(forResource: resource, withExtension: "mp3") else { return }

        // Playback category bypasses the silent switch; mixWithOthers avoids
        // interrupting music or other audio the user may be playing.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        guard let audioPlayer = try? AVAudioPlayer(contentsOf: url) else { return }
        audioPlayer.volume = 0.35 // caps output at ~35% of system volume → always low-mid
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        player = audioPlayer // retain
    }
}
