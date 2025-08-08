//
//  ComplicationController.swift
//  ISS Real-Time Tracker 3D
//
//  Created by Michael Stebel on 8/26/21.
//  Copyright © 2021-2025 ISS Real-Time Tracker. All rights reserved.
//

import ClockKit

/// Handles the data source for all watch complications in the app.
final class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    
    /**
     Returns an array of complication descriptors representing
     each supported complication for this watch app.
     
     - Parameter handler: A closure that receives an array
     of `CLKComplicationDescriptor` objects.
     */
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            // You can add more descriptors here if you want multiple complications.
            CLKComplicationDescriptor(
                identifier: "complication",
                displayName: "Track",
                supportedFamilies: CLKComplicationFamily.allCases
            )
        ]
        handler(descriptors)
    }
    
    /**
     Called when new complication descriptors are shared to the watch.
     
     - Parameter complicationDescriptors: The newly shared complication descriptors.
     */
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Perform any work needed to support these newly shared complication descriptors.
    }
    
    // MARK: - Timeline Configuration
    
    /**
     Provides the last date for which you can provide timeline entries.
     
     - Parameters:
     - complication: The complication you’re configuring.
     - handler: A closure that receives the last entry date you can support,
     or `nil` if you don't support future timeline entries.
     */
    func getTimelineEndDate(
        for complication: CLKComplication,
        withHandler handler: @escaping (Date?) -> Void
    ) {
        // Return nil to indicate we do not support future timelines.
        handler(nil)
    }
    
    /**
     Dictates the complication’s behavior when the device is locked.
     
     - Parameters:
     - complication: The complication you’re configuring.
     - handler: A closure that receives a `CLKComplicationPrivacyBehavior`.
     */
    func getPrivacyBehavior(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void
    ) {
        // Show data on the Lock Screen.
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    /**
     Provides the current timeline entry for the given complication.
     
     - Parameters:
     - complication: The complication requesting the timeline entry.
     - handler: A closure that receives the current `CLKComplicationTimelineEntry`.
     */
    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        // Return nil if you don’t have a current entry.
        handler(nil)
    }
    
    /**
     Provides an array of timeline entries after the specified date.
     
     - Parameters:
     - complication: The complication requesting the timeline entries.
     - date: The date after which entries are requested.
     - limit: The maximum number of entries you can provide.
     - handler: A closure that receives an array of `CLKComplicationTimelineEntry` objects.
     */
    func getTimelineEntries(
        for complication: CLKComplication,
        after date: Date,
        limit: Int,
        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void
    ) {
        // Return nil if no future entries are available.
        handler(nil)
    }
    
    // MARK: - Sample Templates
    
    /**
     Provides a sample complication template for display in the
     complication gallery.
     
     - Parameters:
     - complication: The complication requesting the sample template.
     - handler: A closure that receives a `CLKComplicationTemplate`.
     */
    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
    ) {
        // Return nil if you don’t have a sample template.
        handler(nil)
    }
}
