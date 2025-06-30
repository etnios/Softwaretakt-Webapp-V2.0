import Foundation
import SwiftUI

// Import Step model explicitly by filename to avoid ambiguity

class Pattern: ObservableObject, Codable, Identifiable, Equatable {
    let id = UUID()
    @Published var name: String = "Pattern"
    @Published var steps: [Step]
    @Published var parameterLocks: [Int: [ParameterLockType: Float]]
    
    // Pattern properties
    var length: Int { return steps.count }
    var patternLength: Int { 
        get { return steps.count }
        set { 
            if newValue != steps.count {
                if newValue > steps.count {
                    // Add new steps
                    while steps.count < newValue {
                        steps.append(Step())
                    }
                } else {
                    // Remove steps
                    steps = Array(steps.prefix(newValue))
                    // Clean up parameter locks for removed steps
                    parameterLocks = parameterLocks.filter { $0.key < newValue }
                }
            }
        }
    }
    var activeStepCount: Int { return steps.filter { $0.isActive }.count }
    
    init(length: Int = 16, name: String = "Pattern") {
        self.name = name
        self.steps = (0..<length).map { _ in Step() }
        self.parameterLocks = [:]
    }
    
    // MARK: - Codable support
    private enum CodingKeys: String, CodingKey {
        case name, steps, parameterLocks
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        steps = try container.decode([Step].self, forKey: .steps)
        parameterLocks = try container.decode([Int: [ParameterLockType: Float]].self, forKey: .parameterLocks)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(steps, forKey: .steps)
        try container.encode(parameterLocks, forKey: .parameterLocks)
    }
    
    // MARK: - Equatable
    static func == (lhs: Pattern, rhs: Pattern) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Step Management
    
    func setStep(_ step: Int, active: Bool) {
        guard step >= 0 && step < steps.count else { return }
        steps[step].isActive = active
    }
    
    func toggleStep(_ step: Int) {
        guard step >= 0 && step < steps.count else { return }
        steps[step].isActive.toggle()
    }
    
    func clear() {
        for i in 0..<steps.count {
            steps[i].isActive = false
        }
        parameterLocks.removeAll()
    }
    
    func fill() {
        for i in 0..<steps.count {
            steps[i].isActive = true
        }
    }
    
    func randomize(density: Float = 0.5) {
        for i in 0..<steps.count {
            steps[i].isActive = Float.random(in: 0...1) < density
        }
    }
    
    // MARK: - Pattern Operations
    
    func shift(by positions: Int) {
        let normalizedShift = positions % steps.count
        if normalizedShift == 0 { return }
        
        if normalizedShift > 0 {
            // Shift right
            let shifted = Array(steps.suffix(normalizedShift)) + Array(steps.prefix(steps.count - normalizedShift))
            steps = shifted
        } else {
            // Shift left
            let shifted = Array(steps.suffix(steps.count + normalizedShift)) + Array(steps.prefix(-normalizedShift))
            steps = shifted
        }
        
        // Shift parameter locks too
        shiftParameterLocks(by: normalizedShift)
    }
    
    func reverse() {
        steps.reverse()
        
        // Reverse parameter locks
        let reversedLocks = parameterLocks.reduce(into: [Int: [ParameterLockType: Float]]()) { result, element in
            let reversedStep = steps.count - 1 - element.key
            result[reversedStep] = element.value
        }
        parameterLocks = reversedLocks
    }
    
    func invert() {
        for i in 0..<steps.count {
            steps[i].isActive.toggle()
        }
    }
    
    // MARK: - Parameter Locks
    
    func setParameterLock(step: Int, parameter: ParameterLockType, value: Float) {
        guard step >= 0 && step < steps.count else { return }
        
        if parameterLocks[step] == nil {
            parameterLocks[step] = [:]
        }
        parameterLocks[step]?[parameter] = value
    }
    
    func removeParameterLock(step: Int, parameter: ParameterLockType) {
        parameterLocks[step]?[parameter] = nil
        
        // Clean up empty parameter lock dictionaries
        if parameterLocks[step]?.isEmpty == true {
            parameterLocks[step] = nil
        }
    }
    
    func clearParameterLocks(step: Int) {
        parameterLocks[step] = nil
    }
    
    func clearAllParameterLocks() {
        parameterLocks.removeAll()
    }
    
    func getParameterLock(step: Int, parameter: ParameterLockType) -> Float? {
        return parameterLocks[step]?[parameter]
    }
    
