#if os(iOS)
import UIKit
import CoreAudioKit
import SwiftUI

// 🎛️ SOFTWARETAKT AU3 VIEW CONTROLLER - FOR AUM COMPATIBILITY

@objc public class SoftwaretaktAudioUnitViewController: AUViewController, AUAudioUnitFactory {
    
    // MARK: - Properties
    
    private var audioUnit: SoftwaretaktAudioUnit?
    private var hostingController: UIHostingController<SoftwaretaktAU3View>?
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAudioUnitView()
        
        print("🔥 Softwaretakt AU3 ViewController loaded!")
    }
    
    private func setupAudioUnitView() {
        // Create SwiftUI view for the AU3 interface
        let auView = SoftwaretaktAU3View(audioUnit: audioUnit)
        hostingController = UIHostingController(rootView: auView)
        
        guard let hostingController = hostingController else { return }
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set preferred content size for AUM
        preferredContentSize = CGSize(width: 800, height: 600)
    }
    
    // MARK: - AUAudioUnitFactory
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try SoftwaretaktAudioUnit(componentDescription: componentDescription)
        
        // Update the view with the new audio unit
        if let audioUnit = audioUnit {
            DispatchQueue.main.async {
                self.hostingController?.rootView = SoftwaretaktAU3View(audioUnit: audioUnit)
            }
        }
        
        return audioUnit!
    }
}

// MARK: - SwiftUI AU3 Interface

struct SoftwaretaktAU3View: View {
    
    weak var audioUnit: SoftwaretaktAudioUnit?
    
    @State private var selectedTrack: Int = 0
    @State private var trackVolumes: [Float] = Array(repeating: 0.8, count: 16)
    @State private var trackPans: [Float] = Array(repeating: 0.0, count: 16)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Header
                HStack {
                    Text("🎛️ SOFTWARETAKT AU3")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("Track \(selectedTrack + 1)")
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                
                // Track Selection Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(0..<16, id: \.self) { track in
                        Button(action: {
                            selectedTrack = track
                            triggerTrack(track)
                        }) {
                            VStack {
                                Text("\(track + 1)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundColor(selectedTrack == track ? .green : .gray)
                            }
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .background(selectedTrack == track ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                // Track Controls
                VStack(spacing: 16) {
                    
                    // Volume Control
                    VStack {
                        HStack {
                            Text("Volume")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(trackVolumes[selectedTrack] * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { trackVolumes[selectedTrack] },
                            set: { newValue in
                                trackVolumes[selectedTrack] = newValue
                                setTrackVolume(selectedTrack, volume: newValue)
                            }
                        ), in: 0...1)
                        .accentColor(.green)
                    }
                    
                    // Pan Control
                    VStack {
                        HStack {
                            Text("Pan")
                                .font(.headline)
                            Spacer()
                            Text(panDescription(trackPans[selectedTrack]))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { trackPans[selectedTrack] },
                            set: { newValue in
                                trackPans[selectedTrack] = newValue
                                setTrackPan(selectedTrack, pan: newValue)
                            }
                        ), in: -1...1)
                        .accentColor(.blue)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // FM Synthesis Quick Controls
                VStack(spacing: 12) {
                    Text("FM Synthesis")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        Button("Preset 1") {
                            loadFMPreset(1)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Preset 2") {
                            loadFMPreset(2)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Preset 3") {
                            loadFMPreset(3)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Footer
                Text("Compatible with AUM, GarageBand, Logic Pro")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
            .background(Color(UIColor.systemBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Helper Methods
    
    private func triggerTrack(_ track: Int) {
        // Trigger the track via AU parameter
        audioUnit?.parameterTree?.parameter(withAddress: AUParameterAddress(100 + track))?.setValue(1.0, originator: nil)
    }
    
    private func setTrackVolume(_ track: Int, volume: Float) {
        audioUnit?.parameterTree?.parameter(withAddress: AUParameterAddress(200 + track))?.setValue(AUValue(volume), originator: nil)
    }
    
    private func setTrackPan(_ track: Int, pan: Float) {
        audioUnit?.parameterTree?.parameter(withAddress: AUParameterAddress(300 + track))?.setValue(AUValue(pan), originator: nil)
    }
    
    private func loadFMPreset(_ preset: Int) {
        // Load different FM presets
        let algorithms: [Int] = [1, 5, 12] // Different FM algorithms
        let algorithm = algorithms[min(preset - 1, algorithms.count - 1)]
        
        audioUnit?.parameterTree?.parameter(withAddress: 400)?.setValue(AUValue(algorithm), originator: nil)
    }
    
    private func panDescription(_ pan: Float) -> String {
        if pan < -0.1 {
            return "L\(Int(abs(pan) * 100))"
        } else if pan > 0.1 {
            return "R\(Int(pan * 100))"
        } else {
            return "Center"
        }
    }
}

// MARK: - Preview

struct SoftwaretaktAU3View_Previews: PreviewProvider {
    static var previews: some View {
        SoftwaretaktAU3View(audioUnit: nil)
            .previewLayout(.fixed(width: 800, height: 600))
    }
}

#endif // os(iOS)
