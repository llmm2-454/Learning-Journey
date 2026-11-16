import SwiftUI
import Combine

// قلب التطبيق: كل القواعد هنا (الـ streak، الـ Freezes، 32 ساعة، 12 صباحًا)
final class ActivityViewModel: ObservableObject {

    @Published private(set) var goal: Goal?
    @Published private(set) var logs: [DayLog] = []      // أيام الهدف الحالي
    @Published private(set) var history: [DayLog] = []   // أيام الأهداف السابقة (للتقويم)
    @Published var now = Date()

    private let defaults = UserDefaults.standard
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)   // ميلادي دايمًا حتى لو جهازك هجري
        c.firstWeekday = 1                          // الأسبوع يبدأ الأحد
        return c
    }()

    init() { reload() }

    // MARK: - Load / Save

    func reload() {
        if let subject = defaults.string(forKey: "goalSubject"),
           let raw = defaults.string(forKey: "goalDuration"),
           let duration = LearningDuration(rawValue: raw),
           let start = defaults.object(forKey: "goalStartDate") as? Date {
            goal = Goal(subject: subject, duration: duration, startDate: start)
        } else {
            goal = nil
        }

        if let data = defaults.data(forKey: "dayLogs"),
           let decoded = try? JSONDecoder().decode([DayLog].self, from: data) {
            logs = decoded
        } else {
            logs = []
        }

        if let data = defaults.data(forKey: "dayHistory"),
           let decoded = try? JSONDecoder().decode([DayLog].self, from: data) {
            history = decoded
        } else {
            history = []
        }

        now = Date()
        resetStreakIfNeeded()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(logs) {
            defaults.set(data, forKey: "dayLogs")
        }
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: "dayHistory")
        }
    }

    // يستدعيه المؤقت كل 30 ثانية
    func tick() {
        now = Date()
        resetStreakIfNeeded()
    }

    // MARK: - Counts

    var learnedCount: Int { logs.filter { $0.status == .learned }.count }
    var frozenCount: Int { logs.filter { $0.status == .frozen }.count }
    var maxFreezes: Int { goal?.duration.maxFreezes ?? 0 }

    // MARK: - Today

    private var todayLog: DayLog? {
        logs.first { calendar.isDate($0.date, inSameDayAs: now) }
    }

    var isLearnedToday: Bool { todayLog?.status == .learned }
    var isFrozenToday: Bool { todayLog?.status == .frozen }

    // MARK: - قاعدة الـ 32 ساعة

    private var lastActivity: Date? {
        logs.map(\.loggedAt).max()
    }

    // إذا مرّ أكثر من 32 ساعة بدون تسجيل: الـ streak والفريزات يرجعون للصفر
    // الأيام القديمة تنتقل للأرشيف عشان تظهر في التقويم
    // (ما نصفّر إذا الهدف انتهى، عشان رسالة Well done ما تختفي)
    private func resetStreakIfNeeded() {
        guard state == .active,
              let last = lastActivity,
              now.timeIntervalSince(last) > 32 * 3600 else { return }

        history.removeAll { h in
            logs.contains { calendar.isDate($0.date, inSameDayAs: h.date) }
        }
        history.append(contentsOf: logs)
        logs = []
        save()
    }

    // MARK: - حالة الهدف

    var state: GoalState {
        guard let goal else { return .active }
        if learnedCount >= goal.duration.days { return .completed }

        // الهدف يفشل فقط لما تنتهي مدته بدون ما يكتمل
        let startOfGoal = calendar.startOfDay(for: goal.startDate)
        if let end = calendar.date(byAdding: .day, value: goal.duration.days, to: startOfGoal),
           now >= end {
            return .failed
        }
        return .active
    }

    // MARK: - قواعد الأزرار (مطابقة لتصميم Task 2)

    // دائرة التعلّم: تتعطل إذا اليوم انسجّل "تعلّم"
    var canLog: Bool { state == .active && !isLearnedToday }

    // زر التجميد: يتعطل إذا اليوم مجمّد أو خلصت الفريزات
    var canFreeze: Bool {
        state == .active && !isFrozenToday && frozenCount < maxFreezes
    }

    // MARK: - الأفعال

    // اليوم له حالة وحدة فقط، فنشيل القديمة قبل ما نضيف الجديدة
    private func removeTodayLog() {
        logs.removeAll { calendar.isDate($0.date, inSameDayAs: now) }
    }

    func logLearned() {
        guard canLog else { return }
        removeTodayLog()
        logs.append(DayLog(date: calendar.startOfDay(for: now), status: .learned, loggedAt: now))
        save()
    }

    func freezeDay() {
        guard canFreeze else { return }
        removeTodayLog()
        logs.append(DayLog(date: calendar.startOfDay(for: now), status: .frozen, loggedAt: now))
        save()
    }

    // MARK: - شريط الأسبوع

    var weekDays: [Date] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    func status(for date: Date) -> DayStatus? {
        logs.first { calendar.isDate($0.date, inSameDayAs: date) }?.status
    }

    // للتقويم: الهدف الحالي أولًا ثم الأرشيف
    func calendarStatus(for date: Date) -> DayStatus? {
        if let s = status(for: date) { return s }
        return history.first { calendar.isDate($0.date, inSameDayAs: date) }?.status
    }

    // أقدم تاريخ نعرضه في التقويم
    var calendarStartDate: Date {
        let candidates: [Date?] = [
            goal?.startDate,
            history.map(\.date).min(),
            logs.map(\.date).min()
        ]
        return candidates.compactMap { $0 }.min() ?? now
    }

    func isToday(_ date: Date) -> Bool { calendar.isDate(date, inSameDayAs: now) }

    func dayNumber(_ date: Date) -> String { String(calendar.component(.day, from: date)) }

    func weekdayLetter(_ date: Date) -> String {
        ["S", "M", "T", "W", "T", "F", "S"][calendar.component(.weekday, from: date) - 1]
    }

    var headerDate: String {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: now)
    }

    // إذا الرقم 1 نكتب "day" مو "days" (ملاحظة التصميم)
    func daysText(_ n: Int) -> String { "\(n) \(n == 1 ? "day" : "days")" }
}
