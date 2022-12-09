#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

/// An HStack that grows vertically when single line overflows
@available(iOS 14, macOS 11, *)
@available(iOS, deprecated: 16)
@available(macOS, deprecated: 13)
public struct WrappingHStackOld<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    
    public let data: Data
    public var content: (Data.Element) -> Content
    public var id: KeyPath<Data.Element, ID>
    public var alignment: Alignment
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    
    @State private var sizes: [ID: CGSize] = [:]
    @State private var calculatedSizesKeys: Set<ID> = []
    
    private let idsForCalculatingSizes: Set<ID>
    private var dataForCalculatingSizes: [Data.Element] {
        var result: [Data.Element] = []
        var idsToProcess: Set<ID> = idsForCalculatingSizes
        idsToProcess.subtract(calculatedSizesKeys)
        
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
        let lines = Lines(elements: data, spacing: horizontalSpacing) { element in
            sizes[element[keyPath: id]]?.width ?? 0
        }
        return lines.split(lengthLimit: maxWidth)
    }
    
    public var body: some View {
        if calculatedSizesKeys.isSuperset(of: idsForCalculatingSizes) {
            // All sizes are calculated, displaying the view
            laidOutContent
        } else {
            // Calculating sizes
            sizeCalculatorView
        }
    }
    
    private var laidOutContent: some View {
        TightHeightGeometryReader(alignment: alignment) { geometry in
            let splited = splitIntoLines(maxWidth: geometry.size.width)
            
            // All sizes are known
            VStack(alignment: alignment.horizontal, spacing: verticalSpacing) {
                ForEach(Array(splited.enumerated()), id: \.offset) { list in
                    HStack(alignment: alignment.vertical, spacing: horizontalSpacing) {
                        ForEach(data[list.element], id: id) {
                            content($0)
                        }
                    }
                }
            }
        }
    }
    
    private var sizeCalculatorView: some View {
        VStack {
            ForEach(dataForCalculatingSizes, id: id) { d in
                content(d)
                    .onSizeChange { size in
                        let key = d[keyPath: id]
                        sizes[key] = size
                        calculatedSizesKeys.insert(key)
                    }
            }
        }
    }
}

@available(iOS 14, macOS 11, *)
extension WrappingHStackOld: WrappingStack {}

#if DEBUG

@available(iOS 14, macOS 11, *)
struct WrappingHStackOld_Previews: PreviewProvider {
    static var previews: some View {
        WrappingHStackOld(
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
                    .fixedSize()
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color.white)
    }
}

#endif

#endif
