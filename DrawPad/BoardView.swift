//
//  BoardView.swift
//  DigitalDrawPad
//
//  Created by Rajesh on 16/11/25.
//

import SwiftUI
import PhotosUI

struct BoardView: View {
    @ObservedObject var board: Board
    
    // MARK: - State Variables
    @State private var selectedID: UUID?
    @State private var undoStack: [[CanvasItem]] = []
    @State private var redoStack: [[CanvasItem]] = []
    @State private var canvasSize: CGSize = .zero
    @State private var showColorPicker = false
    
    // Photos Picker State
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    
    // Dragging State
    @State private var draggedItemID: UUID?
    @State private var dragOffset: CGSize = .zero
    
    // Resizing State
    @State private var resizingItemID: UUID?
    @State private var resizeStartSize: CGSize = .zero
    @State private var resizeStartPosition: CGPoint = .zero
    
    // Text Editing State
    @State private var editingTextItemID: UUID?
    @State private var editingText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    
    private let predefinedColors: [Color] = [.blue, .green, .yellow, .orange, .red, .purple, .black, .gray, .white]
    
    // Enum to represent the four resize handles
    private enum ResizeHandle: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
        
        var alignment: Alignment {
            switch self {
            case .topLeft: return .topLeading
            case .topRight: return .topTrailing
            case .bottomLeft: return .bottomLeading
            case .bottomRight: return .bottomTrailing
            }
        }
        
        var xMultiplier: CGFloat {
            switch self {
            case .topLeft, .bottomLeft: return -1
            case .topRight, .bottomRight: return 1
            }
        }
        
        var yMultiplier: CGFloat {
            switch self {
            case .topLeft, .topRight: return -1
            case .bottomLeft, .bottomRight: return 1
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        canvasView
            .navigationTitle(board.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                BoardToolbarContent(
                    showPhotoPicker: $showPhotoPicker,
                    selectedPhotoItem: $selectedPhotoItem,
                    undoAction: undo,
                    redoAction: redo,
                    addRectangleAction: addRectangle,
                    addCircleAction: addCircle,
                    addTextAction: addText,
                    deleteAction: deleteSelectedItem,
                    toggleInspectorAction: { showColorPicker.toggle() },
                    isUndoDisabled: undoStack.count <= 1,
                    isRedoDisabled: redoStack.isEmpty,
                    isDeleteDisabled: selectedID == nil,
                    isInspectorDisabled: selectedID == nil
                )
            }
            .onAppear {
                if undoStack.isEmpty {
                    undoStack.append(board.items)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    // Refactored to a separate async function for clarity.
                    await loadImage(from: newItem)
                }
            }
    }
    
    // MARK: - Canvas View
    private var canvasView: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemGroupedBackground)
                .background(GeometryReader { geometry in
                    Color.clear
                        .onAppear { canvasSize = geometry.size }
                        .onChange(of: geometry.size) { _, newSize in canvasSize = newSize }
                })
                .onTapGesture {
                    saveAndEndEditing()
                    selectedID = nil
                    showColorPicker = false
                }
            
            ForEach(board.items) { item in
                let isSelected = selectedID == item.id
                
                if editingTextItemID != item.id {
                    CanvasItemView(item: item, isSelected: isSelected)
                        .offset(draggedItemID == item.id ? dragOffset : .zero)
                        .onTapGesture {
                            saveAndEndEditing()
                            selectedID = item.id
                        }
                        .onTapGesture(count: 2) {
                            if case .text(let currentText) = item.type {
                                editingText = currentText
                                editingTextItemID = item.id
                                isTextEditorFocused = true
                            }
                        }
                        .gesture(dragGesture(for: item))
                        .overlay(isSelected ? resizeHandles(for: item) : nil)
                }
            }
            
            textEditorOverlay
            
            if showColorPicker && selectedID != nil {
                colorPickerView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: .bottom)
        .onChange(of: isTextEditorFocused) { _, newFocus in
            if !newFocus {
                saveAndEndEditing()
            }
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var textEditorOverlay: some View {
        if let editingID = editingTextItemID,
           let item = board.items.first(where: { $0.id == editingID }) {
            TextEditor(text: $editingText)
                .focused($isTextEditorFocused)
                .font(.body)
                .padding(8)
                .background(.regularMaterial)
                .border(Color.accentColor)
                .frame(width: item.size.width, height: item.size.height)
                .position(item.position)
        }
    }
    
    @ViewBuilder
    private func resizeHandles(for item: CanvasItem) -> some View {
        ZStack {
            ForEach(ResizeHandle.allCases, id: \.self) { handle in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 12, height: 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: handle.alignment)
                    .padding(4)
                    .contentShape(Rectangle())
                    .gesture(resizeGesture(for: item, handle: handle))
            }
        }
        .frame(width: item.size.width, height: item.size.height)
        .position(item.position)
        .offset(draggedItemID == item.id ? dragOffset : .zero)
    }
    
