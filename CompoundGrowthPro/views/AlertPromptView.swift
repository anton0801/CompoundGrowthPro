import SwiftUI

struct AlertPromptView: View {
    @ObservedObject var engine: RuntimeEngine
    @State private var pulse = false
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                Image("main_push_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(0.7)
                
                VStack(spacing: 12) {
                    Spacer()
                    
                    Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .multilineTextAlignment(.center)
                    
                    Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .multilineTextAlignment(.center)
                    
                    actionControls
                }
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        
    }
    
    private var messageContent: some View {
        VStack(spacing: 30) {
            Text("Stay Balanced").font(.largeTitle.bold())
            Text("Enable alerts to receive growth insights and balance reminders")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 68)
        }
    }
    
    @State var animateButton = false
    
    private var actionControls: some View {
        VStack(spacing: 30) {
            Button {
                engine.approveAlerts()
            } label: {
                Text("Yes, I Want Bonuses!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.red)
                    .cornerRadius(28)
                    .scaleEffect(animateButton ? 1.1 : 1.0)
            }
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animateButton)
            .onAppear {
                animateButton = true
            }
            
            Button { engine.postponeAlerts() } label: {
                Text("Skip")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 60)
    }
}

#Preview {
    AlertPromptView(engine: RuntimeEngine())
}
