#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

@available(iOS 14, macOS 11, *)
struct TightHeightGeometryReader<Content: View>: View {
    @State private var height: CGFloat = 0

    var content: (GeometryProxy) -> Content
    
    init(@ViewBuilder content: @escaping (GeometryProxy) -> Content) {
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
        }
        .frame(height: height)
    }
}

#endif
