//
//  CanvasItemView.swift
//  DigitalDrawPad
//
//  Created by Rajesh on 15/11/25.
//

import SwiftUI

/// A view that renders a single `CanvasItem` based on its type and style.
struct CanvasItemView: View {
    let item: CanvasItem
    let isSelected: Bool

    var body: some View {
        ZStack {
            // shapeView provides the background color and border for basic shapes,
            // or a placeholder icon for a failed image load.
            shapeView
            
            // Text is rendered as an overlay on top of any shape or background.
            if case let .text(content) = item.type {
                Text(content)
                    .foregroundColor(item.style.color ?? .primary)
                    .padding(8)
                    .frame(width: item.size.width, height: item.size.height, alignment: .center)
            }
        }
        // The overall frame for the object.
        .frame(width: item.size.width, height: item.size.height)
        // For image objects, the image is set as the background.
        // If the image data is invalid, a placeholder color is shown.
        .background(imageBackground)
        // Clip the entire view, including the background image, to a rounded rectangle.
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            // Add a selection highlight if the object is selected.
            isSelected ? RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor, lineWidth: 2)
                .padding(-5) // Padding to draw the border slightly outside the shape
            : nil
        )
        .rotationEffect(item.style.rotation)
        .opacity(item.style.opacity)
        .position(item.position)
    }

    /// A computed property that returns a background view for image objects.
    @ViewBuilder
    private var imageBackground: some View {
        if case let .image(data) = item.type, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill() // Ensures the image covers the entire frame.
        } else if case .image = item.type {
            // If it's an image object but the data is invalid, show a placeholder background.
            Color(.secondarySystemBackground)
        }
    }

    /// A computed property that returns the correct shape view based on the object's type.
    @ViewBuilder
    private var shapeView: some View {
        switch item.type {
        case .rectangle:
            Rectangle()
                .fillWithBorder(
                    fillColor: item.style.color ?? .blue,
                    borderColor: item.style.borderColor ?? .clear,
                    borderWidth: item.style.borderWidth ?? 0
                )
        case .circle:
            Circle()
                .fillWithBorder(
                    fillColor: item.style.color ?? .orange,
                    borderColor: item.style.borderColor ?? .clear,
                    borderWidth: item.style.borderWidth ?? 0
                )
        case .ellipse:
            Ellipse()
                .fillWithBorder(
                    fillColor: item.style.color ?? .purple,
                    borderColor: item.style.borderColor ?? .clear,
                    borderWidth: item.style.borderWidth ?? 0
                )
        case .line:
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: item.size.width, y: 0))
            }
            .stroke(item.style.color ?? .black, lineWidth: item.style.borderWidth ?? 2)
            
        case .text:
            EmptyView()
            
        case .image(let data):
            // If image data is invalid, overlay a placeholder icon.
            if UIImage(data: data) == nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// A helper extension to apply fill and border modifiers to shapes.
private extension Shape {
    @ViewBuilder
    func fillWithBorder(fillColor: Color, borderColor: Color, borderWidth: CGFloat) -> some View {
        self.fill(fillColor)
            .overlay(
                self.stroke(borderColor, lineWidth: borderWidth)
            )
    }
}
