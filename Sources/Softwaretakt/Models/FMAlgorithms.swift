// 🎹 FM SYNTHESIS MAGIC - Why It Sounds So Incredible

/*
EXAMPLE: "FM Metallic Lead" - Breaking Down the Sound

FUNDAMENTAL FREQUENCY: 440Hz (A4)

OPERATOR 1 (Carrier): 
- Frequency: 440Hz × 2.0 = 880Hz (Octave up)
- Level: 0.8 (Strong output)

OPERATOR 2 (Modulator):
- Frequency: 440Hz × 7.0 = 3080Hz (7th harmonic!)  
- Level: 0.6 (Moderate modulation)
- MODULATING Operator 1

OPERATOR 3 (Modulator):
- Frequency: 440Hz × 3.0 = 1320Hz (3rd harmonic)
- Level: 0.4 (Subtle modulation)
- MODULATING the modulation chain

RESULT: 
- Base tone at 880Hz
- Modulated by 3080Hz (creates sidebands at 880±3080Hz)
- Further modulated by 1320Hz 
- Feedback creates chaotic harmonics
- = METALLIC, CUTTING, AGGRESSIVE LEAD SOUND

This is why FM sounds so "DIGITAL" and "CRYSTALLINE" - 
the sidebands create perfect mathematical relationships 
that don't exist in nature!
*/

import Foundation
import AVFoundation

// MARK: - FM Algorithm Definitions (Opal-Style)
struct FMAlgorithm {
    let id: Int
    let name: String
    let description: String
    let routing: String
    
    static let algorithms: [FMAlgorithm] = [
        // Classic 2-operator algorithms
        FMAlgorithm(id: 1, name: "Classic FM", description: "Simple carrier-modulator", routing: "Op2→Op1→Out"),
        FMAlgorithm(id: 2, name: "Parallel", description: "Two parallel operators", routing: "Op1→Out, Op2→Out"),
        FMAlgorithm(id: 3, name: "Ring Mod", description: "Ring modulation style", routing: "Op1×Op2→Out"),
        FMAlgorithm(id: 4, name: "Bell", description: "Classic bell algorithm", routing: "Op2→Op1→Out"),
        
        // 3-operator algorithms  
        FMAlgorithm(id: 5, name: "Serial 3", description: "Three operators in series", routing: "Op3→Op2→Op1→Out"),
        FMAlgorithm(id: 6, name: "Parallel 3", description: "Three parallel operators", routing: "Op1,Op2,Op3→Out"),
        FMAlgorithm(id: 7, name: "Metal Lead", description: "Aggressive metallic lead", routing: "Op3→Op2→Op1, Op2→Out"),
        FMAlgorithm(id: 8, name: "Brass", description: "Brass-like algorithm", routing: "Op3→Op1, Op2→Op1→Out"),
        
        // 4-operator algorithms
        FMAlgorithm(id: 9, name: "Serial 4", description: "Four operators in series", routing: "Op4→Op3→Op2→Op1→Out"),
        FMAlgorithm(id: 10, name: "Parallel 4", description: "Four parallel operators", routing: "Op1,Op2,Op3,Op4→Out"),
        FMAlgorithm(id: 11, name: "Complex 1", description: "Complex routing pattern", routing: "Op4→Op3→Op1, Op2→Op1→Out"),
        FMAlgorithm(id: 12, name: "Pad", description: "Rich pad algorithm", routing: "Op4→Op2, Op3→Op1, Op2+Op1→Out"),
        
        // Advanced algorithms (13-32)
        FMAlgorithm(id: 13, name: "Feedback 1", description: "Operator 1 feedback", routing: "Op1↻→Op1, Op2→Op1→Out"),
        FMAlgorithm(id: 14, name: "Feedback 2", description: "Operator 2 feedback", routing: "Op2↻→Op2→Op1→Out"),
        FMAlgorithm(id: 15, name: "Double FB", description: "Double feedback", routing: "Op1↻, Op2↻→Op1→Out"),
        FMAlgorithm(id: 16, name: "Chaos", description: "Chaotic feedback", routing: "Op1↻→Op2↻→Op1→Out"),
        
        // More complex algorithms (17-32) - these create the "INSANE" sounds
        FMAlgorithm(id: 17, name: "Metallic 1", description: "Harsh metallic", routing: "Op4→Op3↻→Op2→Op1→Out"),
        FMAlgorithm(id: 18, name: "Metallic 2", description: "Extreme metallic", routing: "Op4↻→Op3→Op2↻→Op1→Out"),
        FMAlgorithm(id: 19, name: "Digital", description: "Digital distortion", routing: "Op4→Op1, Op3→Op2, Op2×Op1→Out"),
        FMAlgorithm(id: 20, name: "Aggressive", description: "Maximum aggression", routing: "Op4↻→Op3→Op1, Op2↻→Op1→Out"),
        
        // Continue with more algorithms...
        FMAlgorithm(id: 21, name: "Bell Harsh", description: "Harsh bell", routing: "Op4→Op3→Op2↻→Op1→Out"),
        FMAlgorithm(id: 22, name: "Lead Cut", description: "Cutting lead", routing: "Op4→Op2, Op3↻→Op1, Op2+Op1→Out"),
        FMAlgorithm(id: 23, name: "Bass Deep", description: "Deep bass", routing: "Op4→Op3→Op1, Op2→Op1↻→Out"),
        FMAlgorithm(id: 24, name: "Pluck", description: "Plucked string", routing: "Op4→Op2↻, Op3→Op1, Op2→Op1→Out"),
        FMAlgorithm(id: 25, name: "Glass", description: "Glass-like", routing: "Op4↻→Op1, Op3→Op2, Op2→Op1→Out"),
        FMAlgorithm(id: 26, name: "Crystal", description: "Crystal clear", routing: "Op4→Op3, Op2↻→Op1, Op3+Op1→Out"),
        FMAlgorithm(id: 27, name: "Sweep", description: "Sweeping sound", routing: "Op4→Op2→Op1, Op3↻→Op2→Out"),
        FMAlgorithm(id: 28, name: "Harmonic", description: "Rich harmonics", routing: "Op4→Op1, Op3→Op2↻, Op1+Op2→Out"),
        FMAlgorithm(id: 29, name: "Noise", description: "Noise-like", routing: "Op4↻→Op3↻→Op2→Op1→Out"),
        FMAlgorithm(id: 30, name: "Extreme 1", description: "Extreme modulation", routing: "Op4↻→Op3→Op2↻→Op1↻→Out"),
        FMAlgorithm(id: 31, name: "Extreme 2", description: "Maximum chaos", routing: "Op4→Op3↻→Op2→Op1↻→Out"),
        FMAlgorithm(id: 32, name: "Digital Max", description: "Maximum digital", routing: "Op4↻→Op3↻→Op2↻→Op1↻→Out")
    ]
}

