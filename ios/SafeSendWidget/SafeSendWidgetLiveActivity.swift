//
//  SafeSendWidgetLiveActivity.swift
//  SafeSendWidget
//
//  Created by ase on 6/27/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SafeSendWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SafeSendWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SafeSendWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SafeSendWidgetAttributes {
    fileprivate static var preview: SafeSendWidgetAttributes {
        SafeSendWidgetAttributes(name: "World")
    }
}

extension SafeSendWidgetAttributes.ContentState {
    fileprivate static var smiley: SafeSendWidgetAttributes.ContentState {
        SafeSendWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SafeSendWidgetAttributes.ContentState {
         SafeSendWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SafeSendWidgetAttributes.preview) {
   SafeSendWidgetLiveActivity()
} contentStates: {
    SafeSendWidgetAttributes.ContentState.smiley
    SafeSendWidgetAttributes.ContentState.starEyes
}
