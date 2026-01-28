//
//  AppViewModel.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/27/25.
//

import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        }
    }
    
    init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
    func completeOnboarding() {
        withAnimation {
            hasSeenOnboarding = true
        }
    }
    
    func resetOnboarding() {
        hasSeenOnboarding = false
    }
}
