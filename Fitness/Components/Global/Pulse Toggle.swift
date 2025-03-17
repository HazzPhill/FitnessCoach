import SwiftUI

struct PulseToggle: View {
    // Required properties
    var label: String
    @Binding var isOn: Bool
    var accentColor: Color
    var textColor: Color
    var font: Font
    
    // Animation properties
    @State private var scale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
                checkmarkScale = isOn ? 1 : 0
                
                // Create a pulsing effect
                if isOn {
                    scale = 1.3
                    // Schedule animations in sequence for the pulse effect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            scale = 0.8
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                    scale = 1.0
                                }
                            }
                        }
                    }
                } else {
                    // More subtle animation when turning off
                    scale = 0.8
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            scale = 1.0
                        }
                    }
                }
            }
        }) {
            HStack(spacing: 12) {
                // Custom checkbox
                ZStack {
                    // Background circle
                    Circle()
                        .fill(isOn ? accentColor : Color.gray.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .scaleEffect(scale)
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkmarkScale)
                        .opacity(isOn ? 1 : 0)
                }
                
                // Text label
                Text(label)
                    .font(font)
                    .foregroundColor(textColor)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Initialize the checkmark scale based on the isOn state
            checkmarkScale = isOn ? 1 : 0
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PulseToggle(
            label: "Completed Goal",
            isOn: .constant(true),
            accentColor: .blue,
            textColor: .primary,
            font: .body
        )
        
        PulseToggle(
            label: "Not Completed Goal",
            isOn: .constant(false),
            accentColor: .blue,
            textColor: .primary,
            font: .body
        )
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
