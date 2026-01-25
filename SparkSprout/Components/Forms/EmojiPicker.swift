//
//  EmojiPicker.swift
//  SparkSprout
//
//  Emoji picker for mood selection in highlights
//

import SwiftUI

struct EmojiPicker: View {
    @Binding var selectedEmoji: String?
    let emojis: [String]
    var columns: Int = 5

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(emojis, id: \.self) { emoji in
                Button(action: {
                    if selectedEmoji == emoji {
                        selectedEmoji = nil // Deselect if tapped again
                    } else {
                        selectedEmoji = emoji
                    }
                }) {
                    Text(emoji)
                        .font(.system(size: 32))
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.clear)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    selectedEmoji == emoji ? Color.blue : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preset Emoji Collections
extension EmojiPicker {
    static let moodEmojis = [
        "🤩", "😊", "🙂", "😐", "😔",
        "😰", "🎉", "🙏", "💪", "😌",
        "❤️", "🌟", "✨", "🌈", "☀️"
    ]

    static let activityEmojis = [
        "🏃", "🎨", "📚", "🍳", "🎵",
        "✈️", "🎮", "🧘", "🏋️", "🚴"
    ]

    static let allEmojis = moodEmojis + activityEmojis
}

// MARK: - Preview
#Preview("Mood Emojis") {
    @Previewable @State var selectedEmoji: String? = "😊"

    VStack {
        Text("Selected: \(selectedEmoji ?? "None")")
            .font(.title)
            .padding()

        EmojiPicker(
            selectedEmoji: $selectedEmoji,
            emojis: EmojiPicker.moodEmojis
        )
        .padding()
    }
}

#Preview("All Emojis") {
    @Previewable @State var selectedEmoji: String? = nil

    EmojiPicker(
        selectedEmoji: $selectedEmoji,
        emojis: EmojiPicker.allEmojis,
        columns: 6
    )
    .padding()
}
