import SwiftUI
import UniformTypeIdentifiers

struct SampleBrowserView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @Environment(\.dismiss) var dismiss
    @State private var samples: [Sample] = []
    @State private var selectedSample: Sample?
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Text("Sample Browser")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button("Import") {
                        showingFilePicker = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                
                // Sample list
                List(samples, id: \.id) { sample in
                    SampleRowView(
                        sample: sample,
                        isSelected: selectedSample?.id == sample.id,
                        onSelect: { selectedSample = sample },
                        onLoad: { track in
                            loadSampleToTrack(sample: sample, track: track)
                        }
                    )
                }
                
                // Preview controls
                if let selectedSample = selectedSample {
                    VStack {
                        Text("Preview: \(selectedSample.name)")
                            .font(.headline)
                            .padding()
                        
                        HStack {
                            Button("Play") {
                                audioEngine.previewSample(selectedSample)
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            
                            Button("Stop") {
                                audioEngine.stopPreview()
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadSamples()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.audio],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result: result)
        }
    }
    
    private func loadSamples() {
        // Load default samples and user imported samples
        samples = audioEngine.getAvailableSamples()
    }
    
    private func loadSampleToTrack(sample: Sample, track: Int) {
        audioEngine.loadSample(sample, toTrack: track)
        dismiss()
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let success = audioEngine.importSample(from: url)
                if success {
                    print("✅ Successfully imported: \(url.lastPathComponent)")
                } else {
                    print("❌ Failed to import: \(url.lastPathComponent)")
                }
            }
            loadSamples() // Refresh the list
        case .failure(let error):
            print("File import failed: \(error)")
        }
    }
}

struct SampleRowView: View {
    let sample: Sample
    let isSelected: Bool
    let onSelect: () -> Void
    let onLoad: (Int) -> Void
    
    @State private var showingTrackSelector = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(sample.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(sample.duration, specifier: "%.1f")s • \(sample.sampleRate)Hz")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button("Load") {
                showingTrackSelector = true
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.vertical, 5)
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onSelect()
        }
        #if os(iOS)
        .actionSheet(isPresented: $showingTrackSelector) {
            ActionSheet(
                title: Text("Load to Track"),
                message: Text("Select a track to load this sample"),
                buttons: (0..<16).map { track in
                    .default(Text("Track \(track + 1)")) {
                        onLoad(track)
                    }
                } + [.cancel()]
            )
        }
        #else
        .confirmationDialog("Load to Track", isPresented: $showingTrackSelector) {
            ForEach(0..<16, id: \.self) { track in
                Button("Track \(track + 1)") {
                    onLoad(track)
                }
            }
        }
        #endif
    }
}

#Preview {
    SampleBrowserView()
        .environmentObject(AudioEngine())
}
