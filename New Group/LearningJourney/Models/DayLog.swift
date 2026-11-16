import Foundation

// حالة اليوم: تعلّمت أو جمّدت
enum DayStatus: String, Codable {
    case learned, frozen
}

// سجل يوم واحد
struct DayLog: Codable, Identifiable {
    var id: Date { date }   // سجل واحد لكل يوم، فنستخدم التاريخ كـ id
    let date: Date          // بداية اليوم (للتقويم)
    let status: DayStatus   // تعلّمت أو جمّدت
    let loggedAt: Date      // الوقت الدقيق للتسجيل (لقاعدة الـ 32 ساعة)
}
