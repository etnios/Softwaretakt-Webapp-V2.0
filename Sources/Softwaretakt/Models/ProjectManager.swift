import Foundation

// 🗂️ SOFTWARETAKT PROJECT MANAGEMENT - SMARTER THAN HARDWARE!

// MARK: - Project Sequence

struct SoftwaretaktSequence: Codable {
    let id: UUID
    var name: String
    var patterns: [UUID]  // References to patterns
    var length: Int
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.patterns = []
        self.length = 0
    }
}

// MARK: - Sample Reference System

/// Represents a reference to a sample within a project
struct SampleReference: Codable, Hashable {
    let sampleID: UUID           // Unique sample identifier
    let originalPath: String     // Original sample file path
    let sampleName: String       // User-friendly name
    let trackIndex: Int         // Which track uses this sample
    let dateAdded: Date         // When added to project
    let md5Hash: String         // File integrity check
    
    init(sample: Sample, trackIndex: Int) {
        self.sampleID = sample.id
        self.originalPath = sample.url.path
        self.sampleName = sample.name
        self.trackIndex = trackIndex
        self.dateAdded = Date()
        self.md5Hash = sample.md5Hash ?? ""
    }
}

/// Global sample usage tracking
struct SampleUsage: Codable {
    let sampleID: UUID
    let samplePath: String
    var usedInProjects: Set<UUID>  // Projects using this sample
    var totalUsageCount: Int       // How many times it's used
    let dateFirstUsed: Date
    var lastUsedDate: Date
    
    mutating func addProject(_ projectID: UUID) {
        usedInProjects.insert(projectID)
        totalUsageCount += 1
        lastUsedDate = Date()
    }
    
    mutating func removeProject(_ projectID: UUID) {
        usedInProjects.remove(projectID)
        if usedInProjects.isEmpty {
            totalUsageCount = 0
        }
    }
    
    var isProtected: Bool {
        return !usedInProjects.isEmpty
    }
}

// MARK: - Project Structure

struct SoftwaretaktProject: Codable {
    // Project Identity
    let id: UUID
    var name: String
    var description: String
    let dateCreated: Date
    var dateModified: Date
    
    // Project Settings
    var bpm: Double
    var key: String
    var scale: String
    var projectColor: String
    
    // Track Configuration
    var trackConfigs: [ProjectTrackConfig]
    var patterns: [Pattern]
    var sequences: [SoftwaretaktSequence]  // Renamed to avoid conflict with Swift's Sequence protocol
    
    // Sample References (Smart!)
    var sampleReferences: [SampleReference]
    var missingSamples: [SampleReference]  // Samples that can't be found
    
    // Project-specific settings
    var masterVolume: Float
    var masterEffects: [String: String]  // Simplified for Codable compliance
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.description = ""
        self.dateCreated = Date()
        self.dateModified = Date()
        
        self.bpm = 120.0
        self.key = "C"
        self.scale = "Major"
        self.projectColor = "blue"
        
        // Initialize 16 tracks with default settings
        self.trackConfigs = (0..<16).map { index in
            ProjectTrackConfig(trackIndex: index)
        }
        
        self.patterns = []
        self.sequences = []
        self.sampleReferences = []
        self.missingSamples = []
        
        self.masterVolume = 0.8
        self.masterEffects = [:]
    }
}

/// Project-specific track configuration
struct ProjectTrackConfig: Codable {
    let trackIndex: Int
    var name: String
    var engineType: SynthEngineType
    var synthParams: SynthParameters
    var sampleReference: SampleReference?  // Reference, not copy!
    
    // Track state
    var volume: Float
    var pan: Float
    var isMuted: Bool
    var isSoloed: Bool
    
    // Effects chain
    var effects: [String: String]  // Simplified for Codable compliance
    
    init(trackIndex: Int) {
        self.trackIndex = trackIndex
        self.name = "Track \(trackIndex + 1)"
        self.engineType = .sample
        self.synthParams = SynthParameters()
        self.sampleReference = nil
        
        self.volume = 0.8
        self.pan = 0.0
        self.isMuted = false
        self.isSoloed = false
        
        self.effects = [:]
    }
}

// MARK: - Project Manager

