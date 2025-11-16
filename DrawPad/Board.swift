//
//  Board.swift
//  DigitalDrawPad
//
//  Created by Rajesh on 15/11/25.
//

import Foundation
import Combine // <-- This is the required import

/// Represents a single board, containing a collection of objects.
class Board: ObservableObject, Identifiable, Hashable {
    // 'id' is a constant, so it doesn't need to be published.
    var id = UUID()
    
    // @Published tells SwiftUI to watch these properties for changes.
    @Published var name: String
    @Published var items: [CanvasItem]
    @Published var lastModifiedDate: Date

    init(id: UUID = UUID(), name: String = "Untitled Board", items: [CanvasItem] = [], lastModifiedDate: Date = .now) {
        self.id = id
        self.name = name
        self.items = items
        self.lastModifiedDate = lastModifiedDate
    }

    // Conformance for Identifiable and Hashable
    static func == (lhs: Board, rhs: Board) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
