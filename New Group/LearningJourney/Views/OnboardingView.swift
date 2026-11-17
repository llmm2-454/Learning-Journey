import SwiftUI

// VIEW: تعرض فقط. المنطق كله في OnboardingViewModel
struct OnboardingView: View {

    // الـ ViewModel (StateObject لأنه ObservableObject وهذي الـ View هي اللي تنشئه)
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 1) الشعار (اللهب)
            Image(systemName: "flame.fill")
                .font(.system(size: 42))
                .foregroundColor(AppColor.orange)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)

            // 2) "Hello Learner": Hello خفيف و Learner عريض
            (Text("Hello ").font(.system(size: 34, weight: .light))
             + Text("Learner").font(.system(size: 34, weight: .bold)))
                .foregroundColor(.white)
                .padding(.top, 82)

            // 3) الجملة الرمادية
            Text("This app will help you learn everyday!")
                .font(.system(size: 17))
                .foregroundColor(AppColor.secondaryText)
                .padding(.top, 2)

            // 4) النموذج: مربوط مباشرة بمتغيرات الـ ViewModel
            GoalForm(subject: $vm.subject, duration: $vm.duration)
                .padding(.top, 35)

            Spacer(minLength: 0)

            // 5) زر البدء + الملاحظة تحته
            VStack(spacing: 12) {
                Button(action: vm.start) {          // start() تحفظ الهدف وتنقلنا لصفحة Activity
                    Text("Start Learning")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)
                .disabled(!vm.canStart)             // معطل إذا الموضوع فاضي
                .opacity(vm.canStart ? 1 : 0.5)
                .appGlass(Capsule(), tint: AppColor.orange, interactive: true)

                Text("You can edit your desire later")
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .background(Color.black.ignoresSafeArea())
        .englishUI()
    }
}

#Preview { OnboardingView().preferredColorScheme(.dark) }