    @ViewBuilder
    private var colorPickerView: some View {
        HStack(spacing: 15) {
            ForEach(predefinedColors, id: \.self) { color in
                Button(action: { changeSelectedItemColor(to: color) }) {
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.gray, lineWidth: color == .white ? 1 : 0))
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding(.bottom, 70)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Gestures
    private func dragGesture(for item: CanvasItem) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if draggedItemID == nil { draggedItemID = item.id }
                if draggedItemID == item.id { dragOffset = value.translation }
            }
            .onEnded { value in
                guard let index = board.items.firstIndex(where: { $0.id == item.id }) else { return }
                if draggedItemID == item.id {
                    board.items[index].position.x += value.translation.width
                    board.items[index].position.y += value.translation.height
                    pushUndo()
                }
                draggedItemID = nil
                dragOffset = .zero
            }
    }
    
    private func resizeGesture(for item: CanvasItem, handle: ResizeHandle) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard let index = board.items.firstIndex(where: { $0.id == item.id }) else { return }
                
                if resizingItemID == nil {
                    resizingItemID = item.id
                    resizeStartSize = item.size
                    resizeStartPosition = item.position
                }
                
                if resizingItemID == item.id {
                    let dW = value.translation.width * handle.xMultiplier
                    let dH = value.translation.height * handle.yMultiplier
                    let newWidth = max(20, resizeStartSize.width + dW)
                    let newHeight = max(20, resizeStartSize.height + dH)
                    board.items[index].size = CGSize(width: newWidth, height: newHeight)
                    let newPosX = resizeStartPosition.x + (newWidth - resizeStartSize.width) / 2 * handle.xMultiplier
                    let newPosY = resizeStartPosition.y + (newHeight - resizeStartSize.height) / 2 * handle.yMultiplier
                    board.items[index].position = CGPoint(x: newPosX, y: newPosY)
                }
            }
            .onEnded { value in
                pushUndo()
                resizingItemID = nil
            }
    }
    
    // MARK: - Core Logic Functions
    private func pushUndo() {
        if undoStack.last != board.items {
            undoStack.append(board.items)
            redoStack.removeAll()
        }
    }
    
    private func undo() {
        guard undoStack.count > 1, let currentState = undoStack.popLast() else { return }
        redoStack.append(currentState)
        withAnimation { board.items = undoStack.last ?? [] }
    }
    
    private func redo() {
        guard let nextState = redoStack.popLast() else { return }
        undoStack.append(nextState)
        withAnimation { board.items = nextState }
    }
    
    private func addRectangle() {
        let centerPoint = canvasSize != .zero ? CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2) : CGPoint(x: 200, y: 200)
        let newRect = CanvasItem(type: .rectangle, position: centerPoint, size: CGSize(width: 100, height: 100), style: .init(color: .cyan))
        withAnimation {
            board.items.append(newRect)
            pushUndo()
        }
    }
    
    private func addCircle() {
        let centerPoint = canvasSize != .zero ? CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2) : CGPoint(x: 200, y: 200)
        let newCircle = CanvasItem(type: .circle, position: centerPoint, size: CGSize(width: 100, height: 100), style: .init(color: .orange))
        withAnimation {
            board.items.append(newCircle)
            pushUndo()
        }
    }
    
    private func addText() {
        let centerPoint = canvasSize != .zero ? CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2) : CGPoint(x: 200, y: 200)
        let newTextItem = CanvasItem(
            type: .text("New Text"),
            position: centerPoint,
            size: CGSize(width: 150, height: 50),
            style: .init(color: .primary)
        )
        withAnimation {
            board.items.append(newTextItem)
            pushUndo()
        }
    }
    
    // MARK: - Image Handling
    
    /// Loads image data from a PhotosPickerItem and adds it to the board.
    private func loadImage(from item: PhotosPickerItem?) async {
        // Ensure the item exists
        guard let item = item else { return }
        
        // Defer resetting the picker selection until the function exits
        defer {
            Task { @MainActor in
                selectedPhotoItem = nil
            }
        }
        
        do {
            // Load the image data; Data is a built-in Transferable type.
            guard let data = try await item.loadTransferable(type: Data.self) else {
                print("Failed to load image data from PhotosPickerItem.")
                return
            }
            
            // Switch to the main actor to update the UI.
            await MainActor.run {
                addImage(from: data)
            }
        } catch {
            print("Failed to load image with error: \(error.localizedDescription)")
        }
    }
    
    /// Processes image data, creates a CanvasItem, and adds it to the canvas.
    private func addImage(from data: Data) {
        guard let uiImage = UIImage(data: data) else {
            print("addImage(Data): FAILED to create UIImage from provided data. Not adding image object.")
            // Optionally, you could show an alert to the user here.
            return
        }
        
        let centerPoint = canvasSize != .zero ? CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2) : CGPoint(x: 200, y: 200)
        
        // Scale the image down if it's too large, preserving aspect ratio.
        let imageSize: CGSize
        let maxDimension: CGFloat = 300
        if uiImage.size.width > maxDimension || uiImage.size.height > maxDimension {
            let aspectRatio = uiImage.size.width / uiImage.size.height
            if aspectRatio > 1 {
                imageSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                imageSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
        } else {
            imageSize = uiImage.size
        }
        
        // Normalize the image by re-drawing it. This fixes potential issues
        // with formats like HEIC and ensures a consistent color profile.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // Use original resolution
        let renderer = UIGraphicsImageRenderer(size: uiImage.size, format: format)
        let normalizedImage = renderer.image { _ in
            uiImage.draw(at: .zero)
        }
        
        // Re-encode to a standard web-safe format (PNG for transparency, JPEG otherwise).
        let hasAlpha = normalizedImage.cgImage?.alphaInfo != .none
        guard let finalData = hasAlpha ? normalizedImage.pngData() : normalizedImage.jpegData(compressionQuality: 0.8) else {
            print("addImage(Data): FAILED to re-encode normalized image. Not adding image object.")
            return
        }
        
        let newImageItem = CanvasItem(type: .image(finalData), position: centerPoint, size: imageSize)
        
        withAnimation {
            board.items.append(newImageItem)
            pushUndo()
        }
    }
    
    private func saveAndEndEditing() {
        guard let editingID = editingTextItemID,
              let index = board.items.firstIndex(where: { $0.id == editingID })
        else { return }
        
        if board.items[index].type != .text(editingText) {
            board.items[index].type = .text(editingText)
            pushUndo()
        }
        
        editingTextItemID = nil
        editingText = ""
    }
    
    private func deleteSelectedItem() {
        guard let itemID = selectedID else { return }
        withAnimation {
            board.items.removeAll { $0.id == itemID }
            pushUndo()
            selectedID = nil
        }
    }
    
    private func changeSelectedItemColor(to color: Color) {
        guard let selectedID = selectedID,
              let index = board.items.firstIndex(where: { $0.id == selectedID })
        else { return }
        
        withAnimation {
            board.items[index].style.color = color
            pushUndo()
        }
    }
}


