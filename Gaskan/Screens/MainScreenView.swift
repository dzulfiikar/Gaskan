//
//  MainScreenView.swift
//  Gaskan
//
//  Created by Dzulfikar on 31/03/23.
//
//  This MainScreenView will be used as `EntryPoint` of our app.

import SwiftUI

struct MainScreenView: View {
    @State private var path: NavigationPath = .init()
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @State var isShowDashboard = false
    @EnvironmentObject var locationDataManager: LocationDataManager
    
    var body: some View {
        NavigationStack(path: $path) {
            if isFirstLaunch && !isShowDashboard {
                OnboardingView(onFinish: {
                    withAnimation {
                        isFirstLaunch = false
                        isShowDashboard = true
                    }
                })
            } else {
                DashboardView(path: $path)
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                    .environmentObject(locationDataManager)
                    .environmentObject(DashboardViewModel.shared)
            }
        }
    }
}

struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(LocationDataManager.shared)
    }
}
