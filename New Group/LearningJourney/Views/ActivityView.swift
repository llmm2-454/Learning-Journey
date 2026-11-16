import SwiftUI
import Combine

class ActivityViewModel: ObservableObject {

    // كل التسجيلات (learned / frozen) تنحفظ هنا
    @Published var logs: [DayLog] = []

    // المدة اللي اختارها المستخدم في الشاشة الأولى
    @Published var duration: LearningDuration = .week

    private let calendar = Calendar.current

    /// جديد: عشان نقدر نمرر المدة من الشاشة الأولى
    init(duration: LearningDuration = .week) {
        self.duration = duration
    }

    // MARK: - الأرقام اللي تظهر في الكروت
    var streakCount: Int {
        logs.filter { $0.status == .learned }.count
    }

    var freezeCount: Int {
        logs.filter { $0.status == .frozen }.count
    }

    var maxFreezes: Int { duration.maxFreezes }

    // MARK: - حالة اليوم
    private func hasLogToday(_ status: DayStatus) -> Bool {
        logs.contains { $0.status == status && calendar.isDateInToday($0.date) }
    }

    var isLearnedToday: Bool { hasLogToday(.learned) }
    var isFrozenToday: Bool { hasLogToday(.frozen) }

    // MARK: - حالة الأزرار
    var canLogLearned: Bool { !isLearnedToday }
    var canFreeze: Bool { !isFrozenToday && freezeCount < maxFreezes }

    // MARK: - الإجراءات
    func logAsLearned() {
        guard canLogLearned else { return }
        logs.append(DayLog(date: Date(), status: .learned))
    }

    func freezeToday() {
        guard canFreeze else { return }
        logs.append(DayLog(date: Date(), status: .frozen))
    }

    // MARK: - تصفير الـ Streak
    func resetStreak() {
        logs.removeAll()
    }

    /// قاعدة الـ 32 ساعة
    func checkStreakExpiry() {
        guard let lastLog = logs.map(\.date).max() else { return }
        let hours = Date().timeIntervalSince(lastLog) / 3600
        if hours > 32 {
            resetStreak()
        }
    }

    /// تغيير الهدف يصفّر الـ Streak
    func updateGoal(duration: LearningDuration) {
        self.duration = duration
        resetStreak()
    }

    // MARK: - النصوص (Day / Days)
    func dayText(_ number: Int) -> String {
        number == 1 ? "\(number) Day" : "\(number) Days"
    }

    var freezeUsedText: String {
        "\(freezeCount) out of \(maxFreezes) Freezes used"
    }
}
