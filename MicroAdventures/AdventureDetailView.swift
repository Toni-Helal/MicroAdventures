import SwiftUI
import MapKit

struct AdventureDetailView: View {
    let adventure: Adventure

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var mapPosition: MapCameraPosition

    init(adventure: Adventure) {
        self.adventure = adventure
        _mapPosition = State(initialValue: .region(Self.region(for: adventure)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(adventure.title)
                        .font(.title3.bold())

                    Text(adventure.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    mapSection

                    VStack(alignment: .leading, spacing: 10) {
                        detailRow(label: "Estimated duration", value: "\(adventure.estimatedDurationMinutes) min")
                        detailRow(label: "Estimated distance", value: distanceLabel)
                        detailRow(label: "Effort", value: adventure.effort.rawValue)
                        detailRow(label: "Start point", value: adventure.startName)
                        detailRow(label: "End point", value: adventure.endName)
                    }
                    .padding(14)
                    .background(AppColor.chipBackground, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                    actionSection

                    if !adventure.highlights.isEmpty {
                        detailListSection(title: "Highlights", items: adventure.highlights)
                    }

                    if !adventure.tips.isEmpty {
                        detailListSection(title: "Quick tips", items: adventure.tips)
                    }
                }
                .padding()
            }
            .navigationTitle("Adventure Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var mapSection: some View {
        Map(position: $mapPosition) {
            if adventure.hasDistinctEndpoints {
                Annotation("Start", coordinate: adventure.startCoordinate) {
                    detailMarker(title: "Start", color: .green)
                }

                Annotation("End", coordinate: adventure.endCoordinate) {
                    detailMarker(title: "End", color: .red)
                }

                MapPolyline(coordinates: [adventure.startCoordinate, adventure.endCoordinate])
                    .stroke(.blue.opacity(0.75), style: StrokeStyle(lineWidth: 3, dash: [8, 5]))
            } else {
                Annotation("Start / End", coordinate: adventure.startCoordinate) {
                    detailMarker(title: "Start / End", color: .blue)
                }
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var distanceLabel: String {
        String(format: "%.1f km", adventure.estimatedDistanceKm)
    }

    private var actionSection: some View {
        VStack(spacing: 10) {
            Button {
                startAdventure()
            } label: {
                Text("Start Adventure")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Button {
                openAdventureInMaps()
            } label: {
                Label("Open in Maps", systemImage: "map")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
    }

    private func startAdventure() {
        guard let url = startAdventureURL else { return }
        openURL(url)
    }

    private func openAdventureInMaps() {
        guard let url = openInMapsURL else { return }
        openURL(url)
    }

    private var startAdventureURL: URL? {
        var components = URLComponents(string: "http://maps.apple.com/")
        var queryItems = [URLQueryItem(name: "dirflg", value: "w")]

        if adventure.hasDistinctEndpoints {
            queryItems.append(URLQueryItem(
                name: "saddr",
                value: "\(adventure.startLatitude),\(adventure.startLongitude)"
            ))
            queryItems.append(URLQueryItem(
                name: "daddr",
                value: "\(adventure.endLatitude),\(adventure.endLongitude)"
            ))
        } else {
            queryItems.append(URLQueryItem(
                name: "daddr",
                value: "\(adventure.startLatitude),\(adventure.startLongitude)"
            ))
        }

        components?.queryItems = queryItems
        return components?.url
    }

    private var openInMapsURL: URL? {
        var components = URLComponents(string: "http://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(adventure.startLatitude),\(adventure.startLongitude)"),
            URLQueryItem(name: "q", value: adventure.startName)
        ]
        return components?.url
    }

    @ViewBuilder
    private func detailMarker(title: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(.white, lineWidth: 2))
            Text(title)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private func detailListSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private static func region(for adventure: Adventure) -> MKCoordinateRegion {
        let start = adventure.startCoordinate
        let end = adventure.endCoordinate

        if adventure.hasDistinctEndpoints {
            let center = CLLocationCoordinate2D(
                latitude: (start.latitude + end.latitude) / 2,
                longitude: (start.longitude + end.longitude) / 2
            )
            let latitudeDelta = max(abs(start.latitude - end.latitude) * 2.4, 0.01)
            let longitudeDelta = max(abs(start.longitude - end.longitude) * 2.4, 0.01)
            return MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            )
        }

        return MKCoordinateRegion(
            center: start,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}
