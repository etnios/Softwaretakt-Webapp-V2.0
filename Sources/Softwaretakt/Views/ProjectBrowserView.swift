import SwiftUI

// 🗂️ SOFTWARETAKT PROJECT BROWSER - MODERN PROJECT MANAGEMENT

struct ProjectBrowserView: View {
    @ObservedObject var projectManager: ProjectManager
    @State private var showingNewProjectSheet = false
    @State private var showingProjectInfo = false
    @State private var selectedProject: SoftwaretaktProject?
    @State private var searchText = ""
    @State private var showingSampleUsage = false
    
    var filteredProjects: [SoftwaretaktProject] {
        if searchText.isEmpty {
            return projectManager.availableProjects
        }
        return projectManager.availableProjects.filter { project in
            project.name.localizedCaseInsensitiveContains(searchText) ||
            project.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with current project info
                currentProjectHeader
                
                Divider()
                
                // Project list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredProjects, id: \.id) { project in
                            ProjectCard(
                                project: project,
                                isCurrentProject: project.id == projectManager.currentProject?.id,
                                onLoad: { loadProject(project) },
                                onInfo: { showProjectInfo(project) },
                                onDuplicate: { duplicateProject(project) },
                                onDelete: { deleteProject(project) }
                            )
                        }
                    }
                    .padding()
                }
                .refreshable {
                    // Refresh projects
                }
            }
            .navigationTitle("Projects")
            .searchable(text: $searchText, prompt: "Search projects...")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    
                    Button(action: { showingSampleUsage = true }) {
                        Image(systemName: "chart.bar.fill")
                    }
                    
                    Button(action: { showingNewProjectSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet(projectManager: projectManager)
        }
        .sheet(isPresented: $showingProjectInfo) {
            if let project = selectedProject {
                ProjectInfoSheet(project: project, projectManager: projectManager)
            }
        }
        .sheet(isPresented: $showingSampleUsage) {
            SampleUsageView(projectManager: projectManager)
        }
    }
    
    private var currentProjectHeader: some View {
        VStack(spacing: 8) {
            if let project = projectManager.currentProject {
                HStack {
                    VStack(alignment: .leading) {
                        Text(project.name)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("\(project.sampleCount) samples • \(Int(project.bpm)) BPM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if project.hasIssues {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                    
                    Button("Save") {
                        projectManager.quickSave()
                    }
                    .buttonStyle(.bordered)
                    .disabled(projectManager.isLoading)
                }
            } else {
                Text("No project loaded")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    private func loadProject(_ project: SoftwaretaktProject) {
        projectManager.loadProject(project.id)
    }
    
    private func showProjectInfo(_ project: SoftwaretaktProject) {
        selectedProject = project
        showingProjectInfo = true
    }
    
    private func duplicateProject(_ project: SoftwaretaktProject) {
        let newName = "\(project.name) Copy"
        projectManager.duplicateProject(project.id, newName: newName)
    }
    
    private func deleteProject(_ project: SoftwaretaktProject) {
        projectManager.deleteProject(project.id)
    }
}

// MARK: - Project Card

struct ProjectCard: View {
    let project: SoftwaretaktProject
    let isCurrentProject: Bool
    let onLoad: () -> Void
    let onInfo: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color(project.projectColor))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading) {
                    Text(project.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if isCurrentProject {
                    Text("CURRENT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            // Stats
            HStack(spacing: 16) {
                Label("\(project.sampleCount)", systemImage: "waveform")
                Label("\(Int(project.bpm))", systemImage: "metronome")
                Label(project.key, systemImage: "music.note")
                
                if project.hasIssues {
                    Label("\(project.missingSampleCount)", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Text(project.dateModified, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            
            // Actions
            HStack {
                if !isCurrentProject {
                    Button("Load") {
                        onLoad()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Info") {
                    onInfo()
                }
                .buttonStyle(.bordered)
                
                Button("Duplicate") {
                    onDuplicate()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(isCurrentProject ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentProject ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - New Project Sheet

struct NewProjectSheet: View {
    @ObservedObject var projectManager: ProjectManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName = ""
    @State private var projectDescription = ""
    @State private var projectBPM = 120.0
    @State private var projectKey = "C"
    @State private var projectScale = "Major"
    @State private var projectColor = "blue"
    
    let keys = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    let scales = ["Major", "Minor", "Dorian", "Mixolydian", "Pentatonic"]
    let colors = ["blue", "green", "orange", "purple", "red", "pink"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $projectName)
                    TextField("Description (optional)", text: $projectDescription, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section("Musical Settings") {
                    HStack {
                        Text("BPM")
                        Spacer()
                        Slider(value: $projectBPM, in: 60...200, step: 1) {
                            Text("BPM")
                        } minimumValueLabel: {
                            Text("60")
                        } maximumValueLabel: {
                            Text("200")
                        }
                        Text("\(Int(projectBPM))")
                            .frame(width: 40)
                    }
                    
                    Picker("Key", selection: $projectKey) {
                        ForEach(keys, id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                    
                    Picker("Scale", selection: $projectScale) {
                        ForEach(scales, id: \.self) { scale in
                            Text(scale).tag(scale)
                        }
                    }
                }
                
                Section("Appearance") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(projectColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    projectColor = color
                                }
                        }
                    }
                }
                
                Section {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Create Project") {
                            createProject()
                        }
                        .disabled(projectName.isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("New Project")
        }
    }
    
    private func createProject() {
        projectManager.createNewProject(name: projectName)
        
        // Apply settings to the new project
        if var project = projectManager.currentProject {
            project.description = projectDescription
            project.bpm = projectBPM
            project.key = projectKey
            project.scale = projectScale
            project.projectColor = projectColor
            projectManager.currentProject = project
            projectManager.saveCurrentProject()
        }
        
        dismiss()
    }
}

// MARK: - Project Info Sheet

struct ProjectInfoSheet: View {
    let project: SoftwaretaktProject
    @ObservedObject var projectManager: ProjectManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Project Details") {
                    LabeledContent("Name", value: project.name)
                    if !project.description.isEmpty {
                        LabeledContent("Description", value: project.description)
                    }
                    LabeledContent("Created", value: project.dateCreated.formatted())
                    LabeledContent("Modified", value: project.dateModified.formatted())
                }
                
                Section("Musical Settings") {
                    LabeledContent("BPM", value: "\(Int(project.bpm))")
                    LabeledContent("Key", value: project.key)
                    LabeledContent("Scale", value: project.scale)
                }
                
                Section("Content") {
                    LabeledContent("Samples", value: "\(project.sampleCount)")
                    LabeledContent("Patterns", value: "\(project.patterns.count)")
                    LabeledContent("Sequences", value: "\(project.sequences.count)")
                    
                    if project.hasIssues {
                        LabeledContent("Missing Samples", value: "\(project.missingSampleCount)")
                            .foregroundColor(.orange)
                    }
                }
                
                Section("Sample References") {
                    ForEach(project.sampleReferences, id: \.sampleID) { sampleRef in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(sampleRef.sampleName)
                                    .font(.headline)
                                Text("Track \(sampleRef.trackIndex + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let usage = projectManager.getSampleUsageInfo(for: Sample(url: URL(fileURLWithPath: sampleRef.originalPath))) {
                                Text("\(usage.usedInProjects.count) projects")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Done") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Project Info")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

// MARK: - Sample Usage View

struct SampleUsageView: View {
    @ObservedObject var projectManager: ProjectManager
    @Environment(\.dismiss) private var dismiss
    
    var sortedSamples: [(UUID, SampleUsage)] {
        projectManager.globalSampleUsage.sorted { $0.value.totalUsageCount > $1.value.totalUsageCount }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Sample Usage Statistics") {
                    ForEach(sortedSamples, id: \.0) { sampleID, usage in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(URL(fileURLWithPath: usage.samplePath).lastPathComponent)
                                    .font(.headline)
                                
                                Spacer()
                                
                                if usage.isProtected {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            
                            HStack {
                                Text("Used in \(usage.usedInProjects.count) project(s)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Last used: \(usage.lastUsedDate, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Find Unused Samples") {
                        // Implementation for finding unused samples
                    }
                    
                    Button("Clean Up Missing References") {
                        // Implementation for cleaning up missing sample references
                    }
                }
                
                Section {
                    Button("Done") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Sample Usage")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

// MARK: - Previews

struct ProjectBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectBrowserView(projectManager: ProjectManager(audioEngine: AudioEngine()))
    }
}
