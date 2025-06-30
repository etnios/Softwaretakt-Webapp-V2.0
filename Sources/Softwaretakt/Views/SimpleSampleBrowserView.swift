import SwiftUI
import UniformTypeIdentifiers

/// Super simple and accessible sample browser
struct SimpleSampleBrowserView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @StateObject private var sampleManager = SimpleSampleManager()
    
    @State private var selectedTrack: Int = 0
    @State private var showingFilePicker = false
    @State private var selectedCategory: SimpleSampleCategory? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header info
                infoHeader
                
                // Track selector
                trackSelector
                
                // Category filter
                categoryFilter
                
                // Sample list
                sampleList
                
                // Import button
                importButton
            }
            .navigationTitle("Samples")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if audioEngine.isPreviewingSample {
                            Button("Stop Preview") { 
                                audioEngine.stopPreview()
                            }
                            .foregroundColor(.red)
                        }
                        Button("Done") { 
                            audioEngine.stopPreview() // Stop any preview when closing
                            dismiss() 
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") { 
                        sampleManager.refresh()
                        audioEngine.refreshSamples()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    HStack {
                        if audioEngine.isPreviewingSample {
                            Button("Stop Preview") { 
                                audioEngine.stopPreview()
                            }
                            .foregroundColor(.red)
                        }
                        Button("Done") { 
                            audioEngine.stopPreview() // Stop any preview when closing
                            dismiss() 
                        }
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Refresh") { 
                        sampleManager.refresh()
                        audioEngine.refreshSamples()
                    }
                }
                #endif
            }
        }
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .onAppear {
            // Create default samples if none exist
            if sampleManager.availableSamples.isEmpty {
                sampleManager.createDefaultSamples()
            }
        }
    }
    
    // MARK: - Info Header
    private var infoHeader: some View {
        VStack(spacing: 4) {
            if audioEngine.isPreviewingSample {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.orange)
                    Text("Now playing: \(audioEngine.previewingSampleName)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Stop") {
                        audioEngine.stopPreview()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
            } else {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Tap Preview to listen before loading • Auto-stops after 10 seconds")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
    }
    
    // MARK: - Track Selector
    private var trackSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<16, id: \.self) { track in
                    Button("Track \(track + 1)") {
                        selectedTrack = track
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedTrack == track ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        HStack {
            Button("All") {
                selectedCategory = nil
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedCategory == nil ? Color.green : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(8)
            
            ForEach(SimpleSampleCategory.allCases, id: \.self) { category in
                Button("\(category.displayName)") {
                    selectedCategory = category
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? Color.green : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Sample List
    private var sampleList: some View {
        List {
            ForEach(Array(filteredSamples.enumerated()), id: \.element.id) { index, sample in
                SimpleSampleRowView(
                    sample: Binding(
                        get: { 
                            // Find the sample in the original array
                            if let originalIndex = sampleManager.availableSamples.firstIndex(where: { $0.id == sample.id }) {
                                return sampleManager.availableSamples[originalIndex]
                            }
                            return sample
                        },
                        set: { newValue in
                            // Update the sample in the original array
                            if let originalIndex = sampleManager.availableSamples.firstIndex(where: { $0.id == sample.id }) {
                                sampleManager.availableSamples[originalIndex] = newValue
                            }
                        }
                    ),
                    selectedTrack: selectedTrack,
                    onLoad: { loadSample(sample) },
                    onPreview: { previewSample(sample) }
                )
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredSamples: [SimpleSample] {
        if let category = selectedCategory {
            return sampleManager.getSamples(category: category)
        }
        return sampleManager.availableSamples
    }
    
    // MARK: - Import Button
    private var importButton: some View {
        Button(action: {
            showingFilePicker = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Import Samples")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func loadSample(_ sample: SimpleSample) {
        audioEngine.loadSimpleSample(sample, toTrack: selectedTrack)
        print("✅ Loaded \(sample.name) to track \(selectedTrack + 1)")
    }
    
    private func previewSample(_ sample: SimpleSample) {
        audioEngine.previewSimpleSample(sample)
        print("🔊 Previewing \(sample.name)")
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            var importedCount = 0
            for url in urls {
                if sampleManager.importSample(from: url) {
                    importedCount += 1
                }
            }
            print("✅ Imported \(importedCount) samples")
            
        case .failure(let error):
            print("❌ Import failed: \(error)")
        }
    }
}

// MARK: - Simple Sample Row
struct SimpleSampleRowView: View {
    @Binding var sample: SimpleSample
    let selectedTrack: Int
    let onLoad: () -> Void
    let onPreview: () -> Void
    
    @EnvironmentObject var audioEngine: AudioEngine
    @State private var showingEditor = false
    
    var body: some View {
        HStack {
            // Sample info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(sample.categoryEmoji)
                    Text(sample.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Preview indicator
                    if audioEngine.isPreviewingSample && audioEngine.previewingSampleName == sample.name {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Playing...")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                    }
                }
                
                Text("\(sample.durationString) • \(Int(sample.sampleRate))Hz • \(sample.channels)ch")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // Edit button
                Button(action: {
                    showingEditor = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(6)
                
                // Preview/Stop button
                if audioEngine.isPreviewingSample && audioEngine.previewingSampleName == sample.name {
                    Button("Stop") {
                        audioEngine.stopPreview()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .font(.caption)
                } else {
                    Button("Preview") {
                        onPreview()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .font(.caption)
                }
                
                Button("Load to Track \(selectedTrack + 1)") {
                    onLoad()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(6)
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
        .sheet(isPresented: $showingEditor) {
            SampleEditorView(sample: $sample)
                .environmentObject(audioEngine)
        }
    }
}

#Preview {
    SimpleSampleBrowserView()
        .environmentObject(AudioEngine())
}
