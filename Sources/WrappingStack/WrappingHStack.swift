#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

@available(iOS 16, macOS 13, *)
public struct WrappingHStack<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    
    public var content: ForEach<Data, ID, Content>
    public var id: KeyPath<Data.Element, ID>
    public var idealLineLength: Int?
    public var alignment: Alignment
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    
    public init(
        id: KeyPath<Data.Element, ID>,
        alignment: Alignment,
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat,
        @ViewBuilder content create: () -> ForEach<Data, ID, Content>
    ) {
        self.content = create()
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
        ) { content }
        .frame(maxWidth: .infinity, alignment: alignment)
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
        
//        The zero proposal – respond with the layout’s minimum size.
//        The infinity proposal – respond with the layout’s maximum size.
//        The unspecified proposal – respond with the layout’s ideal size.
        
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
        
        let (maxWidth, totalHeight) = MultilineSizeComputer.gridSize(
            elements: lines.lazy.map { $0.lazy.map { dimensions[$0] } },
            spacing: horizontalSpacing,
            orthogonalSpacing: verticalSpacing,
            length: \.width,
            orthogonalLength: \.height
        )
        
        let computedSize = CGSize(width: maxWidth, height: totalHeight)
        
        print(lines)
        print(computedSize)
        
        return computedSize
    }
    
    private func calculateMinWidthSize(dimensions: [ViewDimensions]) -> CGSize {
        // vertical column of all elements
        let (height, width) = MultilineSizeComputer.lineSize(
            elements: dimensions,
            spacing: verticalSpacing,
            length: \.height,
            orthogonalLength: \.width
        )
        return CGSize(width: width, height: height)
    }
    
    private func calculateMaxWidthSize(dimensions: [ViewDimensions]) -> CGSize {
        // horizontal row of all elements
        let (width, height) = MultilineSizeComputer.lineSize(
            elements: dimensions,
            spacing: horizontalSpacing,
            length: \.width,
            orthogonalLength: \.height
        )
        return CGSize(width: width, height: height)
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
        
        var xAdjustment: (_ lineWidth: CGFloat) -> CGFloat
        switch alignment.horizontal {
        case .leading: xAdjustment = { _ in 0 }
        case .center: xAdjustment = { lineWidth in (bounds.width - lineWidth) / 2 }
        case .trailing: xAdjustment = { lineWidth in bounds.width - lineWidth }
        default: // not supported
            xAdjustment = { _ in 0 }
        }
        
        var yAdjustment: (_ elementHeight: CGFloat, _ lineHeight: CGFloat) -> CGFloat
        
        switch alignment.vertical {
        case .top: yAdjustment = { _, _ in 0 }
        case .center: yAdjustment = { elementHeight, lineHeight in (lineHeight - elementHeight) / 2 }
        case .bottom: yAdjustment = { elementHeight, lineHeight in lineHeight - elementHeight }
        default: // not supported
            yAdjustment = { _, _ in 0 }
        }
        
        lines.split(lengthLimit: proposedSize.width).forEach { line in
            let (lineWidth, lineHeight) = MultilineSizeComputer.lineSize(
                elements: cache.dimensions[line],
                spacing: horizontalSpacing,
                length: \.width, orthogonalLength: \.height
            )
            
            var x = minX + xAdjustment(lineWidth)
            
            line.indices.forEach { index in
                let size = cache.dimensions[index]
                subviews[index].place(
                    at: CGPoint(x: x, y: y + yAdjustment(size.height, lineHeight)),
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + horizontalSpacing
            }
            
            y += lineHeight + verticalSpacing
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
