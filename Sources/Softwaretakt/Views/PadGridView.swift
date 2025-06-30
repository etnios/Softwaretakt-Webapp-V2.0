import SwiftUI

struct PadGridView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    let selectedTrack: Int
    @State private var padStates: [Bool] = Array(repeating: false, count: 64)
    
    // 8x8 grid layout
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Pad Grid - Track \(selectedTrack + 1)")
                .font(.title2)
                .foregroundColor(.white)
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<64, id: \.self) { index in
                    PadButton(
                        index: index,
                        isActive: padStates[index],
                        onTap: { 
                            triggerPad(index: index)
                        },
                        onPress: { pressed in
                            padStates[index] = pressed
                        }
                    )
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    private func triggerPad(index: Int) {
        // Trigger sample on the selected track
        audioEngine.triggerSample(track: selectedTrack, padIndex: index)
        
        // Visual feedback
        withAnimation(.easeInOut(duration: 0.1)) {
            padStates[index] = true
        }
        
        // Reset visual state after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                padStates[index] = false
            }
        }
    }
}

struct PadButton: View {
    let index: Int
    let isActive: Bool
    let onTap: () -> Void
    let onPress: (Bool) -> Void
    
    @State private var isPressed: Bool = false
    
    // Color coding for different pad sections
    private var padColor: Color {
        switch index {
        case 0..<16:
            return .cyan  // Main triggers
        case 16..<32:
            return .purple  // Slice points
        case 32..<48:
            return .orange  // Hot cues
        case 48..<64:
            return .green  // Effects/rolls
        default:
            return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive || isPressed ? padColor : Color.gray.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(padColor, lineWidth: isActive ? 3 : 1)
                    )
                
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isActive || isPressed ? .black : .white)
            }
        }
        .frame(width: 60, height: 60)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
                onPress(pressing)
            }
        }, perform: {})
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    onTap()
                }
        )
    }
}

#Preview {
    PadGridView(selectedTrack: 0)
        .environmentObject(AudioEngine())
        .background(Color.black)
}
