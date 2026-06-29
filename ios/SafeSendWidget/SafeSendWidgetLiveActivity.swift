//
//  SafeSendWidgetLiveActivity.swift
//  SafeSendWidget
//
//  #011 Background Transfer — iOS Live Activity (Lock Screen + Dynamic Island).
//
//  Uses the `live_activities` plugin contract: the ActivityAttributes MUST be
//  named EXACTLY `LiveActivitiesAppAttributes`, and dynamic values are read from
//  the shared App Group UserDefaults via `context.attributes.prefixedKey(...)`.
//  The keys match BackgroundTransferState.toContentState() (Dart) — see
//  specs/011-background-transfer/contracts/live_activity_state.md.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Attributes (name + shape required by the live_activities plugin)

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState

  public struct ContentState: Codable, Hashable {}

  var id = UUID()
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String { "\(id)_\(key)" }
}

// MARK: - Shared App Group store (flavor-specific — must equal the Dart
// AppConfig.liveActivityAppGroupId). The group id is injected per flavor via the
// `APP_GROUP_ID` build setting (Runner flavor xcconfigs + the widget build
// settings) and surfaced in this extension's Info.plist as `AppGroupId`, so dev
// and prod use separate containers.

private let ssAppGroupId: String =
  (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String)
  ?? "group.app.safesend.liveactivities"

// Non-forced: if the App Group is somehow unavailable, fall back to .standard
// so the widget still renders (blank) instead of crashing and showing nothing.
private let ssSharedDefault = UserDefaults(suiteName: ssAppGroupId) ?? .standard

// MARK: - Palette (mirrored from the design tokens — see the contract)

private enum SS {
  static let green400 = Color(red: 0x1E / 255, green: 0xD6 / 255, blue: 0x6E / 255)
  static let receive = Color(red: 0x4F / 255, green: 0xE6 / 255, blue: 0xFF / 255)
  static func accent(_ direction: String) -> Color {
    direction == "send" ? green400 : receive
  }
}

/// Reads the current transfer fields for a given activity from the App Group.
private struct SSFields {
  let direction: String
  let title: String
  let peerLine: String
  let percent: Int
  let speedLabel: String
  let bytesLabel: String
  let etaLabel: String
  let phase: String

  init(_ attrs: LiveActivitiesAppAttributes) {
    func s(_ k: String) -> String {
      ssSharedDefault.string(forKey: attrs.prefixedKey(k)) ?? ""
    }
    direction = s("direction")
    title = s("title")
    peerLine = s("peerLine")
    percent = ssSharedDefault.integer(forKey: attrs.prefixedKey("percent"))
    speedLabel = s("speedLabel")
    bytesLabel = s("bytesLabel")
    etaLabel = s("etaLabel")
    phase = s("phase")
  }

  var accent: Color { SS.accent(direction) }
  var progress: Double { Double(percent) / 100.0 }
  var icon: String { direction == "send" ? "arrow.up" : "arrow.down" }
  var metaTrailing: String {
    etaLabel.isEmpty ? bytesLabel : "\(bytesLabel) · \(etaLabel)"
  }
}

// MARK: - Widget

struct SafeSendWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      // Lock Screen / banner.
      LockScreenCard(f: SSFields(context.attributes))
        .padding(14)
        .activityBackgroundTint(Color.black.opacity(0.55))
        .activitySystemActionForegroundColor(Color.white)
    } dynamicIsland: { context in
      let f = SSFields(context.attributes)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: f.icon).foregroundColor(f.accent)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("\(f.percent)%")
            .font(.system(.body, design: .monospaced).weight(.bold))
            .foregroundColor(f.accent)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 1) {
            Text(f.title).font(.system(size: 13, weight: .bold)).lineLimit(1)
            Text(f.peerLine).font(.system(size: 11))
              .foregroundColor(.white.opacity(0.6)).lineLimit(1)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 6) {
            ProgressView(value: f.progress).tint(f.accent)
            HStack {
              Text(f.speedLabel)
              Spacer()
              Text(f.metaTrailing)
            }
            .font(.system(.caption2, design: .monospaced))
            .foregroundColor(.white.opacity(0.6))
          }
        }
      } compactLeading: {
        Image(systemName: f.icon).foregroundColor(f.accent)
      } compactTrailing: {
        Text("\(f.percent)%")
          .font(.system(.caption2, design: .monospaced)).foregroundColor(f.accent)
      } minimal: {
        Text("\(f.percent)%")
          .font(.system(.caption2, design: .monospaced)).foregroundColor(f.accent)
      }
    }
  }
}

// MARK: - Lock Screen card

private struct LockScreenCard: View {
  let f: SSFields

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        Image(systemName: f.icon)
          .foregroundColor(.black)
          .frame(width: 34, height: 34)
          .background(f.accent)
          .clipShape(RoundedRectangle(cornerRadius: 10))
        VStack(alignment: .leading, spacing: 1) {
          Text(f.title).font(.system(size: 13, weight: .bold))
          Text(f.peerLine).font(.system(size: 11))
            .foregroundColor(.white.opacity(0.65))
        }
        Spacer()
        Text("\(f.percent)%")
          .font(.system(size: 19, weight: .bold, design: .monospaced))
          .foregroundColor(f.accent)
      }
      ProgressView(value: f.progress).tint(f.accent)
      HStack {
        Text(f.speedLabel)
        Spacer()
        Text(f.metaTrailing)
      }
      .font(.system(.caption2, design: .monospaced))
      .foregroundColor(.white.opacity(0.6))
    }
    .foregroundColor(.white)
  }
}
