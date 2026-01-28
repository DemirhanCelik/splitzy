//
//  ContentView.swift
//  Splitzy
//
//  Created by Demirhan Celik on 12/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some View {
        Group {
            if appViewModel.hasSeenOnboarding {
                HomeView()
            } else {
                OnboardingView(appViewModel: appViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
