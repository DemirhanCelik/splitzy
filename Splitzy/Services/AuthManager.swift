//
//  AuthManager.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/27/25.
//

import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore

import CryptoKit
import Security

// MARK: - Helpers
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        var randoms = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
        if status != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
        }

        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }

    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.map { String(format: "%02x", $0) }.joined()
}

class AuthManager: NSObject, ObservableObject {
    @Published var userID: String?
    @Published var isAnonymous: Bool = true
    @Published var isLoading: Bool = false
    
    // Store nonce for Apple Sign In validation
    fileprivate var currentNonce: String?
    
    override init() {
        super.init()
        // Listen to auth state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.userID = user?.uid
                self?.isAnonymous = user?.isAnonymous ?? true
            }
        }
    }
    
    func signInAnonymously() {
        isLoading = true
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            if let error = error {
                print("Error signing in anonymously: \(error.localizedDescription)")
                return
            }
            print("Signed in anonymously: \(result?.user.uid ?? "unknown")")
        }
    }
    
    func makeAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        guard
            let nonce = currentNonce,
            let idTokenData = credential.identityToken,
            let idTokenString = String(data: idTokenData, encoding: .utf8)
        else {
            print("Error: Missing nonce or identity token")
            return
        }

        // Use the specific appleCredential method found in the SDK source
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        isLoading = true

        if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
            currentUser.link(with: firebaseCredential) { [weak self] result, error in
                DispatchQueue.main.async { self?.isLoading = false }
                if let error = error {
                    print("Error linking: \(error.localizedDescription)")
                    // Fallback to sign in if link fails (e.g. account exists)
                    self?.signInOnly(credential: firebaseCredential)
                    return
                }
                print("Linked anonymous account to Apple ID: \(result?.user.uid ?? "")")
            }
        } else {
            signInOnly(credential: firebaseCredential)
        }
    }
    
    private func signInOnly(credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            if let error = error {
                print("Error signing in with Apple: \(error.localizedDescription)")
                return
            }
            print("Signed in with Apple: \(result?.user.uid ?? "")")
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
