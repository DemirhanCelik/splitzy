//
//  OnboardingView.swift
//  Splitzy
//
//  Created by Demirhan Celik on 01/28/26.
//

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @ObservedObject var appViewModel: AppViewModel
    @EnvironmentObject var authManager: AuthManager
    @State private var currentPage = 0
    
    let slides: [(icon: String, color: Color, title: String, subtitle: String)] = [
        ("fork.knife", .orange, "Split by Items", "Assign specific items to friends.\nEveryone pays only for what they ordered."),
        ("percent", .green, "Smart Tax & Tip", "Tax and tip are split proportionally.\nNo more unfair calculations."),
        ("paperplane.fill", .cyan, "Share Instantly", "Send a link so friends can see\nexactly what they owe.")
    ]
    
    var body: some View {
        ZStack {
            // Premium animated background
            AnimatedMeshBackground()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < 2 {
                        Button("Skip") {
                            withAnimation(.spring()) {
                                currentPage = 2
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                    }
                }
                
                // Swipeable content area
                TabView(selection: $currentPage) {
                    ForEach(0..<3) { index in
                        OnboardingSlideContent(slide: slides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Page indicators
                HStack(spacing: 10) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Actions
                VStack(spacing: 16) {
                    if currentPage == 2 {
                        SignInWithAppleButton(.signIn) { request in
                            authManager.makeAppleRequest(request)
                        } onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                if let credential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                    authManager.signInWithApple(credential: credential)
                                    appViewModel.completeOnboarding()
                                }
                            case .failure(let error):
                                print("Authorization failed: \(error.localizedDescription)")
                            }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Button(action: {
                            authManager.signInAnonymously()
                            appViewModel.completeOnboarding()
                        }) {
                            Text("Continue as Guest")
                                .font(.subheadline.bold())
                                .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                currentPage += 1
                            }
                        }) {
                            Text("Continue")
                                .font(.headline.bold())
                                .foregroundColor(Color.Splitzy.vibrantPurple)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Slide Content
struct OnboardingSlideContent: View {
    let slide: (icon: String, color: Color, title: String, subtitle: String)
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero illustration
            ZStack {
                // Floating orbs (static per slide to avoid randomness issues)
                Circle()
                    .fill(slide.color.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                    .offset(x: -80, y: -40)
                
                Circle()
                    .fill(Color.Splitzy.electricTeal.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .blur(radius: 25)
                    .offset(x: 90, y: 30)
                
                // Main icon with glow
                ZStack {
                    Circle()
                        .fill(slide.color.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)
                    
                    Image(systemName: slide.icon)
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, slide.color], startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: slide.color.opacity(0.5), radius: 20, x: 0, y: 10)
                }
            }
            .frame(height: 250)
            
            // Text content
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(slide.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Animated Mesh Background
struct AnimatedMeshBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x1a1a2e),
                    Color(hex: 0x16213e),
                    Color.Splitzy.vibrantPurple.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Circle()
                .fill(Color.Splitzy.vibrantPurple.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: animate ? -50 : 50, y: animate ? -100 : -150)
            
            Circle()
                .fill(Color.Splitzy.electricTeal.opacity(0.3))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: animate ? 80 : -80, y: animate ? 200 : 150)
            
            Circle()
                .fill(Color.pink.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: animate ? -100 : 100, y: animate ? 50 : 100)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
