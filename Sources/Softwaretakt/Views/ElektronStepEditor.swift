import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// 🎛️ ELEKTRON-STYLE STEP EDITOR - The Creative Heart!

// MARK: - Helper Functions
private func hapticFeedback(style: HapticStyle = .medium) {
    #if canImport(UIKit)
    let impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = {
        switch style {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        }
    }()
    let impactFeedback = UIImpactFeedbackGenerator(style: impactStyle)
    
    #endif
}

private enum HapticStyle {
    case light, medium, heavy
}

struct ElektronStepEditor: View {
    @ObservedObject var pattern: Pattern
    @State private var selectedStep: Int = 0
    @State private var editMode: EditMode = .steps
    @State private var showParameterLocks = true
    @State private var currentPage: Int = 0
    
    let trackIndex: Int
    let stepsPerPage = 16
    
    enum EditMode: String, CaseIterable {
        case steps = "STEPS"
        case velocity = "VEL"
        case microtiming = "μTIME"
        case probability = "PROB"
        case conditions = "COND"
        case locks = "LOCKS"
        
        var color: Color {
            switch self {
            case .steps: return .blue
            case .velocity: return .green
            case .microtiming: return .orange
            case .probability: return .purple
            case .conditions: return .yellow
            case .locks: return .red
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Pattern info header
            patternHeader
            
            // Edit mode selector
            editModeSelector
            
            // Step grid
            stepGrid
            
            // Selected step details
            if selectedStep < pattern.steps.count {
                selectedStepEditor
            }
            
            // Pattern controls
            patternControls
        }
        .background(Color.black)
        .foregroundColor(.white)
    }
    
    // MARK: - Pattern Header
    
