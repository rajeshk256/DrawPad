//
//  BoardGalleryView.swift
//  DigitalDrawPad
//
//  Created by Rajesh on 16/11/25.
//

import SwiftUI

struct BoardGalleryView: View {
    @State private var boards: [Board] = [
        Board(name: "My First Idea", items: []),
        Board(name: "Project Brainstorm", items: [])
    ]
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 160, maximum: 220))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    // 1. Iterate over 'boards' directly, not '$boards'.
                    ForEach(boards) { board in
                        // 2. Use the value-based NavigationLink.
                        NavigationLink(value: board) {
                            BoardThumbnailView(board: board)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            // 3. Add a navigationDestination modifier to handle navigation.
            .navigationDestination(for: Board.self) { board in
                BoardView(board: board)
            }
            .navigationTitle("Boards")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addBoard) {
                        Label("New Board", systemImage: "plus")
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private func addBoard() {
        withAnimation {
            let newBoard = Board()
            boards.insert(newBoard, at: 0)
        }
    }
}

/// A view that shows a preview of a board in the gallery.
struct BoardThumbnailView: View {
    // 4. Use @ObservedObject so the thumbnail updates when the board changes.
    @ObservedObject var board: Board

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemGroupedBackground))
                
                if board.items.isEmpty {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(Color(.tertiaryLabel))
                } else {
                    Text("\(board.items.count) items")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.separator, lineWidth: 0.5)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(board.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("Edited \(board.lastModifiedDate, style: .relative)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
    }
}
