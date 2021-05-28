#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

/// An HStack that grows vertically when single line overflows
@available(iOS 14, macOS 11, *)
public struct WrappingHStack<Data: RandomAccessCollection, ID: Hashable, Cell: View>: View {
    
    public let data: Data
    public var cell: (Data.Element) -> Cell
    public var id: KeyPath<Data.Element, ID>
    public var alignment: Alignment
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    
    @State private var elementsWidths: [ID: CGFloat] = [:]
    @State private var calculatedWidthsKeys: Set<ID> = []
    
    private let idsForCalculatingSizes: Set<ID>
    private var dataForCalculatingSizes: [Data.Element] {
        var result: [Data.Element] = []
        var idsToProcess: Set<ID> = idsForCalculatingSizes
        idsToProcess.subtract(calculatedWidthsKeys)
        
        data.forEach { item in
            let itemId = item[keyPath: id]
            if idsToProcess.contains(itemId) {
                idsToProcess.remove(itemId)
                result.append(item)
            }
        }
        return result
    }
    
    /// Creates a new WrappingHStack
    ///
    /// - Parameters:
    ///   - data: a data that stack represents
    ///   - id: a keypath of element identifier
    ///   - alignment: horizontal and vertical alignment. Vertical alignment is applied to every row
    ///   - horizontalSpacing: horizontal spacing between elements
    ///   - verticalSpacing: vertical spacing between the lines
    ///   - create: a method that creates an element representation
    public init(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat = 0,
        verticalSpacing: CGFloat = 0,
        @ViewBuilder content create: @escaping (Data.Element) -> Cell
    ) {
        self.data = data
        cell = create
        idsForCalculatingSizes = Set(data.map { $0[keyPath: id] })
        self.id = id
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    public var body: some View {
        if calculatedWidthsKeys.isSuperset(of: idsForCalculatingSizes) {
            TightHeightGeometryReader { geometry in
                let splitted = data.split(maxLength: geometry.size.width, spacing: horizontalSpacing) { element in
                    elementsWidths[element[keyPath: id]]
                }
                
                // All sizes are known
                VStack(alignment: alignment.horizontal, spacing: verticalSpacing) {
                    ForEach(Array(splitted.enumerated()), id: \.offset) { list in
                        HStack(alignment: alignment.vertical, spacing: horizontalSpacing) {
                            ForEach(data[list.element], id: id, content: cell)
                        }
                    }
                }
            }
        } else {
            // Calculating sizes
            VStack {
                ForEach(dataForCalculatingSizes, id: id) { d in
                    cell(d)
                        .onSizeChange { size in
                            let key = d[keyPath: id]
                            elementsWidths[key] = size.width
                            calculatedWidthsKeys.insert(key)
                        }
                }
            }
        }
    }
}

extension WrappingHStack {
    /// Creates a new WrappingHStack
    ///
    /// - Parameters:
    ///   - id: a keypath of element identifier
    ///   - alignment: horizontal and vertical alignment. Vertical alignment is applied to every row
    ///   - horizontalSpacing: horizontal spacing between elements
    ///   - verticalSpacing: vertical spacing between the lines
    ///   - create: a method that creates an array of elements
    public init(
        id: KeyPath<Data.Element, ID>,
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat = 0,
        verticalSpacing: CGFloat = 0,
        @ViewBuilder content create: () -> ForEach<Data, ID, Cell>
    ) {
        let forEach = create()
        self.init(data: forEach.data,
                  id: id,
                  alignment: alignment,
                  horizontalSpacing: horizontalSpacing,
                  verticalSpacing: verticalSpacing,
                  content: forEach.content)
    }
}

@available(iOS 14, macOS 11, *)
extension WrappingHStack where ID == Data.Element.ID, Data.Element: Identifiable {
    /// Creates a new WrappingHStack
    ///
    /// - Parameters:
    ///   - alignment: horizontal and vertical alignment. Vertical alignment is applied to every row
    ///   - horizontalSpacing: horizontal spacing between elements
    ///   - verticalSpacing: vertical spacing between the lines
    ///   - create: a method that creates an array of elements
    public init(
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat = 0,
        verticalSpacing: CGFloat = 0,
        @ViewBuilder content create: () -> ForEach<Data, ID, Cell>
    ) {
        self.init(id: \.id,
                  alignment: alignment,
                  horizontalSpacing: horizontalSpacing,
                  verticalSpacing: verticalSpacing,
                  content: create)
    }
}

#if DEBUG

@available(iOS 14, macOS 11, *)
struct WrappingHStack_Previews: PreviewProvider {
    static var previews: some View {
        WrappingHStack(
            id: \.self,
            horizontalSpacing: 8,
            verticalSpacing: 8
        ) {
            ForEach(["Cat 🐱", "Dog 🐶", "Sun 🌞", "Moon 🌕", "Tree 🌳"], id: \.self) { element in
                Text(element)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color.white)
    }
}

#endif

#endif