    private var patternHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.name)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1, x: 0, y: 1)
                
                HStack(spacing: 16) {
                    // Step count with visual indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        Text("\(pattern.activeStepCount)/\(pattern.patternLength)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    // Feature indicators with better styling
                    if pattern.steps.contains(where: { !$0.parameterLocks.isEmpty }) {
                        HStack(spacing: 2) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                            Text("LOCKS")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red.opacity(0.2))
                        )
                    }
                    
                    if pattern.steps.contains(where: { $0.retrig != nil }) {
                        HStack(spacing: 2) {
                            Image(systemName: "repeat")
                                .font(.system(size: 8))
                            Text("RETRIG")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange.opacity(0.2))
                        )
                    }
                    
                    if pattern.steps.contains(where: { $0.condition != .none }) {
                        HStack(spacing: 2) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 8))
                            Text("COND")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.yellow.opacity(0.2))
                        )
                    }
                }
            }
            
            Spacer()
            
            // Enhanced pattern info
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("LENGTH")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(pattern.patternLength)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("PAGE")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(currentPage + 1)/\(totalPages)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.2),
                    Color.gray.opacity(0.1),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Edit Mode Selector
    
    private var editModeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(EditMode.allCases, id: \.self) { mode in
                    Button(action: { 
                        // Haptic feedback for mode changes
                        hapticFeedback(style: .light)
                        
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            editMode = mode
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(editMode == mode ? .black : .white)
                            
                            // Mode indicator line
                            Rectangle()
                                .fill(mode.color)
                                .frame(width: editMode == mode ? 40 : 0, height: 2)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: editMode)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    editMode == mode ? 
                                    LinearGradient(
                                        gradient: Gradient(colors: [mode.color.opacity(0.9), mode.color.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(
                            color: editMode == mode ? mode.color.opacity(0.4) : .black.opacity(0.2),
                            radius: editMode == mode ? 4 : 2,
                            x: 0,
                            y: 2
                        )
                        .scaleEffect(editMode == mode ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: editMode)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Step Grid
    
    private var stepGrid: some View {
        VStack(spacing: 4) {
            // Page selector if more than 16 steps
            if totalPages > 1 {
                pageSelector
            }
            
            // Main step grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4), spacing: 2) {
                ForEach(currentPageSteps, id: \.self) { stepIndex in
                    stepButton(stepIndex)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func stepButton(_ stepIndex: Int) -> some View {
        let step = pattern.steps[stepIndex]
        let isSelected = stepIndex == selectedStep
        let isActive = step.isActive
        let isBeatMarker = stepIndex % 4 == 0
        
        return Button(action: {
            // Haptic feedback
            hapticFeedback()
            
            if editMode == .steps {
                pattern.toggleStep(stepIndex)
            }
            selectedStep = stepIndex
        }) {
            ZStack {
                // Main button background with gradient
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: stepGradientColors(step, stepIndex, isSelected, isActive)),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: isSelected ? .white.opacity(0.3) : .black.opacity(0.3), 
                           radius: isSelected ? 4 : 2, x: 0, y: 2)
                
                VStack(spacing: 3) {
                    // Step number with better typography
                    Text("\(stepIndex + 1)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(stepNumberColor(step, stepIndex, isSelected, isActive))
                    
                    // Enhanced step indicators
                    stepIndicators(step, stepIndex)
                    
                    // Beat marker indicator
                    if isBeatMarker && !isActive {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 12, height: 1)
                    }
                }
                .padding(4)
                
                // Selection ring with glow effect
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [editMode.color, editMode.color.opacity(0.5)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .shadow(color: editMode.color, radius: 6, x: 0, y: 0)
                }
                
                // Active step pulse animation
                if isActive && !isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue, lineWidth: 1)
                        .opacity(0.8)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isActive)
                }
            }
            .frame(width: 85, height: 65)
        }
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
    
    private func stepIndicators(_ step: Step, _ stepIndex: Int) -> some View {
        VStack(spacing: 2) {
            // Parameter locks indicator with better visual hierarchy
            if !step.parameterLocks.isEmpty {
                HStack(spacing: 1) {
                    ForEach(step.parameterLocks.prefix(4), id: \.id) { lock in
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        parameterLockColor(lock.parameter),
                                        parameterLockColor(lock.parameter).opacity(0.6)
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 3
                                )
                            )
                            .frame(width: 5, height: 5)
                            .shadow(color: parameterLockColor(lock.parameter), radius: 1, x: 0, y: 0)
                    }
                    if step.parameterLocks.count > 4 {
                        Text("+\(step.parameterLocks.count - 4)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 0, y: 1)
                    }
                }
            }
            
            // Enhanced value display based on edit mode
            switch editMode {
            case .steps:
                if step.isActive {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.6)]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 4
                            )
                        )
                        .frame(width: 10, height: 10)
                        .shadow(color: .blue, radius: 2, x: 0, y: 0)
                }
                
            case .velocity:
                let velocityHeight = max(3, CGFloat(step.velocity * 16))
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green,
                                Color.green.opacity(0.7)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: velocityHeight)
                    .shadow(color: .green.opacity(0.5), radius: 1, x: 0, y: 0)
                
            case .microtiming:
                if step.microtiming != 0 {
                    let timingHeight = abs(step.microtiming) * 0.7
                    let timingColor = step.microtiming > 0 ? Color.orange : Color.red
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [timingColor, timingColor.opacity(0.6)]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 3, height: CGFloat(timingHeight))
                        .shadow(color: timingColor.opacity(0.5), radius: 1, x: 0, y: 0)
                }
                
            case .probability:
                if step.probability < 1.0 {
                    let probSize = CGFloat(step.probability * 14)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.6)]),
                                center: .center,
                                startRadius: 0,
                                endRadius: probSize/2
                            )
                        )
                        .frame(width: probSize, height: probSize)
                        .shadow(color: .purple.opacity(0.5), radius: 1, x: 0, y: 0)
                        .overlay(
                            Text("\(Int(step.probability * 100))")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
            case .conditions:
                if step.condition != .none {
                    Text(step.condition.shortName)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(2)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.black.opacity(0.7))
                        )
                        .shadow(color: .yellow.opacity(0.5), radius: 1, x: 0, y: 0)
                }
                
            case .locks:
                if !step.parameterLocks.isEmpty {
                    Text("\(step.parameterLocks.count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [Color.red, Color.red.opacity(0.6)]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 8
                                    )
                                )
                        )
                        .shadow(color: .red.opacity(0.5), radius: 2, x: 0, y: 0)
                }
            }
            
            // Enhanced retrig indicator
            if step.retrig != nil {
                Text("⟲")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.orange)
                    .shadow(color: .black, radius: 1, x: 0, y: 1)
                    .scaleEffect(1.2)
            }
        }
    }
    
    private func stepGradientColors(_ step: Step, _ stepIndex: Int, _ isSelected: Bool, _ isActive: Bool) -> [Color] {
        if isSelected {
            return [editMode.color.opacity(0.9), editMode.color.opacity(0.6)]
        } else if isActive {
            return [Color.blue.opacity(0.8), Color.blue.opacity(0.4)]
        } else if stepIndex % 4 == 0 {
            return [Color.gray.opacity(0.4), Color.gray.opacity(0.2)] // Beat markers
        } else {
            return [Color.gray.opacity(0.15), Color.gray.opacity(0.05)]
        }
    }
    
    private func stepNumberColor(_ step: Step, _ stepIndex: Int, _ isSelected: Bool, _ isActive: Bool) -> Color {
        if isSelected {
            return editMode.color == .yellow ? .black : .white
        } else if isActive {
            return .white
        } else {
            return .gray
        }
    }
    
    private func stepBackgroundColor(_ step: Step, _ stepIndex: Int, _ isSelected: Bool, _ isActive: Bool) -> Color {
        if isSelected {
            return editMode.color
        } else if isActive {
            return Color.blue.opacity(0.6)
        } else if stepIndex % 4 == 0 {
            return Color.gray.opacity(0.3) // Beat markers
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private func parameterLockColor(_ parameter: ParameterLock.LockableParameter) -> Color {
        switch parameter {
        case .sampleStart, .sampleLength, .samplePitch, .sampleReverse:
            return .cyan
        case .fmAlgorithm, .op1Ratio, .op2Ratio, .op1Level, .op2Level, .fmDepth, .feedback:
            return Color(red: 1.0, green: 0.0, blue: 1.0) // Magenta replacement
        case .filterCutoff, .filterResonance:
            return .green
        case .volume, .pan:
            return .blue
        case .attack, .decay, .sustain, .release:
            return .orange
        case .lfoRate, .lfoAmount:
            return .yellow
        }
    }
    
    // MARK: - Selected Step Editor
    
    private var selectedStepEditor: some View {
        VStack(spacing: 8) {
            Text("STEP \(selectedStep + 1)")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 12) {
                    // Basic step parameters
                    stepParameterControls
                    
                    // Parameter locks
                    if editMode == .locks {
                        parameterLocksEditor
                    }
                    
                    // Retrig settings
                    retrigEditor
                }
                .padding()
            }
        }
        .frame(maxHeight: 200)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var stepParameterControls: some View {
        VStack(spacing: 8) {
            // Velocity
            HStack {
                Text("VELOCITY")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Slider(value: Binding(
                    get: { pattern.steps[selectedStep].velocity },
                    set: { pattern.setStepVelocity(selectedStep, velocity: $0) }
                ), in: 0...1)
                .accentColor(.green)
                Text("\(Int(pattern.steps[selectedStep].velocity * 127))")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 30)
            }
            
            // Microtiming
            HStack {
                Text("μTIME")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Slider(value: Binding(
                    get: { pattern.steps[selectedStep].microtiming },
                    set: { pattern.setMicrotiming(selectedStep, timing: $0) }
                ), in: -23...23)
                .accentColor(.orange)
                Text("\(Int(pattern.steps[selectedStep].microtiming))")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 30)
            }
            
            // Probability
            HStack {
                Text("PROB")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Slider(value: Binding(
                    get: { pattern.steps[selectedStep].probability },
                    set: { pattern.setStepProbability(selectedStep, probability: $0) }
                ), in: 0...1)
                .accentColor(.purple)
                Text("\(Int(pattern.steps[selectedStep].probability * 100))%")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 40)
            }
            
            // Condition
            HStack {
                Text("CONDITION")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Picker("Condition", selection: Binding(
                    get: { pattern.steps[selectedStep].condition },
                    set: { pattern.setStepCondition(selectedStep, condition: $0) }
                )) {
                    ForEach(TrigCondition.allCases, id: \.self) { condition in
                        Text(condition.displayName)
                            .tag(condition)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .accentColor(.yellow)
            }
        }
    }
    
    private var parameterLocksEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PARAMETER LOCKS")
                .font(.caption.bold())
                .foregroundColor(.red)
            
            ForEach(pattern.steps[selectedStep].parameterLocks, id: \.id) { lock in
                HStack {
                    Circle()
                        .fill(parameterLockColor(lock.parameter))
                        .frame(width: 8, height: 8)
                    
                    Text(lock.parameter.displayName)
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f", lock.value))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button("✕") {
                        pattern.removeParameterLock(step: selectedStep, parameter: ParameterLockType(rawValue: lock.parameter.rawValue) ?? .volume)
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            // Add parameter lock button
            Menu("+ ADD LOCK") {
                ForEach(ParameterLock.LockableParameter.allCases, id: \.self) { param in
                    Button(param.displayName) {
                        pattern.addParameterLock(selectedStep, parameter: param, value: 0.5)
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.red)
        }
    }
    
    private var retrigEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RETRIG")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { pattern.steps[selectedStep].retrig != nil },
                    set: { enabled in
                        if enabled {
                            pattern.setRetrig(selectedStep, settings: RetrigSettings())
                        } else {
                            pattern.setRetrig(selectedStep, settings: nil)
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle())
            }
            
            if pattern.steps[selectedStep].retrig != nil {
                // Retrig controls would go here
                Text("Retrig controls (Rate, Count, Velocity)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Pattern Controls
    
    private var patternControls: some View {
        VStack(spacing: 12) {
            // Action buttons
            HStack(spacing: 12) {
                PatternActionButton(title: "CLEAR", color: .red, action: {
                    pattern.clear()
                })
                
                PatternActionButton(title: "REVERSE", color: .orange, action: {
                    pattern.reverse()
                })
                
                PatternActionButton(title: "SHIFT", color: .blue, action: {
                    pattern.shift(by: 1)
                })
                
                PatternActionButton(title: "RANDOM", color: .purple, action: {
                    pattern.randomize()
                })
                
                Spacer()
                
                // Pattern length control with enhanced styling
                VStack(spacing: 4) {
                    Text("LENGTH")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Button("-") {
                            if pattern.patternLength > 1 {
                                hapticFeedback(style: .light)
                                
                                pattern.patternLength -= 1
                            }
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        )
                        .disabled(pattern.patternLength <= 1)
                        
                        Text("\(pattern.patternLength)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40)
                        
                        Button("+") {
                            if pattern.patternLength < 64 {
                                hapticFeedback(style: .light)
                                
                                pattern.patternLength += 1
                            }
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        )
                        .disabled(pattern.patternLength >= 64)
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.1),
                    Color.gray.opacity(0.05),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Page Navigation
    
    private var pageSelector: some View {
        HStack(spacing: 12) {
            // Previous page button
            Button(action: {
                if currentPage > 0 {
                    hapticFeedback(style: .light)
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        currentPage -= 1
                        updateSelectedStepForPage()
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(currentPage > 0 ? .blue : .gray)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(currentPage > 0 ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    )
            }
            .disabled(currentPage == 0)
            
            Spacer()
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { page in
                    Button(action: {
                        hapticFeedback(style: .light)
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            currentPage = page
                            updateSelectedStepForPage()
                        }
                    }) {
                        Text("\(page + 1)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(currentPage == page ? .black : .white)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(
                                        currentPage == page ? 
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(
                                color: currentPage == page ? .blue.opacity(0.4) : .black.opacity(0.2),
                                radius: currentPage == page ? 3 : 1,
                                x: 0,
                                y: 1
                            )
                    }
                    .scaleEffect(currentPage == page ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            
            Spacer()
            
            // Next page button
            Button(action: {
                if currentPage < totalPages - 1 {
                    hapticFeedback(style: .light)
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        currentPage += 1
                        updateSelectedStepForPage()
                    }
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(currentPage < totalPages - 1 ? .blue : .gray)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(currentPage < totalPages - 1 ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    )
            }
            .disabled(currentPage == totalPages - 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var totalPages: Int {
        return (pattern.patternLength - 1) / stepsPerPage + 1
    }
    
    private var currentPageSteps: [Int] {
        let startStep = currentPage * stepsPerPage
        let endStep = min(startStep + stepsPerPage, pattern.patternLength)
        return Array(startStep..<endStep)
    }
    
    private func updateSelectedStepForPage() {
        let pageStart = currentPage * stepsPerPage
        if selectedStep < pageStart || selectedStep >= pageStart + stepsPerPage {
            selectedStep = pageStart
        }
    }
}

// MARK: - Pattern Action Button Component

struct PatternActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            hapticFeedback()
            
            action()
        }) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color.opacity(0.8), color.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: false)
    }
}

// MARK: - Preview

struct ElektronStepEditor_Previews: PreviewProvider {
    static var previews: some View {
        let pattern = Pattern(length: 16, name: "Test Pattern")
        pattern.toggleStep(0)
        pattern.toggleStep(4)
        pattern.toggleStep(8)
        pattern.toggleStep(12)
        pattern.addParameterLock(0, parameter: .fmAlgorithm, value: 0.8)
        pattern.addParameterLock(4, parameter: .filterCutoff, value: 0.6)
        
        return ElektronStepEditor(pattern: pattern, trackIndex: 0)
            .preferredColorScheme(.dark)
    }
}