@MainActor
class ProjectManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentProject: SoftwaretaktProject?
    @Published var availableProjects: [SoftwaretaktProject] = []
    @Published var globalSampleUsage: [UUID: SampleUsage] = [:]
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    
    // MARK: - Core Properties
    
    private let audioEngine: AudioEngine
    private let fileManager = FileManager.default
    private let projectsDirectory: URL
    private let samplesDirectory: URL
    
    // MARK: - Initialization
    
    init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
        
        // Setup directories
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.projectsDirectory = documentsPath.appendingPathComponent("SoftwaretaktProjects")
        self.samplesDirectory = documentsPath.appendingPathComponent("SoftwaretaktSamples")
        
        setupDirectories()
        loadGlobalSampleUsage()
        loadAvailableProjects()
        
        // Create default project if none exist
        if availableProjects.isEmpty {
            createNewProject(name: "My First Project")
        }
    }
    
    private func setupDirectories() {
        try? fileManager.createDirectory(at: projectsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: samplesDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Project Operations
    
    func createNewProject(name: String) {
        let project = SoftwaretaktProject(name: name)
        availableProjects.append(project)
        saveProject(project)
        loadProject(project.id)
        
        print("📁 Created new project: \(name)")
    }
    
    func loadProject(_ projectID: UUID) {
        guard let project = availableProjects.first(where: { $0.id == projectID }) else {
            lastError = "Project not found"
            return
        }
        
        isLoading = true
        
        Task {
            await loadProjectToAudioEngine(project)
            
            await MainActor.run {
                currentProject = project
                isLoading = false
                print("📂 Loaded project: \(project.name)")
            }
        }
    }
    
    private func loadProjectToAudioEngine(_ project: SoftwaretaktProject) async {
        // Apply project settings to audio engine
        await MainActor.run {
            audioEngine.currentBPM = project.bpm
            
            // Load track configurations
            for (index, trackConfig) in project.trackConfigs.enumerated() {
                // Set engine type
                audioEngine.setEngineType(trackConfig.engineType, forTrack: index)
                
                // Load sample if referenced
                if let sampleRef = trackConfig.sampleReference {
                    loadSampleReference(sampleRef, toTrack: index)
                }
                
                // Apply track settings
                audioEngine.setTrackVolume(index, volume: trackConfig.volume)
                audioEngine.setTrackPan(index, pan: trackConfig.pan)
                
                if trackConfig.isMuted {
                    audioEngine.toggleMute(index)
                }
            }
        }
    }
    
    func saveCurrentProject() {
        guard var project = currentProject else { return }
        
        // Update project with current audio engine state
        updateProjectFromAudioEngine(&project)
        
        // Save to disk
        saveProject(project)
        
        // Update in memory
        if let index = availableProjects.firstIndex(where: { $0.id == project.id }) {
            availableProjects[index] = project
        }
        
        currentProject = project
        print("💾 Saved project: \(project.name)")
    }
    
    private func updateProjectFromAudioEngine(_ project: inout SoftwaretaktProject) {
        project.dateModified = Date()
        project.bpm = audioEngine.currentBPM
        
        // Update track configurations from audio engine
        for index in 0..<16 {
            var trackConfig = project.trackConfigs[index]
            
            trackConfig.engineType = audioEngine.getEngineType(forTrack: index)
            trackConfig.volume = audioEngine.getTrackVolume(index)
            trackConfig.pan = audioEngine.getTrackPan(index)
            trackConfig.isMuted = audioEngine.isTrackMuted(index)
            trackConfig.isSoloed = audioEngine.isTrackSoloed(index)
            
            project.trackConfigs[index] = trackConfig
        }
    }
    
    // MARK: - Smart Sample Management
    
    func addSampleToProject(_ sample: Sample, toTrack track: Int) {
        guard var project = currentProject else { return }
        
        // Create sample reference
        let sampleRef = SampleReference(sample: sample, trackIndex: track)
        
        // Add to project
        project.sampleReferences.append(sampleRef)
        project.trackConfigs[track].sampleReference = sampleRef
        
        // Update global usage tracking
        updateGlobalSampleUsage(for: sample, projectID: project.id, adding: true)
        
        // Load sample to audio engine
        audioEngine.loadSample(sample, toTrack: track)
        
        // Update current project
        currentProject = project
        
        print("🎵 Added sample '\(sample.name)' to project '\(project.name)' track \(track + 1)")
        print("📊 Sample now used in \(globalSampleUsage[sample.id]?.usedInProjects.count ?? 1) project(s)")
    }
    
    func removeSampleFromProject(track: Int) {
        guard var project = currentProject else { return }
        
        // Find and remove sample reference
        if let sampleRef = project.trackConfigs[track].sampleReference {
            project.sampleReferences.removeAll { $0.sampleID == sampleRef.sampleID && $0.trackIndex == track }
            project.trackConfigs[track].sampleReference = nil
            
            // Update global usage
            updateGlobalSampleUsage(for: sampleRef.sampleID, projectID: project.id, adding: false)
            
            currentProject = project
            
            print("🗑️ Removed sample from track \(track + 1)")
        }
    }
    
    private func updateGlobalSampleUsage(for sample: Sample, projectID: UUID, adding: Bool) {
        updateGlobalSampleUsage(for: sample.id, projectID: projectID, adding: adding)
    }
    
    private func updateGlobalSampleUsage(for sampleID: UUID, projectID: UUID, adding: Bool) {
        if adding {
            if var usage = globalSampleUsage[sampleID] {
                usage.addProject(projectID)
                globalSampleUsage[sampleID] = usage
            } else {
                let usage = SampleUsage(
                    sampleID: sampleID,
                    samplePath: "", // Would need to get from sample
                    usedInProjects: [projectID],
                    totalUsageCount: 1,
                    dateFirstUsed: Date(),
                    lastUsedDate: Date()
                )
                globalSampleUsage[sampleID] = usage
            }
        } else {
            globalSampleUsage[sampleID]?.removeProject(projectID)
        }
        
        saveGlobalSampleUsage()
    }
    
    // MARK: - Sample Protection & Analysis
    
    func getSampleUsageInfo(for sample: Sample) -> SampleUsage? {
        return globalSampleUsage[sample.id]
    }
    
    func canDeleteSample(_ sample: Sample) -> Bool {
        guard let usage = globalSampleUsage[sample.id] else { return true }
        return !usage.isProtected
    }
    
    func getProjectsUsingSample(_ sample: Sample) -> [SoftwaretaktProject] {
        guard let usage = globalSampleUsage[sample.id] else { return [] }
        
        return availableProjects.filter { project in
            usage.usedInProjects.contains(project.id)
        }
    }
    
    func findUnusedSamples() -> [Sample] {
        // This would scan the samples directory and find samples not referenced in any project
        // Implementation would compare available samples with global usage tracking
        return []
    }
    
    // MARK: - Project Utilities
    
    func duplicateProject(_ projectID: UUID, newName: String) {
        guard let originalProject = availableProjects.first(where: { $0.id == projectID }) else { return }
        
        // Create new project with new ID
        var newProject = SoftwaretaktProject(name: newName)
        newProject.description = originalProject.description
        newProject.bpm = originalProject.bpm
        newProject.key = originalProject.key
        newProject.scale = originalProject.scale
        newProject.projectColor = originalProject.projectColor
        newProject.trackConfigs = originalProject.trackConfigs
        newProject.patterns = originalProject.patterns
        newProject.sequences = originalProject.sequences
        newProject.sampleReferences = originalProject.sampleReferences
        newProject.masterVolume = originalProject.masterVolume
        newProject.masterEffects = originalProject.masterEffects
        
        // Update sample references to point to new project
        for sampleRef in newProject.sampleReferences {
            updateGlobalSampleUsage(for: sampleRef.sampleID, projectID: newProject.id, adding: true)
        }
        
        availableProjects.append(newProject)
        saveProject(newProject)
        
        print("📋 Duplicated project: \(originalProject.name) → \(newName)")
    }
    
    func deleteProject(_ projectID: UUID) {
        guard let project = availableProjects.first(where: { $0.id == projectID }) else { return }
        
        // Remove from global sample usage
        for sampleRef in project.sampleReferences {
            updateGlobalSampleUsage(for: sampleRef.sampleID, projectID: projectID, adding: false)
        }
        
        // Remove project file
        let projectURL = projectsDirectory.appendingPathComponent("\(projectID.uuidString).json")
        try? fileManager.removeItem(at: projectURL)
        
        // Remove from memory
        availableProjects.removeAll { $0.id == projectID }
        
        // If this was current project, switch to another
        if currentProject?.id == projectID {
            currentProject = availableProjects.first
            if let newProject = currentProject {
                loadProject(newProject.id)
            }
        }
        
        print("🗑️ Deleted project: \(project.name)")
    }
    
    // MARK: - File Management
    
    private func saveProject(_ project: SoftwaretaktProject) {
        let projectURL = projectsDirectory.appendingPathComponent("\(project.id.uuidString).json")
        
        do {
            let data = try JSONEncoder().encode(project)
            try data.write(to: projectURL)
        } catch {
            lastError = "Failed to save project: \(error.localizedDescription)"
            print("❌ Failed to save project: \(error)")
        }
    }
    
    private func loadAvailableProjects() {
        do {
            let projectFiles = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil)
            
            for projectFile in projectFiles where projectFile.pathExtension == "json" {
                if let project = loadProject(from: projectFile) {
                    availableProjects.append(project)
                }
            }
            
            // Sort by date modified (newest first)
            availableProjects.sort { $0.dateModified > $1.dateModified }
            
        } catch {
            print("❌ Failed to load projects: \(error)")
        }
    }
    
    private func loadProject(from url: URL) -> SoftwaretaktProject? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(SoftwaretaktProject.self, from: data)
        } catch {
            print("❌ Failed to load project from \(url): \(error)")
            return nil
        }
    }
    
    private func loadSampleReference(_ sampleRef: SampleReference, toTrack track: Int) {
        // Try to load the sample from its original path
        let sampleURL = URL(fileURLWithPath: sampleRef.originalPath)
        
        if fileManager.fileExists(atPath: sampleRef.originalPath) {
            let sample = Sample(url: sampleURL)
            audioEngine.loadSample(sample, toTrack: track)
            print("✅ Loaded sample: \(sampleRef.sampleName)")
        } else {
            // Sample is missing - add to missing samples list
            if var project = currentProject {
                project.missingSamples.append(sampleRef)
                currentProject = project
            }
            print("⚠️ Missing sample: \(sampleRef.sampleName) at \(sampleRef.originalPath)")
        }
    }
    
    // MARK: - Global Sample Usage Persistence
    
    private func saveGlobalSampleUsage() {
        let usageURL = projectsDirectory.appendingPathComponent("globalSampleUsage.json")
        
        do {
            let data = try JSONEncoder().encode(globalSampleUsage)
            try data.write(to: usageURL)
        } catch {
            print("❌ Failed to save global sample usage: \(error)")
        }
    }
    
    private func loadGlobalSampleUsage() {
        let usageURL = projectsDirectory.appendingPathComponent("globalSampleUsage.json")
        
        do {
            let data = try Data(contentsOf: usageURL)
            globalSampleUsage = try JSONDecoder().decode([UUID: SampleUsage].self, from: data)
        } catch {
            print("ℹ️ No existing sample usage data found (this is normal for first run)")
            globalSampleUsage = [:]
        }
    }
}

// MARK: - Convenience Extensions

extension SoftwaretaktProject {
    var sampleCount: Int {
        return sampleReferences.count
    }
    
    var missingSampleCount: Int {
        return missingSamples.count
    }
    
    var hasIssues: Bool {
        return !missingSamples.isEmpty
    }
    
    func getSamplesForTrack(_ track: Int) -> [SampleReference] {
        return sampleReferences.filter { $0.trackIndex == track }
    }
}

extension ProjectManager {
    
    // MARK: - Quick Actions
    
    func quickSave() {
        saveCurrentProject()
    }
    
    func getProjectSummary() -> String {
        guard let project = currentProject else { return "No project loaded" }
        
        let sampleCount = project.sampleCount
        let missingCount = project.missingSampleCount
        let tracksInUse = project.trackConfigs.filter { $0.sampleReference != nil }.count
        
        return """
        📊 Project: \(project.name)
        🎵 \(sampleCount) samples, \(tracksInUse) tracks in use
        ⚠️ \(missingCount) missing samples
        🕒 Modified: \(project.dateModified.formatted())
        """
    }
}
