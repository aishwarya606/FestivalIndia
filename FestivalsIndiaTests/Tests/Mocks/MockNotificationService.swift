import UserNotifications
@testable import FestivalsIndia

// L: Drop-in for NotificationServiceProtocol. No real UNUserNotificationCenter calls.
final class MockNotificationService: NotificationServiceProtocol {

    // Configurable state for each test
    var authorizationStatus: UNAuthorizationStatus = .authorized
    var shouldGrantPermission = true

    // Spies
    var requestPermissionCallCount = 0
    var scheduleRemindersCallCount = 0
    var cancelAllRemindersCallCount = 0
    var cancelRemindersForFestivalCallCount = 0
    var lastScheduledFestivals: [Festival] = []
    var lastScheduledYearRange: ClosedRange<Int>?

    func requestPermission() async -> Bool {
        requestPermissionCallCount += 1
        if shouldGrantPermission { authorizationStatus = .authorized }
        return shouldGrantPermission
    }

    func refreshStatus() { /* no-op in tests */ }

    func scheduleReminders(for festivals: [Festival], years: ClosedRange<Int>) async {
        scheduleRemindersCallCount += 1
        lastScheduledFestivals = festivals
        lastScheduledYearRange = years
    }

    func cancelAllReminders() async {
        cancelAllRemindersCallCount += 1
    }

    func cancelReminders(for festival: Festival) async {
        cancelRemindersForFestivalCallCount += 1
    }
}
