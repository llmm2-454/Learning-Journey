import SwiftUI
import Combine

final class ActivityViewModel: ObservableObject {

    // MARK: - الحالة (الـ View تراقبها وتتحدث لما تتغير)

    @Published private(set) var goal: Goal?          // الهدف الحالي (nil = ما فيه هدف)
    @Published private(set) var logs: [DayLog] = []  // أيام الهدف الحالي (تعلّم / تجميد)
    @Published private(set) var history: [DayLog] = []  // أرشيف أيام الأهداف القديمة (للتقويم فقط)
    @Published var now = Date()                      // الوقت الحالي (يتحدث بـ tick)

    private let defaults = UserDefaults.standard
    // تقويم ميلادي، وأول يوم في الأسبوع الأحد
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1
        return c
    }()

    // أول ما ينشأ الـ ViewModel نقرأ كل شي من التخزين
    init() { reload() }

    // MARK: - Load / Save

    // يقرأ الهدف والسجل والأرشيف من UserDefaults
    func reload() {
        // 1) الهدف: لازم تكون كل قيمه موجودة، وإلا نعتبر ما فيه هدف
        if let subject = defaults.string(forKey: "goalSubject"),
           let raw = defaults.string(forKey: "goalDuration"),
           let duration = LearningDuration(rawValue: raw),
           let start = defaults.object(forKey: "goalStartDate") as? Date {
            goal = Goal(subject: subject, duration: duration, startDate: start)
        } else {
            goal = nil
        }

        // 2) سجل أيام الهدف الحالي
        if let data = defaults.data(forKey: "dayLogs"),
           let decoded = try? JSONDecoder().decode([DayLog].self, from: data) {
            logs = decoded
        } else {
            logs = []
        }

        // 3) أرشيف الأيام القديمة
        if let data = defaults.data(forKey: "dayHistory"),
           let decoded = try? JSONDecoder().decode([DayLog].self, from: data) {
            history = decoded
        } else {
            history = []
        }

        now = Date()            // نحدّث الوقت
        resetStreakIfNeeded()   // ✏️ جديد: نتحقق هل انكسر الستريك
    }

    // ✏️ صار يحفظ السجل والأرشيف الاثنين
    private func save() {
        // نحفظ سجل الهدف الحالي
        if let data = try? JSONEncoder().encode(logs) {
            defaults.set(data, forKey: "dayLogs")
        }
        // ونحفظ الأرشيف
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: "dayHistory")
        }
    }

    // يُنادى بشكل دوري من الـ View (مؤقت) عشان الوقت وحالة الأزرار تتحدث
    func tick() {
        now = Date()
        resetStreakIfNeeded()   // ✏️ جديد: نتحقق كل 30 ثانية
    }

    // MARK: - العدادات

    var learnedCount: Int { logs.filter { $0.status == .learned }.count }  // أيام التعلّم
    var frozenCount: Int { logs.filter { $0.status == .frozen }.count }    // أيام التجميد
    var maxFreezes: Int { goal?.duration.maxFreezes ?? 0 }                 // الحد الأقصى حسب مدة الهدف

    // MARK: - اليوم الحالي

    // سجل اليوم الحالي (nil إذا ما سجّلتي شي اليوم)
    private var todayLog: DayLog? {
        logs.first { calendar.isDate($0.date, inSameDayAs: now) }
    }

    var isLearnedToday: Bool { todayLog?.status == .learned }  // سجّلتي تعلّم اليوم؟
    var isFrozenToday: Bool { todayLog?.status == .frozen }    // جمّدتي اليوم؟

    // MARK: - إعادة الستريك (قاعدة الـ 32 ساعة)

    // ✏️ جديد: آخر وقت سجّلتي فيه (تعلّم أو تجميد)
    private var lastActivity: Date? {
        logs.map(\.loggedAt).max()
    }

    // ✏️ جديد: إذا مرّ أكثر من 32 ساعة بدون تسجيل، الـ streak والفريزات يرجعون للصفر
    // الأيام القديمة ما تنحذف، تنتقل للأرشيف عشان تظهر في التقويم
    private func resetStreakIfNeeded() {
        // نكمل فقط إذا فيه نشاط سابق ومرّ عليه أكثر من 32 ساعة
        guard let last = lastActivity,
              now.timeIntervalSince(last) > 32 * 3600 else { return }

        // نشيل من الأرشيف أي يوم مكرر ثم نضيف السجل الحالي
        history.removeAll { h in
            logs.contains { calendar.isDate($0.date, inSameDayAs: h.date) }
        }
        history.append(contentsOf: logs)   // ننقل السجل الحالي للأرشيف
        logs = []                          // نصفّر السجل (الستريك والفريزات = 0)
        save()                             // نحفظ التغيير
    }

    // MARK: - حالة الهدف

    // ✏️ تعديل: فشل الهدف صار فقط لما تنتهي مدته بدون ما يكتمل
    // قبل: كان يفشل بعد 32 ساعة، وهذا يخالف التصميم
    var state: GoalState {
        guard let goal else { return .active }                        // ما فيه هدف = نعتبره active
        if learnedCount >= goal.duration.days { return .completed }   // وصلنا عدد الأيام المطلوب = نجاح

        // نحسب وقت نهاية الهدف = بداية يوم البدء + عدد أيام المدة
        let startOfGoal = calendar.startOfDay(for: goal.startDate)
        if let end = calendar.date(byAdding: .day, value: goal.duration.days, to: startOfGoal),
           now >= end {
            return .failed   // انتهت المدة وما اكتمل = فشل
        }
        return .active       // لسا الوقت متاح
    }

    // MARK: - قواعد الأزرار

    // ✏️ تعديل: الزر الكبير يشتغل إذا الهدف شغال وما سجّلتي "تعلّمت" اليوم
    // (يسمح تغيّرين من تجميد إلى تعلّم، مثل التصميم)
    var canLog: Bool { state == .active && !isLearnedToday }

    // ✏️ تعديل: التجميد يشتغل إذا الهدف شغال واليوم مو متجمّد أصلاً وما وصلنا الحد الأقصى
    // (يسمح تجمّدين حتى بعد ما سجّلتي "تعلّمت"، مثل التصميم)
    var canFreeze: Bool {
        state == .active && !isFrozenToday && frozenCount < maxFreezes
    }

    // MARK: - الأفعال

    // تسجيل اليوم كـ "تعلّمت"
    func logLearned() {
        guard canLog else { return }   // ما نسجّل إذا مو مسموح
        setToday(.learned)
    }

    // تجميد اليوم
    func freezeDay() {
        guard canFreeze else { return }   // ما نجمّد إذا مو مسموح
        setToday(.frozen)
    }

    // ✏️ جديد: يستبدل حالة اليوم الحالية بالجديدة (يوم واحد = حالة وحدة) ثم يحفظ
    private func setToday(_ status: DayStatus) {
        logs.removeAll { calendar.isDate($0.date, inSameDayAs: now) }   // نشيل حالة اليوم القديمة
        logs.append(DayLog(date: calendar.startOfDay(for: now), status: status, loggedAt: now))
        save()
    }

    // MARK: - شريط الأسبوع

    // أيام الأسبوع الحالي السبعة (الأحد → السبت)
    var weekDays: [Date] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    // حالة يوم معيّن من سجل الهدف الحالي (nil = ما فيه شي)
    func status(for date: Date) -> DayStatus? {
        logs.first { calendar.isDate($0.date, inSameDayAs: date) }?.status
    }

    // حالة اليوم للتقويم: نبحث في الحالي أولاً ثم في الأرشيف
    func calendarStatus(for date: Date) -> DayStatus? {
        if let s = status(for: date) { return s }
        return history.first { calendar.isDate($0.date, inSameDayAs: date) }?.status
    }

    // أول تاريخ يبدأ منه التقويم: أقدم تاريخ بين الهدف والأرشيف والسجل
    var calendarStartDate: Date {
        let candidates: [Date?] = [
            goal?.startDate,
            history.map(\.date).min(),
            logs.map(\.date).min()
        ]
        return candidates.compactMap { $0 }.min() ?? now
    }

    // هل هذا التاريخ هو اليوم؟
    func isToday(_ date: Date) -> Bool { calendar.isDate(date, inSameDayAs: now) }

    // رقم اليوم في الشهر كنص (مثال: "24")
    func dayNumber(_ date: Date) -> String { String(calendar.component(.day, from: date)) }

    // حرف اليوم (S M T W T F S) حسب رقم اليوم في الأسبوع
    func weekdayLetter(_ date: Date) -> String {
        ["S", "M", "T", "W", "T", "F", "S"][calendar.component(.weekday, from: date) - 1]
    }

    // تاريخ اليوم للهيدر (مثال: Thursday, 24 October) بالإنجليزي دائماً
    var headerDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: now)
    }

    // نص العدد: "1 day" أو "4 days" (يعالج المفرد والجمع)
    func daysText(_ n: Int) -> String { "\(n) \(n == 1 ? "day" : "days")" }
}
