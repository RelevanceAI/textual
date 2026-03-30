import SwiftUI

// MARK: - Overview
//
// `TextFragmentOverlay` combines attachment rendering and link interaction into a single
// overlay modifier, reducing the number of GeometryReaders and preference subscriptions
// per text fragment from 2 to 1.
//
// Previously, `AttachmentOverlay` and `TextLinkInteraction` each independently subscribed
// to `Text.LayoutKey` and created their own `GeometryReader`. This combined modifier reads
// the preference once and resolves geometry once, then renders both attachments and link
// tap handling in the same overlay.

struct TextFragmentOverlay: ViewModifier {
  #if TEXTUAL_ENABLE_LINKS
    @Environment(\.openURL) private var openURL
  #endif

  private let attachments: Set<AnyAttachment>

  init(attachments: Set<AnyAttachment>) {
    self.attachments = attachments
  }

  func body(content: Content) -> some View {
    content
      .overlayPreferenceValue(Text.LayoutKey.self) { value in
        if let anchoredLayout = value.first {
          GeometryReader { geometry in
            let origin = geometry[anchoredLayout.origin]
            let layout = anchoredLayout.layout

            AttachmentView(
              attachments: attachments,
              origin: origin,
              layout: layout
            )

            #if TEXTUAL_ENABLE_LINKS
              Color.clear
                .contentShape(.rect)
                .gesture(
                  SpatialTapGesture()
                    .onEnded { value in
                      let localPoint = CGPoint(
                        x: value.location.x - origin.x,
                        y: value.location.y - origin.y
                      )
                      let runs = layout.flatMap(\.self)
                      let run = runs.first { run in
                        run.typographicBounds.rect.contains(localPoint)
                      }
                      guard let url = run?.url else {
                        return
                      }
                      openURL(url)
                    }
                )
            #endif
          }
        }
      }
  }
}
