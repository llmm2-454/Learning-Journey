import SwiftUI
import Combine

// ViewModel صفحة التقويم (ملف جديد): يجهّز الشهور والخانات للـ View
// يعتمد على ActivityViewModel لأن حالات الأيام (الحالية والأرشيف) موجودة فيه
final class CalendarViewModel: ObservableObject {

    private let activity: ActivityViewModel   // مصدر البيانات
    private let calendar = Calendar(identifier: .gregorian)

    init(activity: ActivityViewModel) {
        self.activity = activity
    }

    // أول يوم في الشهر (00:00) لأي تاريخ
    private func monthStart(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    // الشهور المعروضة: من شهر أقدم يوم مسجّل، إلى شهر نهاية الهدف (أو الشهر الحالي أيهما أبعد)
    var months: [Date] {
        let first = monthStart(activity.calendarStartDate)

        var end = activity.now
        if let goal = activity.goal,
           let goalEnd = calendar.date(byAdding: .day, value: goal.duration.days, to: goal.startDate) {
            end = max(end, goalEnd)
        }
        let last = monthStart(end)

        var result: [Date] = []
        var current = first
        while current <= last {
            result.append(current)
            guard let next = calendar.date(byAdding: .month, value: 1, to: current) else { break }
            current = next
        }
        return result
    }

    // الشهر الحالي (نسكرول له أول ما تفتح الصفحة)
    var currentMonth: Date { monthStart(activity.now) }

    // خانات الشهر: خانات فاضية (nil) قبل اليوم الأول ثم تواريخ الأيام
    func cells(for month: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let offset = calendar.component(.weekday, from: month) - 1   // الأحد = 0
        let days: [Date?] = range.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: month)
        }
        return Array(repeating: nil as Date?, count: offset) + days
    }

    // عنوان الشهر (مثال: January 2026) بالإنجليزي دائماً
    func monthTitle(_ month: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: month)
    }

    // حالة اليوم (من الهدف الحالي أو الأرشيف)
    func status(for date: Date) -> DayStatus? { activity.calendarStatus(for: date) }

    func isToday(_ date: Date) -> Bool { activity.isToday(date) }
    func dayNumber(_ date: Date) -> String { activity.dayNumber(date) }
}

