import SwiftUI
import Combine

// ViewModel شاشة تعديل الهدف (Task 4)
final class GoalViewModel: ObservableObject {

    @Published var subject: String
    @Published var duration: LearningDuration

    // القيم الأصلية: نقارن فيها عشان نعرف هل تغيّر شي
    private let originalSubject: String
    private let originalDuration: LearningDuration

    init() {
        let d = UserDefaults.standard
        let savedSubject = d.string(forKey: "goalSubject") ?? ""
        let savedDuration = LearningDuration(rawValue: d.string(forKey: "goalDuration") ?? "") ?? .week

        subject = savedSubject
        duration = savedDuration
        originalSubject = savedSubject
        originalDuration = savedDuration
    }

    private var cleanSubject: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool { !cleanSubject.isEmpty }

    var hasChanges: Bool {
        cleanSubject != originalSubject || duration != originalDuration
    }

    // يحفظ الهدف الجديد ويصفّر الـ streak
    func update() {
        guard canSave else { return }
        GoalStorage.startNewGoal(subject: cleanSubject, duration: duration)
    }
}
