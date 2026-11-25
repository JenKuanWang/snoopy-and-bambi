import AppKit
import UserNotifications

/// Optional macOS notifications (off until you turn them on from the menu).
/// The always-on reminders are in the pen itself: badges on the buttons, a
/// bubble over the hay or bowl, and a bunny waiting there thumping.
@MainActor
final class Reminders: NSObject, UNUserNotificationCenterDelegate {
    private static let repeatEvery: TimeInterval = 4 * 3600

    private var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }

    /// Called at launch when notifications were turned on earlier.
    func attach() {
        center.delegate = self
    }

    func enable(_ done: @escaping @MainActor (Bool) -> Void) {
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error { Log.info("Notification permission error: \(error.localizedDescription)") }
            Task { @MainActor in done(granted) }
        }
    }

    func check(_ model: inout PenModel, now: Date) {
        guard model.notificationsOn else { return }
        func due(_ last: Date?) -> Bool { last.map { now.timeIntervalSince($0) > Self.repeatEvery } ?? true }

        if model.hayLow, due(model.lastHayNotice) {
            post(title: "Hay is running low 🌾", body: "Snoopy and Bambi would love some more hay.")
            model.lastHayNotice = now
        }
        if model.needsWaterAttention(at: now), due(model.lastWaterNotice) {
            post(title: "Time for fresh water 💧",
                 body: model.waterLow ? "The water bowl is nearly empty." : "The water has been out for a day.")
            model.lastWaterNotice = now
        }
        if model.litterNeedsCleaning, due(model.lastLitterNotice) {
            post(title: "Litter box needs a clean 🧹", body: "It's getting pretty full in there.")
            model.lastLitterNotice = now
        }
    }

    private func post(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)) { error in
            if let error { Log.info("Couldn't post notification: \(error.localizedDescription)") }
        }
        Log.info("Notification: \(title)")
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
