//
//  SettingsView.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/28/25.
//

import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.Splitzy.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color.Splitzy.surface)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Settings")
                        .font(.headline)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Profile Card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.vibrantMain)
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 5)
                                    .opacity(0.5)
                                
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.Splitzy.electricTeal))
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            }
                            
                            VStack(spacing: 4) {
                                if authManager.isAnonymous {
                                    Text("Guest User")
                                        .font(.title2.bold())
                                    Text("Sign in to save your data")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Signed In")
                                        .font(.title2.bold())
                                    Text("User ID: \(authManager.userID?.prefix(8) ?? "Unknown")...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if authManager.isAnonymous {
                                SignInWithAppleButton(.signIn) { request in
                                    authManager.makeAppleRequest(request)
                                } onCompletion: { result in
                                    switch result {
                                    case .success(let authResults):
                                        if let credential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                            authManager.signInWithApple(credential: credential)
                                        }
                                    case .failure(let error):
                                        print("Authorization failed: \(error.localizedDescription)")
                                    }
                                }
                                .signInWithAppleButtonStyle(.white)
                                .frame(height: 50)
                                .cornerRadius(12)
                                .padding(.top, 10)
                            } else {
                                Button(action: {
                                    authManager.signOut()
                                }) {
                                    Text("Sign Out")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(12)
                                }
                                .padding(.top, 10)
                            }
                        }
                        .padding(24)
                        .background(Color.Splitzy.surface)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.headline)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                SettingsRow(icon: "info.circle.fill", color: .blue, title: "Version", value: "1.0.0")
                                Divider().padding(.leading, 50)
                                SettingsRow(icon: "lock.shield.fill", color: .green, title: "Privacy Policy", value: nil)
                                    .onTapGesture {
                                        if let url = URL(string: "https://example.com/privacy") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                            }
                            .background(Color.Splitzy.surface)
                            .cornerRadius(16)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding()
    }
}