    // MARK: - Step Parameter Methods
    
    func setStepVelocity(_ step: Int, velocity: Float) {
        guard step >= 0 && step < steps.count else { return }
        steps[step].velocity = max(0.0, min(1.0, velocity))
    }
    
    func setRetrig(_ step: Int, settings: RetrigSettings?) {
        guard step >= 0 && step < steps.count else { return }
        steps[step].retrig = settings
    }
    
    func setMicrotiming(_ step: Int, timing: Float) {
        guard step >= 0 && step < steps.count else { return }
        steps[step].microtiming = max(-23.0, min(23.0, timing))
    }
    
    func setStepCondition(_ step: Int, condition: TrigCondition) {
        guard step >= 0 && step < steps.count else { return }
        steps[step].condition = condition
    }
    
    func setStepProbability(_ step: Int, probability: Float) {
        guard step >= 0 && step < steps.count else { return }
        steps[step].probability = max(0.0, min(1.0, probability))
    }
    
    func addParameterLock(_ step: Int, parameter: ParameterLock.LockableParameter, value: Float) {
        guard step >= 0 && step < steps.count else { return }
        
        let lock = ParameterLock(parameter: parameter, value: value, stepIndex: step)
        steps[step].parameterLocks.removeAll { $0.parameter == parameter }
        steps[step].parameterLocks.append(lock)
    }
    
    // MARK: - Pattern Properties for View Compatibility
    
    var hasParameterLocks: (Int) -> Bool {
        return { step in
            guard step >= 0 && step < self.steps.count else { return false }
            return !self.steps[step].parameterLocks.isEmpty
        }
    }
    
    private func shiftParameterLocks(by positions: Int) {
        let normalizedShift = positions % steps.count
        if normalizedShift == 0 { return }
        
        let shiftedLocks = parameterLocks.reduce(into: [Int: [ParameterLockType: Float]]()) { result, element in
            let newStep = (element.key + normalizedShift) % steps.count
            result[newStep] = element.value
        }
        parameterLocks = shiftedLocks
    }
    
    // MARK: - Pattern Generation
    
    func generateEuclidean(hits: Int, steps: Int) {
        guard hits <= steps && hits > 0 && steps > 0 else { return }
        
        // Resize pattern if needed
        if self.steps.count != steps {
            self.steps = (0..<steps).map { _ in Step() }
            clearAllParameterLocks()
        }
        
        // Generate Euclidean rhythm
        var bucket = 0
        
        for i in 0..<steps {
            bucket += hits
            if bucket >= steps {
                bucket -= steps
                self.steps[i].isActive = true
            } else {
                self.steps[i].isActive = false
            }
        }
    }
    
    // MARK: - Copy/Paste
    
    func copy() -> Pattern {
        let copy = Pattern(length: self.length)
        copy.steps = self.steps
        copy.parameterLocks = self.parameterLocks
        return copy
    }
    
    func paste(from pattern: Pattern) {
        // Adjust length if necessary
        if pattern.length != self.length {
            let minLength = min(pattern.length, self.length)
            for i in 0..<minLength {
                self.steps[i] = pattern.steps[i]
            }
        } else {
            self.steps = pattern.steps
        }
        
        // Copy parameter locks
        self.parameterLocks = pattern.parameterLocks
    }
}

// Pattern presets
extension Pattern {
    static func fourOnTheFloor() -> Pattern {
        let pattern = Pattern()
        pattern.setStep(0, active: true)
        pattern.setStep(4, active: true)
        pattern.setStep(8, active: true)
        pattern.setStep(12, active: true)
        return pattern
    }
    
    static func breakbeat() -> Pattern {
        let pattern = Pattern()
        pattern.setStep(0, active: true)
        pattern.setStep(2, active: true)
        pattern.setStep(6, active: true)
        pattern.setStep(10, active: true)
        pattern.setStep(14, active: true)
        return pattern
    }
    
    static func offbeat() -> Pattern {
        let pattern = Pattern()
        pattern.setStep(2, active: true)
        pattern.setStep(6, active: true)
        pattern.setStep(10, active: true)
        pattern.setStep(14, active: true)
        return pattern
    }
    
    static func shaker() -> Pattern {
        let pattern = Pattern()
        for i in stride(from: 1, to: 16, by: 2) {
            pattern.setStep(i, active: true)
        }
        return pattern
    }
}
