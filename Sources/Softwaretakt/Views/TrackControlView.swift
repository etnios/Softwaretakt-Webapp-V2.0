import SwiftUI

struct TrackControlView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    let trackIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Track \(trackIndex + 1) Controls")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Volume control
            VStack(alignment: .leading) {
                Text("Volume")
                    .foregroundColor(.gray)
                Slider(value: Binding(
                    get: { audioEngine.getTrackVolume(trackIndex) },
                    set: { audioEngine.setTrackVolume(trackIndex, volume: $0) }
                ), in: 0...1)
                .accentColor(.cyan)
            }
            
            // Pan control
            VStack(alignment: .leading) {
                Text("Pan")
                    .foregroundColor(.gray)
                Slider(value: Binding(
                    get: { audioEngine.getTrackPan(trackIndex) },
                    set: { audioEngine.setTrackPan(trackIndex, pan: $0) }
                ), in: -1...1)
                .accentColor(.purple)
            }
            
            // Filter controls
            VStack(alignment: .leading, spacing: 10) {
                Text("Filter")
                    .foregroundColor(.gray)
                
                // Cutoff
                HStack {
                    Text("Cutoff")
                        .frame(width: 60, alignment: .leading)
                        .foregroundColor(.gray)
                    Slider(value: Binding(
                        get: { audioEngine.getFilterCutoff(trackIndex) },
                        set: { audioEngine.setFilterCutoff($0, forTrack: trackIndex) }
                    ), in: 20...20000)
                    .accentColor(.orange)
                }
                
                // Resonance
                HStack {
                    Text("Res")
                        .frame(width: 60, alignment: .leading)
                        .foregroundColor(.gray)
                    Slider(value: Binding(
                        get: { audioEngine.getFilterResonance(trackIndex) },
                        set: { audioEngine.setFilterResonance($0, forTrack: trackIndex) }
                    ), in: 0.0...30.0)
                    .accentColor(.orange)
                }
            }
            
            // Sample info
            VStack(alignment: .leading, spacing: 5) {
                Text("Sample")
                    .foregroundColor(.gray)
                
                if let sampleName = audioEngine.getCurrentSample(trackIndex) {
                    Text(sampleName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(5)
                } else {
                    Text("No sample loaded")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                }
            }
            
            // Quick actions
            HStack(spacing: 10) {
                Button("Mute") {
                    audioEngine.toggleMute(trackIndex)
                }
                .padding(8)
                .background(audioEngine.isTrackMuted(trackIndex) ? Color.red : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(5)
                
                Button("Solo") {
                    audioEngine.toggleSolo(trackIndex)
                }
                .padding(8)
                .background(audioEngine.isTrackSoloed(trackIndex) ? Color.yellow : Color.gray.opacity(0.3))
                .foregroundColor(.black)
                .cornerRadius(5)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3) as Color)
        .cornerRadius(15)
    }
}

#Preview {
    TrackControlView(trackIndex: 0)
        .environmentObject(AudioEngine())
        .background(Color.black)
}
