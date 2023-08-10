//
//  GlobalClickListener.swift
//  Gerry
//
//  Created by Jacob Brunson on 8/6/23.
//

import AppKit

public class GlobalMouseListener {

    private var monitor: AnyObject?
    private let handler: (NSEvent?) -> ()

    public init(handler: @escaping (NSEvent?) -> ()) {
        self.handler = handler
    }

    deinit {
        stop()
    }

    public func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .leftMouseDragged], handler: handler) as AnyObject?
    }

    public func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}
