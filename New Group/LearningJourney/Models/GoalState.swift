import Foundation

// الهدف: إيش أتعلم؟ كم المدة؟ ومتى بدأ؟
struct Goal: Codable {
    var subject: String
    var duration: LearningDuration
    var startDate: Date
}

// حالة الهدف
enum GoalState: String {
    case active      // شغّال
    case completed   // انتهى بنجاح
    case failed      // انتهت مدته بدون ما يكتمل
}
