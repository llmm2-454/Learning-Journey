import Foundation

// يحفظ الهدف الجديد في UserDefaults
enum GoalStorage {

    private static let calendar = Calendar(identifier: .gregorian)

    // يبدأ هدف جديد: يأرشف أيام الهدف القديم (للتقويم) ويصفّر الجديد
    static func startNewGoal(subject: String, duration: LearningDuration) {
        let d = UserDefaults.standard
        let decoder = JSONDecoder()

        let old: [DayLog] = d.data(forKey: "dayLogs")
            .flatMap { try? decoder.decode([DayLog].self, from: $0) } ?? []
        var history: [DayLog] = d.data(forKey: "dayHistory")
            .flatMap { try? decoder.decode([DayLog].self, from: $0) } ?? []

        // نشيل المكرر من الأرشيف ثم نضيف السجل القديم
        history.removeAll { h in
            old.contains { calendar.isDate($0.date, inSameDayAs: h.date) }
        }
        history.append(contentsOf: old)

        if let data = try? JSONEncoder().encode(history) {
            d.set(data, forKey: "dayHistory")
        }

        // نصفّر الهدف الحالي ونحفظ الجديد
        d.removeObject(forKey: "dayLogs")
        d.set(subject, forKey: "goalSubject")
        d.set(duration.rawValue, forKey: "goalDuration")
        d.set(Date(), forKey: "goalStartDate")
        d.set(true, forKey: "hasGoal")
    }
}
