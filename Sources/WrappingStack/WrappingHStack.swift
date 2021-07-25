#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

/// An HStack that grows vertically when single line overflows
@available(iOS 14, macOS 11, *)
public struct WrappingHStack<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    
    public let data: Data
    public var content: (Data.Element) -> Content
    public var id: KeyPath<Data.Element, ID>
    public var alignment: Alignment
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    
    @State private var sizes: [ID: CGSize] = [:]
    @State private var calculatesSizesKeys: Set<ID> = []
    
    private let idsForCalculatingSizes: Set<ID>
    private var dataForCalculatingSizes: [Data.Element] {
        var result: [Data.Element] = []
        var idsToProcess: Set<ID> = idsForCalculatingSizes
        idsToProcess.subtract(calculatesSizesKeys)
        
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
        @ViewBuilder content create: () -> ForEach<Data, ID, Content>
    ) {
        let forEach = create()
        data = forEach.data
        content = forEach.content
        idsForCalculatingSizes = Set(data.map { $0[keyPath: id] })
        self.id = id
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    private func splitIntoLines(maxWidth: CGFloat) -> [Range<Data.Index>] {
        var width: CGFloat = 0
        var result: [Range<Data.Index>] = []
        var lineStart = data.startIndex
        var lineLength = 0
        
        for element in data {
            guard let elementWidth = sizes[element[keyPath: id]]?.width
            else { break }
            let newWidth = width + elementWidth
            if newWidth < maxWidth || lineLength == 0 {
                width = newWidth + horizontalSpacing
                lineLength += 1
            } else {
                width = elementWidth
                let lineEnd = data.index(lineStart, offsetBy:lineLength)
                result.append(lineStart ..< lineEnd)
                lineLength = 0
                lineStart = lineEnd
            }
        }
        
        if lineStart != data.endIndex {
            result.append(lineStart ..< data.endIndex)
        }
        return result
    }
    
    public var body: some View {
        if calculatesSizesKeys.isSuperset(of: idsForCalculatingSizes) {
            TightHeightGeometryReader(alignment: alignment) { geometry in
                let splitted = splitIntoLines(maxWidth: geometry.size.width)
                
                // All sizes are known
                VStack(alignment: alignment.horizontal, spacing: verticalSpacing) {
                    ForEach(Array(splitted.enumerated()), id: \.offset) { list in
                        HStack(alignment: alignment.vertical, spacing: horizontalSpacing) {
                            ForEach(data[list.element], id: id) {
                                content($0)
                            }
                        }
                    }
                }
            }
        } else {
            // Calculating sizes
            VStack {
                ForEach(dataForCalculatingSizes, id: id) { d in
                    content(d)
                        .onSizeChange { size in
                            let key = d[keyPath: id]
                            sizes[key] = size
                            calculatesSizesKeys.insert(key)
                        }
                }
            }
        }
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
        @ViewBuilder content create: () -> ForEach<Data, ID, Content>
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
            alignment: .trailing,
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
