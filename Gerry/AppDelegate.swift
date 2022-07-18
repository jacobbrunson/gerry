//
//  AppDelegate.swift
//  Gerry
//
//  Created by Jacob Brunson on 7/17/22.
//
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var gerryController: GerryController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        gerryController = GerryController()
    }
}