import SwiftUI

struct CompletionCelebrationView: View {
    let streak: Int
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.45 : 0)
                .ignoresSafeArea()
                .animation(.easeIn(duration: 0.2), value: appeared)

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .scaleEffect(appeared ? 1.0 : 0.3)

                Text("Adventure Complete")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                if streak > 0 {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(streak)-day streak")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .font(.headline)
                }
            }
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { onDismiss() }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onDismiss()
            }
        }
    }
}
