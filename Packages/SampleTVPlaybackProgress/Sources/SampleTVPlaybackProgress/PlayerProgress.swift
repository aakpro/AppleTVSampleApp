import Foundation
import SampleTVDomain

/// Protocol for reporting player progress - this allows the PlayerView to pass back position updates to save progress
public protocol PlayerProgressDelegate: Sendable {
    /// Called periodically with current position and duration to allow saving resume information
    func onPlayerProgress(position: TimeInterval, duration: TimeInterval)
    
    /// Called when player disappears/dismisses - can be used to save final progress or clear the state
    func onPlayerWillDisappear()
}