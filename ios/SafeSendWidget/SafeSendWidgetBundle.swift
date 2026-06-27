//
//  SafeSendWidgetBundle.swift
//  SafeSendWidget
//
//  Created by ase on 6/27/26.
//

import WidgetKit
import SwiftUI

@main
struct SafeSendWidgetBundle: WidgetBundle {
    var body: some Widget {
        SafeSendWidget()
        SafeSendWidgetControl()
        SafeSendWidgetLiveActivity()
    }
}
