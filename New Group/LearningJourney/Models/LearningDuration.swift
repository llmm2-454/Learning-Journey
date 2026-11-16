import Foundation

// مدة الهدف: أسبوع / شهر / سنة
// Identifiable: عشان ForEach يعرف كل خيار. Codable: عشان نقدر نحفظه
enum LearningDuration: String, CaseIterable, Identifiable, Codable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }

    // عدد أيام الهدف
    var days: Int {
        switch self {
        case .week:  return 7
        case .month: return 30
        case .year:  return 365
        }
    }

    // الحد الأقصى للـ Freezes (من ملاحظات التصميم)
    var maxFreezes: Int {
        switch self {
        case .week:  return 2
        case .month: return 8
        case .year:  return 96
        }
    }
}
