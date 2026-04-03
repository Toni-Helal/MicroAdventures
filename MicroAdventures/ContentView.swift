//
//  ContentView.swift
//  MicroAdventures
//
//  Created by Antoun Helal on 05/02/2026.
//

import SwiftUI
import MapKit
import UIKit
internal import Combine

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ContentViewModel
    @StateObject private var userLocationManager = UserLocationManager()

    @State private var didApplyUserLocation = false
    @State private var displayedAdventureID: UUID?
    @State private var pendingCenterOnUser = false
    @State private var completionCelebration: CompletionCelebrationState?
    @State private var showingLocationAccessAlert = false
    @State private var cameraPosition: MapCameraPosition

    private let timeTicker = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    private let topSectionHeightFactor: CGFloat = 0.33
    private let adventureTransition = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )

    init() {
        let model = ContentViewModel()
        _viewModel = StateObject(wrappedValue: model)
        _displayedAdventureID = State(initialValue: model.currentAdventure?.id)

        let start = model.mapSeedAdventure
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        _cameraPosition = State(initialValue: .region(region))
    }

    private var cardStyle: AdventureCardStyle {
        AdventureCardStyle(
            cardBackground: colorScheme == .dark ? Color.black.opacity(0.65) : Color.white.opacity(0.9),
            chipBackground: colorScheme == .dark ? Color.white.opacity(0.12) : Color.gray.opacity(0.15),
            doneButtonBackground: colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.25),
            doneButtonForeground: colorScheme == .dark ? Color.white.opacity(0.9) : Color.gray.opacity(0.9)
        )
    }

    private var actionIconColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color.gray.opacity(0.85)
    }

    private var pinColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.85) : Color.gray
    }

    var body: some View {
        GeometryReader { proxy in
            let topHeight = proxy.size.height * topSectionHeightFactor

            ZStack(alignment: .top) {
                mapLayer
            }
            .safeAreaInset(edge: .top) {
                overlayContent(topHeight: topHeight)
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            .onAppear {
                userLocationManager.requestPermissionAndLocation()
                viewModel.ensureDailyPick(forceReselect: false)
                if let adventure = viewModel.currentAdventure {
                    focusOn(adventure)
                }
            }
            .onReceive(userLocationManager.$coordinate.compactMap { $0 }) { coordinate in
                handleUserLocationUpdate(coordinate)
            }
            .onReceive(userLocationManager.$authorizationStatus) { status in
                handleAuthorizationStatusUpdate(status)
            }
            .onReceive(timeTicker) { date in
                viewModel.refreshTime(date)
            }
            .onChange(of: viewModel.currentAdventureID) { _, newAdventureID in
                let nextAdventure = resolveAdventure(for: newAdventureID) ?? viewModel.currentAdventure
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayedAdventureID = nextAdventure?.id
                    if let nextAdventure {
                        focusOn(nextAdventure)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingFilters) {
                AdventureFiltersView(
                    selectedCategories: viewModel.selectedCategories,
                    selectedEfforts: viewModel.selectedEfforts,
                    selectedEnergy: viewModel.selectedEnergy,
                    selectedWeather: viewModel.selectedWeather,
                    selectedDuration: viewModel.selectedDuration,
                    timeBucket: viewModel.timeBucket,
                    onCancel: viewModel.hideFilters,
                    onApply: { categories, efforts, energy, weather, duration in
                        viewModel.applyFilters(
                            categories: categories,
                            efforts: efforts,
                            energy: energy,
                            weather: weather,
                            duration: duration
                        )
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        viewModel.hideFilters()
                    }
                )
            }
            .alert("Location access needed", isPresented: $showingLocationAccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Allow location access in Settings to center the map on your position.")
            }
            .overlay(alignment: .bottom) {
                if let completionCelebration {
                    CompletionCelebrationView(
                        currentStreak: completionCelebration.currentStreak,
                        longestStreak: completionCelebration.longestStreak,
                        onDismiss: dismissCompletionCelebration
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    @ViewBuilder
    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            if let adventure = viewModel.currentAdventure {
                Annotation(adventure.locationName, coordinate: adventure.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(pinColor)
                        .shadow(radius: 2)
                }
            }
        }
    }

    @ViewBuilder
    private func overlayContent(topHeight: CGFloat) -> some View {
        VStack(spacing: 1) {
            ContentHeaderView(
                actionColor: actionIconColor,
                activeFilterCount: viewModel.activeFilterCount,
                onCenterMap: centerMapOnUser,
                onOpenFilters: viewModel.showFilters
            )

            if let adventure = displayedAdventure {
                AdventureCardView(
                    adventure: adventure,
                    whyText: viewModel.whyThisText(for: adventure),
                    style: cardStyle,
                    onAnotherPick: {
                        dismissCompletionCelebration()
                        viewModel.rerollTodayPick()
                    },
                    onToggleCompleted: {
                        handleCompletionToggle(for: adventure)
                    }
                )
                .id(adventure.id)
                .transition(adventureTransition)
                .padding(.horizontal)
                .padding(.top, 34)
            } else {
                NoPickCardView(
                    cardBackground: cardStyle.cardBackground,
                    onResetFilters: {
                        viewModel.resetFilters()
                    }
                )
                .id("no-pick")
                .transition(adventureTransition)
                .padding(.horizontal)
                .padding(.top, 34)
            }
        }
        .padding(.top, 98)
        .padding(.bottom, 6)
        .frame(height: topHeight, alignment: .top)
    }

    private func focusOn(_ adventure: Adventure) {
        if let userCoordinate = userLocationManager.coordinate {
            let center = CLLocationCoordinate2D(
                latitude: (userCoordinate.latitude + adventure.latitude) / 2,
                longitude: (userCoordinate.longitude + adventure.longitude) / 2
            )
            let latitudeDelta = max(abs(userCoordinate.latitude - adventure.latitude) * 2.2, 0.02)
            let longitudeDelta = max(abs(userCoordinate.longitude - adventure.longitude) * 2.2, 0.02)
            cameraPosition = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            ))
            return
        }

        cameraPosition = .region(MKCoordinateRegion(
            center: adventure.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }

    private func setCameraOnUser(_ coordinate: CLLocationCoordinate2D) {
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }

    private func centerMapOnUser() {
        pendingCenterOnUser = true
        userLocationManager.requestPermissionAndLocation()

        if userLocationManager.authorizationStatus == .denied || userLocationManager.authorizationStatus == .restricted {
            pendingCenterOnUser = false
            showingLocationAccessAlert = true
            return
        }

        guard let userCoordinate = userLocationManager.coordinate else { return }
        didApplyUserLocation = true
        pendingCenterOnUser = false
        setCameraOnUser(userCoordinate)
    }

    private func handleUserLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
        viewModel.updateUserCoordinate(coordinate)

        if pendingCenterOnUser {
            pendingCenterOnUser = false
            didApplyUserLocation = true
            setCameraOnUser(coordinate)
            return
        }

        if !didApplyUserLocation {
            didApplyUserLocation = true
            if let adventure = viewModel.currentAdventure {
                focusOn(adventure)
            } else {
                setCameraOnUser(coordinate)
            }
        }
    }

    private func handleAuthorizationStatusUpdate(_ status: CLAuthorizationStatus) {
        guard pendingCenterOnUser else { return }

        if status == .denied || status == .restricted {
            pendingCenterOnUser = false
            showingLocationAccessAlert = true
        }
    }

    private var displayedAdventure: Adventure? {
        guard let displayedAdventureID else { return viewModel.currentAdventure }
        return resolveAdventure(for: displayedAdventureID) ?? viewModel.currentAdventure
    }

    private func resolveAdventure(for id: UUID?) -> Adventure? {
        guard let id else { return nil }
        return viewModel.adventures.first(where: { $0.id == id })
    }

    private func handleCompletionToggle(for adventure: Adventure) {
        let isCompleted = viewModel.toggleCompleted(for: adventure)
        guard isCompleted else {
            dismissCompletionCelebration()
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            completionCelebration = CompletionCelebrationState(
                currentStreak: viewModel.currentStreak,
                longestStreak: viewModel.longestStreak
            )
        }
    }

    private func dismissCompletionCelebration() {
        guard completionCelebration != nil else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            completionCelebration = nil
        }
    }
}

private struct CompletionCelebrationState: Identifiable {
    let id = UUID()
    let currentStreak: Int
    let longestStreak: Int
}

#Preview {
    ContentView()
}