// MARK: - Famous FM Operator Ratios (From DX7, Digitone, Opal)
struct FMOperatorRatio {
    let value: Float
    let name: String
    let character: String
    
    static let famousRatios: [FMOperatorRatio] = [
        // Harmonic ratios (musical intervals)
        FMOperatorRatio(value: 0.5, name: "Sub", character: "Deep, sub-harmonic"),
        FMOperatorRatio(value: 1.0, name: "Fund", character: "Fundamental, warm"),
        FMOperatorRatio(value: 2.0, name: "Octave", character: "Bright, clear"),
        FMOperatorRatio(value: 3.0, name: "Fifth", character: "Hollow, woody"),
        FMOperatorRatio(value: 4.0, name: "2nd Oct", character: "Very bright"),
        FMOperatorRatio(value: 5.0, name: "Maj 3rd", character: "Sweet, bell-like"),
        FMOperatorRatio(value: 7.0, name: "Dom 7th", character: "METALLIC, aggressive"),
        FMOperatorRatio(value: 11.0, name: "11th", character: "Very dissonant"),
        
        // Inharmonic ratios (create chaos and digital artifacts)
        FMOperatorRatio(value: 1.41, name: "√2", character: "Slightly detuned"),
        FMOperatorRatio(value: π, name: "π", character: "Chaotic, digital"),
        FMOperatorRatio(value: 6.28, name: "2π", character: "Extreme chaos"),
        FMOperatorRatio(value: 13.0, name: "13th", character: "INSANE metallic"),
        FMOperatorRatio(value: 16.0, name: "4th Oct", character: "Extreme brightness")
    ]
}

/*
🎹 THE MAGIC COMBINATIONS:

1. METALLIC LEAD (Algorithm 7):
   - Op1: 2.0 (octave up carrier)
   - Op2: 7.0 (dominant 7th modulator) ← THIS IS THE MAGIC!
   - Op3: 3.0 (fifth modulator)
   - Result: CUTTING, AGGRESSIVE, METALLIC

2. BELL (Algorithm 4):
   - Op1: 1.0 (fundamental carrier)  
   - Op2: 3.0 (fifth modulator)
   - Result: CLASSIC FM BELL SOUND

3. CHAOS (Algorithm 32):
   - All operators with feedback
   - Inharmonic ratios (π, √2, etc.)
   - Result: DIGITAL MADNESS

The beauty is that these mathematical relationships create 
sounds that are IMPOSSIBLE to achieve with traditional synthesis!
*/
