#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

@available(iOS 16, macOS 13, *)
public struct WrappingHStack<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    
    public let data: Data
    public var content: (Data.Element) -> Content
    public var id: KeyPath<Data.Element, ID>
    public var idealLineLength: Int?
    public var alignment: Alignment
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    
    public init(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        alignment: Alignment,
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat,
        content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        self.id = id
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    public var body: some View {
        WrappingHStackLayout(
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            alignment: alignment
        ) {
            ForEach(0 ..< 20) { index in
                Rectangle().frame(width: 50, height: 50)
                    .overlay(Text("\(index)").foregroundColor(.white))
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .background(Color.gray)
    }
}

@available(iOS 16, macOS 13, *)
extension WrappingHStack: WrappingStack {}

@available(iOS 16, macOS 13, *)
private struct WrappingHStackLayout: Layout {
    struct Cache {
        private(set) var dimensions: [ViewDimensions] = []
        
        mutating func invalidate() {
            dimensions = []
        }
        
        mutating func updateSizesIfNeeded(subviews: Subviews, proposal: ProposedViewSize) {
            guard dimensions.isEmpty
            else { return }
            
            dimensions = subviews.map { $0.dimensions(in: proposal) }
        }
    }
    
    static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }
    
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat
    var alignment: Alignment
    
    func makeCache(subviews: Subviews) -> Cache { .init() }
    
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.invalidate()
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache)
    -> CGSize {
        print("Proposed size \(proposal.width)x\(proposal.height)")
        
//        The zero proposal; respond with the layout’s minimum size.
//        The infinity proposal; respond with the layout’s maximum size.
//        The unspecified proposal; respond with the layout’s ideal size.
        
        cache.updateSizesIfNeeded(subviews: subviews, proposal: proposal)
        
        let dimensions = cache.dimensions
        
        if proposal.width == .zero {
            // searching for minimal width size
            let result = calculateMinWidthSize(dimensions: dimensions)
            print(result)
            return result
        } else if proposal.width == .infinity {
            // searching for minimal width size
            let result = calculateMaxWidthSize(dimensions: dimensions)
            print(result)
            return result
        }
        
        
        //FIXME:
        let proposedSize = proposal.replacingUnspecifiedDimensions(by: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        

        let lines = Lines(
            elements: subviews.indices,
            spacing: horizontalSpacing
        ) { dimensions[$0].width }.split(lengthLimit: proposedSize.width)
        
        let linesHeights = lines.lazy
            .map { dimensions[$0].lazy.map { $0.height }.max() ?? 0 }
        
        let verticalSpacing = verticalSpacing
        let horizontalSpacing = horizontalSpacing
        
        var totalHeight = linesHeights.reduce(into: 0) { totalHeight, lineHeight in
            totalHeight += lineHeight + verticalSpacing
        }
        
        var maxWidth = lines.lazy.map {
            dimensions[$0].lazy.map { $0.width }.reduce(into: 0) { width, elementWidth in
                width += elementWidth + horizontalSpacing
            }
        }.max() ?? 0
        
        if !lines.isEmpty {
            maxWidth -= horizontalSpacing
            totalHeight -= verticalSpacing
        }
        
        let computedSize = CGSize(width: maxWidth, height: totalHeight)
        
        print(lines)
        print(computedSize)
        
        return computedSize
    }
    
    private func calculateMinWidthSize(dimensions: [ViewDimensions]) -> CGSize {
        let (height, width) = calculateLineSize(
            elements: dimensions,
            spacing: verticalSpacing,
            length: \.height,
            orthogonalLength: \.width
        )
        return CGSize(width: width, height: height)
    }
    
    private func calculateMaxWidthSize(dimensions: [ViewDimensions]) -> CGSize {
        let (width, height) = calculateLineSize(
            elements: dimensions,
            spacing: horizontalSpacing,
            length: \.width,
            orthogonalLength: \.height
        )
        return CGSize(width: width, height: height)
    }
    
    private func calculateLineSize<S: RandomAccessCollection>(
        elements: S,
        spacing: CGFloat,
        length: (S.Element) -> CGFloat,
        orthogonalLength: (S.Element) -> CGFloat
    ) -> (length: CGFloat, orthogonalLength: CGFloat) {
        
        var lineSize = elements.reduce(into:(length: CGFloat.zero, orthogonalLength: CGFloat.zero)) { result, element in
            result.length += length(element)
            
            let normalElementLength = orthogonalLength(element)
            
            if result.orthogonalLength < normalElementLength{
                result.orthogonalLength = normalElementLength
            }
        }
        
        if !elements.isEmpty {
            lineSize.length += spacing * CGFloat(elements.count - 1)
        }
        
        return lineSize
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        cache.updateSizesIfNeeded(subviews: subviews, proposal: proposal)
        
        print("Placing subviews in \(bounds)")
        let horizontalSpacing = horizontalSpacing
        let verticalSpacing = verticalSpacing
        
        let minX = bounds.minX
        
        var y: CGFloat = bounds.minY
        
        let proposedSize = proposal.replacingUnspecifiedDimensions(by: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        let dimensions = cache.dimensions
        
        let lines = Lines(
            elements: subviews.indices,
            spacing: horizontalSpacing
        ) { dimensions[$0].width }
        
        let adjustsHorizontalPosition = alignment.horizontal != .leading
        
        lines.split(lengthLimit: proposedSize.width).forEach { line in
            var x: CGFloat = minX
            
            if adjustsHorizontalPosition {
                var lineWidth = line.indices.reduce(into: 0) { width, index in
                    width += cache.dimensions[index].width
                }
                
                if !line.isEmpty {
                    lineWidth += CGFloat(line.count - 1) * horizontalSpacing
                }
                
                switch alignment.horizontal {
                case .center:
                    x += (bounds.width - lineWidth) / 2
                case .trailing:
                    x += bounds.width - lineWidth
                default: break
                }
            }
            
            var height: CGFloat = 0
            
            line.indices.forEach { index in
                let size = cache.dimensions[index]
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + horizontalSpacing
                height = max(height, size.height)
            }
            
            y += height + verticalSpacing
        }
    }
}

@available(iOS 16, macOS 13, *)
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
                    .fixedSize()
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color.white)
    }
}

#endif