// MARK: - Toolbar Content
struct BoardToolbarContent: ToolbarContent {
    @Binding var showPhotoPicker: Bool
    @Binding var selectedPhotoItem: PhotosPickerItem?
    
    let undoAction: () -> Void
    let redoAction: () -> Void
    let addRectangleAction: () -> Void
    let addCircleAction: () -> Void
    let addTextAction: () -> Void
    let deleteAction: () -> Void
    let toggleInspectorAction: () -> Void
    
    let isUndoDisabled: Bool
    let isRedoDisabled: Bool
    let isDeleteDisabled: Bool
    let isInspectorDisabled: Bool
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button(action: undoAction) { Label("Undo", systemImage: "arrow.uturn.backward") }.disabled(isUndoDisabled)
            Button(action: redoAction) { Label("Redo", systemImage: "arrow.uturn.forward") }.disabled(isRedoDisabled)
            Spacer()
            Menu {
                Button(action: addRectangleAction) { Label("Add Rectangle", systemImage: "square") }
                Button(action: addCircleAction) { Label("Add Circle", systemImage: "circle") }
                Button(action: addTextAction) { Label("Add Text", systemImage: "textformat") }
                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Add Image", systemImage: "photo")
                }
            } label: { Label("Add Item", systemImage: "plus.circle.fill").font(.title2)
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            Spacer()
            Button(action: deleteAction) { Label("Delete", systemImage: "trash") }.disabled(isDeleteDisabled)
            Button(action: toggleInspectorAction) { Label("Inspector", systemImage: "swatchpalette") }.disabled(isInspectorDisabled)
        }
    }
}
