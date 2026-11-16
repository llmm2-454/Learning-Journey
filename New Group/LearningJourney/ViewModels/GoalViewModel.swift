import SwiftUI
import Combine

class GoalViewModel: ObservableObject {

    // المسودة: التعديلات المؤقتة
    @Published var topic: String
    @Published var selectedDuration: LearningDuration
    @Published var showUpdateAlert: Bool = false

    /// نستقبل الموضوع والمدة مباشرة (بدل LearningGoal)
    init(topic: String, duration: LearningDuration) {
        self.topic = topic
        self.selectedDuration = duration
    }

    /// النص بعد حذف المسافات والأسطر الجديدة
    var cleanTopic: String {
        topic.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// علامة الصح ما تشتغل إذا الحقل فاضي
    var isUpdateEnabled: Bool {
        !cleanTopic.isEmpty
    }

    /// عند الضغط على علامة الصح: نطلع التنبيه
    func askToUpdate() {
        showUpdateAlert = true
    }
}
