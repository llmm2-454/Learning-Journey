import SwiftUI
import Combine

// ViewModel شاشة البداية (Task 1)
final class OnboardingViewModel: ObservableObject {

    @Published var subject: String = ""
    @Published var duration: LearningDuration = .week

    private var cleanSubject: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // زر Start Learning يشتغل فقط إذا كتبتي موضوع
    var canStart: Bool { !cleanSubject.isEmpty }

    func start() {
        guard canStart else { return }
        GoalStorage.startNewGoal(subject: cleanSubject, duration: duration)
    }
}
