//
//  SafeSendWidgetBundle.swift
//  SafeSendWidget
//
//  #011 Background Transfer. This extension hosts only the transfer Live
//  Activity — the default home-screen widget + Control template that Xcode
//  generated were removed (Safe Send ships no home widget / control).
//

import SwiftUI
import WidgetKit

@main
struct SafeSendWidgetBundle: WidgetBundle {
  var body: some Widget {
    SafeSendWidgetLiveActivity()
  }
}
