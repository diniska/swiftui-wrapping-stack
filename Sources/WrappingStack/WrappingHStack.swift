#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

/// An HStack that grows vertically when single line overflows
@available(iOS 14, macOS 11, *)
public struct WrappingHStack<Data: RandomAccessCollection, ID: Hashable, Cell: View>: View {
    
    public let data: Data
    public var content: (Data.Element) -> Cell
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
    
    private init(
        id: KeyPath<Data.Element, ID>,
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat = 0,
        verticalSpacing: CGFloat = 0,
        data: Data,
        @ViewBuilder content create: @escaping (Data.Element) -> Cell
    ){
        self.data = data
        self.content = create
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
            TightHeightGeometryReader { geometry in
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
    ){
        let forEach = create()
        self.init(id: id,
                  alignment: alignment,
                  horizontalSpacing: horizontalSpacing,
                  verticalSpacing: verticalSpacing,
                  data: forEach.data,
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
        @ViewBuilder content create: () -> ForEach<Data, ID, Content>
    ) {
        self.init(id: \.id,
                  alignment: alignment,
                  horizontalSpacing: horizontalSpacing,
                  verticalSpacing: verticalSpacing,
                  content: create)
    }
}

//@available(iOS 14, macOS 11, *)
//extension WrappingHStack where Data == Array<(Int, Cell)>, ID == Int {
//    /// Single element wrapper
//    public init(
//        alignment: Alignment = .center,
//        horizontalSpacing: CGFloat = 0,
//        verticalSpacing: CGFloat = 0,
//        @ViewBuilder content create: () -> Cell
//    ) {
//        data = [(0, create())]
//        id = \.self.0
//        self.alignment = alignment
//        self.horizontalSpacing = horizontalSpacing
//        self.verticalSpacing = verticalSpacing
//        idsForCalculatingSizes = [0]
//        self.content = { $0.1 }
//    }
//}

@available(iOS 14, macOS 11, *)
extension WrappingHStack where Data == Array<(Int, Cell)>, ID == Int, Cell == AnyView {
    /// Single element wrapper
    public init<C0: View, C1: View>(
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat = 0,
        verticalSpacing: CGFloat = 0,
        @ViewBuilder content create: () -> TupleView<(C0, C1)>
    ) {
        let tuple = create().value
        self.init(id: \.self.0, alignment: alignment, horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing) {
            ForEach([(0, AnyView(tuple.0.background(Color.red))), (1, AnyView(tuple.1))], id: \.self.0) {
                $0.1
            }
        }
    }
}

private struct TupleWrapper<Element> {
    var items: [Element]
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

        WrappingHStack {
            Text("Lorem")
                .padding()
            Text("ipsum")
                .padding()
        }
        .background(Color.gray)
        .frame(width: 120)
        //        Text("dolor")
        //        Text("sit")
        //        Text("amet,")
        //        Text("consectetur")
        //        Text("adipiscing")
        //        Text("elit")
    }
}

#endif

#endif
