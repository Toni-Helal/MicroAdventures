//
//  ContentView.swift
//  MicroAdventures
//
//  Created by Antoun Helal on 05/02/2026.
//

import SwiftUI
import MapKit
internal import Combine

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ContentViewModel
    @StateObject private var userLocationManager = UserLocationManager()

    @State private var didApplyUserLocation = false
    @State private var pendingCenterOnUser = false
    @State private var cameraPosition: MapCameraPosition

    private let timeTicker = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    private let topSectionHeightFactor: CGFloat = 0.33

    init() {
        let model = ContentViewModel()
        _viewModel = StateObject(wrappedValue: model)

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
            .onReceive(timeTicker) { date in
                viewModel.refreshTime(date)
            }
            .onChange(of: viewModel.currentAdventureID) { _ in
                if let adventure = viewModel.currentAdventure {
                    focusOn(adventure)
                }
            }
            .sheet(isPresented: $viewModel.showingFilters) {
                AdventureFiltersView(
                    selectedCategories: $viewModel.selectedCategories,
                    selectedEfforts: $viewModel.selectedEfforts,
                    selectedEnergy: $viewModel.selectedEnergy,
                    selectedWeather: $viewModel.selectedWeather,
                    selectedDuration: $viewModel.selectedDuration,
                    timeBucket: viewModel.timeBucket,
                    onClose: viewModel.hideFilters
                )
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
                onCenterMap: centerMapOnUser,
                onOpenFilters: viewModel.showFilters
            )

            if let adventure = viewModel.currentAdventure {
                AdventureCardView(
                    adventure: adventure,
                    whyText: viewModel.whyThisText(for: adventure),
                    style: cardStyle,
                    onToggleCompleted: {
                        viewModel.toggleCompleted(for: adventure)
                    }
                )
                .padding(.horizontal)
                .padding(.top, 34)
            } else {
                NoPickCardView(
                    cardBackground: cardStyle.cardBackground,
                    onResetFilters: {
                        viewModel.resetFilters()
                    }
                )
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

        guard let userCoordinate = userLocationManager.coordinate else { return }
        didApplyUserLocation = true
        pendingCenterOnUser = false
        setCameraOnUser(userCoordinate)
    }

    private func handleUserLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
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
}

#Preview {
    ContentView()
}
