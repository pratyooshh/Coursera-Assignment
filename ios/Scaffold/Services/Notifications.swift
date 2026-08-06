import Foundation
import UserNotifications

/// Nudges, kept deliberately few.
///
/// Notification fatigue is a real failure mode here: once you've learned to
/// dismiss this app's alerts without reading them, every alert it sends is
/// worthless. So the app only schedules what the user explicitly set up — the
/// end of a block they started, the body checks they opted into, and the
/// routine reminders they configured. Nothing motivational, nothing unprompted.
enum Notifications {

    static let sessionCategory = "scaffold.session"
    static let routineCategory = "scaffold.routine"

    static func requestPermission(_ completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async { completion?(granted) }
            }
    }

    static func authorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    // MARK: - Focus sessions

    static func scheduleSessionEnd(in minutes: Int, mode: FocusMode) {
        let content = UNMutableNotificationContent()
        content.title = "Block finished"
        content.body = mode == .hyperfocusGuard
            ? "Stop and check in with your body before you carry on."
            : "That's your \(minutes) minutes. Stop or extend — either is fine."
        content.sound = .default
        content.categoryIdentifier = sessionCategory

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(1, minutes * 60)),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "\(sessionCategory).end",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Recurring interruptions for hyperfocus mode. Once someone is in, they
    /// will not spontaneously remember to drink water — that's the whole point.
    static func scheduleBodyChecks(totalMinutes: Int, every interval: Int) {
        guard interval > 0 else { return }
        var elapsed = interval
        var index = 0
        while elapsed < totalMinutes {
            let content = UNMutableNotificationContent()
            content.title = "Body check"
            content.body = ["Water.", "Eaten anything?", "Stand up for a second.", "Look away from the screen."][index % 4]
            content.sound = .default
            content.categoryIdentifier = sessionCategory

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(elapsed * 60),
                repeats: false
            )
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(
                    identifier: "\(sessionCategory).check.\(index)",
                    content: content,
                    trigger: trigger
                )
            )
            elapsed += interval
            index += 1
        }
    }

    static func cancelSessionNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.content.categoryIdentifier == sessionCategory }
                .map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Routines

    static func syncRoutineReminders(_ routines: [Routine]) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.content.categoryIdentifier == routineCategory }
                .map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)

            for routine in routines where routine.isEnabled {
                guard let mins = routine.reminderMinutes else { continue }
                let content = UNMutableNotificationContent()
                content.title = routine.name
                content.body = "\(routine.steps.count) small steps, about \(routine.totalMinutes) minutes."
                content.sound = .default
                content.categoryIdentifier = routineCategory

                var components = DateComponents()
                components.hour = mins / 60
                components.minute = mins % 60

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                UNUserNotificationCenter.current().add(
                    UNNotificationRequest(
                        identifier: "\(routineCategory).\(routine.id.uuidString)",
                        content: content,
                        trigger: trigger
                    )
                )
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
