import SwiftUI

@main
struct LearningJourneyApp: App {

    // يقرأ "hasGoal" من UserDefaults، ويتحدث تلقائيًا لما نحفظ هدف جديد
    @AppStorage("hasGoal") private var hasGoal = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasGoal {
                    ActivityView()      // فيه هدف: نعرض Activity
                } else {
                    OnboardingView()    // ما فيه هدف: نعرض البداية
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
