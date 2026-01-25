//
//  LocationSearchField.swift
//  SparkSprout
//
//  Searchable location field with autocomplete suggestions
//

import SwiftUI
import MapKit

struct LocationSearchField: View {
    @Binding var location: String

    @State private var searchCompleter = LocationSearchCompleter()
    @State private var showingSuggestions = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "location")
                    .foregroundStyle(Theme.Colors.textSecondary)

                TextField("Search for a place...", text: $searchCompleter.searchQuery)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .onChange(of: searchCompleter.searchQuery) { _, newValue in
                        showingSuggestions = !newValue.isEmpty && !searchCompleter.suggestions.isEmpty
                    }
                    .onChange(of: searchCompleter.suggestions) { _, _ in
                        showingSuggestions = !searchCompleter.searchQuery.isEmpty && !searchCompleter.suggestions.isEmpty
                    }

                if !searchCompleter.searchQuery.isEmpty {
                    Button(action: {
                        searchCompleter.clearSearch()
                        location = ""
                        showingSuggestions = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Suggestions list
            if showingSuggestions {
                Divider()
                    .padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(searchCompleter.suggestions, id: \.self) { suggestion in
                            Button(action: {
                                Task {
                                    await selectLocation(suggestion)
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(suggestion.title)
                                        .font(Theme.Typography.body)
                                        .foregroundStyle(Theme.Colors.textPrimary)

                                    if !suggestion.subtitle.isEmpty {
                                        Text(suggestion.subtitle)
                                            .font(Theme.Typography.caption)
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if suggestion != searchCompleter.suggestions.last {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }

            // Current selected location (if any)
            if !location.isEmpty && searchCompleter.searchQuery.isEmpty {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)

                    Text(location)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Spacer()

                    Button(action: {
                        location = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            // Populate search query with existing location if available
            if !location.isEmpty && searchCompleter.searchQuery.isEmpty {
                // Don't auto-populate to avoid triggering search
            }
        }
    }

    // MARK: - Methods

    private func selectLocation(_ suggestion: MKLocalSearchCompletion) async {
        if let result = await searchCompleter.selectLocation(suggestion) {
            location = result.fullDescription
            searchCompleter.clearSearch()
            showingSuggestions = false
            isFocused = false
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var location = ""

    Form {
        Section("Location") {
            LocationSearchField(location: $location)
        }
    }
}

#Preview("With Location") {
    @Previewable @State var location = "Apple Park, Cupertino, CA"

    Form {
        Section("Location") {
            LocationSearchField(location: $location)
        }
    }
}
