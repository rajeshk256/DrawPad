//
//  CanvasItem.swift
//  DigitalDrawPad
//
//  Created by Rajesh on 15/11/25.
//

import SwiftUI

// MARK: - Canvas Item Types

/// Represents the type of a freeform object on the canvas.
enum CanvasItemType: Equatable {
    /// A rectangular shape.
    case rectangle
    /// A circular shape.
    case circle
    /// An elliptical shape.
    case ellipse
    /// A line segment.
    case line
    /// A text element, with its string content.
    case text(String)
    /// An image, with its raw data.
    case image(Data)
}

/// Represents a single object on the freeform canvas.
///
/// Each object has a unique identity, type, position, size, and style.
/// It also tracks whether it is currently selected.
struct CanvasItem: Identifiable, Equatable {
    /// Defines the visual styling of a `CanvasItem`.
    struct Style: Equatable {
        /// The fill color of the object. For text, this is the font color.
        var color: Color? = nil
        /// The width of the object's border.
        var borderWidth: CGFloat? = nil
        /// The color of the object's border.
        var borderColor: Color? = nil
        /// The rotation of the object.
        var rotation: Angle = .zero
        /// The opacity of the object, from 0.0 to 1.0.
        var opacity: Double = 1.0
    }
    /// A unique identifier for the object.
    var id = UUID()
    /// The type of the object (e.g., rectangle, text).
    var type: CanvasItemType
    /// The center position of the object on the canvas.
    var position: CGPoint
    /// The size (width and height) of the object.
    var size: CGSize
    /// The visual style of the object.
    var style: Style = Style()
    /// A Boolean value indicating whether the object is currently selected.
    var isSelected: Bool = false
}
