#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

@available(iOS 14, macOS 11, *)
struct TightHeightGeometryReader<Content: View>: View {
    var alignment: Alignment
    @State private var height: CGFloat = 0

    var content: (GeometryProxy) -> Content
    
    init(
        alignment: Alignment = .topLeading,
        @ViewBuilder content: @escaping (GeometryProxy) -> Content
    ) {
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            content(geometry)
                .onSizeChange { size in
                    if self.height != size.height {
                        self.height = size.height
                    }
                }
                .frame(maxWidth: .infinity, alignment: alignment)
        }
        .frame(height: height)
    }
}

#endif
