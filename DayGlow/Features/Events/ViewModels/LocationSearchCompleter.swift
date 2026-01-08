//
//  LocationSearchCompleter.swift
//  DayGlow
//
//  Location search with MapKit autocomplete
//

import Foundation
import MapKit
import Observation

/// Observable location search completer using MapKit
@Observable
@MainActor
final class LocationSearchCompleter: NSObject {
    // MARK: - Properties
    var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                suggestions = []
            } else {
                completer.queryFragment = searchQuery
            }
        }
    }

    var suggestions: [MKLocalSearchCompletion] = []
    var isSearching: Bool = false

    private let completer: MKLocalSearchCompleter

    // MARK: - Initialization
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    // MARK: - Methods

    /// Select a location from suggestions
    func selectLocation(_ completion: MKLocalSearchCompletion) async -> LocationResult? {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)

        do {
            let response = try await search.start()

            guard let mapItem = response.mapItems.first else {
                return nil
            }

            let name = mapItem.name ?? completion.title
            let address = formatAddress(from: mapItem)
            let coordinate = mapItem.placemark.coordinate

            return LocationResult(
                name: name,
                address: address,
                coordinate: coordinate
            )
        } catch {
            print("Error searching for location: \(error)")
            return nil
        }
    }

    /// Format map item into readable address
    private func formatAddress(from mapItem: MKMapItem) -> String {
        var addressComponents: [String] = []
        let placemark = mapItem.placemark

        if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }

        if let locality = placemark.locality {
            addressComponents.append(locality)
        }

        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }

        return addressComponents.joined(separator: ", ")
    }

    /// Clear search
    func clearSearch() {
        searchQuery = ""
        suggestions = []
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchCompleter: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.suggestions = completer.results
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            print("Location search error: \(error.localizedDescription)")
            self.suggestions = []
            self.isSearching = false
        }
    }
}

// MARK: - Location Result

struct LocationResult {
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D

    var fullDescription: String {
        if address.isEmpty {
            return name
        } else {
            return "\(name), \(address)"
        }
    }
}
