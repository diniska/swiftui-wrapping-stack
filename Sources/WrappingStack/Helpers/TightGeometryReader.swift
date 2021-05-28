#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI

@available(iOS 13, macOS 10.15, *)
struct TightWidthGeometryReader<Content: View>: View {
    @State private var width: CGFloat = 0

    var content: (GeometryProxy) -> Content
    
    init(@ViewBuilder content: @escaping (GeometryProxy) -> Content) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            content(geometry)
                .onSizeChange { size in
                    if self.width != size.width {
                        self.width = size.width
                    }
                }
        }
        .frame(width: width)
    }
}

@available(iOS 13, macOS 10.15, *)
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
