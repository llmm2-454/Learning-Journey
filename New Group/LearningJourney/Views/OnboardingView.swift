import SwiftUI

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // الأيقونة
                HStack {
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColor.orange)
                        .frame(width: 100, height: 100)
                        .background(Circle().fill(Color(white: 0.12)))
                    Spacer()
                }
                .padding(.top, 60)

                // العنوان
                Text("Hello Learner")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 28)

                Text("This app will help you learn everyday!")
                    .font(.system(size: 17))
                    .foregroundColor(AppColor.secondaryText)
                    .padding(.top, 6)

                subjectField.padding(.top, 36)
                durationPicker.padding(.top, 32)

                Spacer()

                // زر البداية
                VStack(spacing: 10) {
                    Button { vm.start() } label: {
                        Text("Start Learning")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 14)
                            .background(OrangeCapsuleBackground())
                    }
                    .buttonStyle(.plain)
                    .disabled(!vm.canStart)
                    .opacity(vm.canStart ? 1 : 0.5)

                    Text("You can edit your desire later")
                        .font(.system(size: 13))
                        .foregroundColor(AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - حقل الموضوع

    private var subjectField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("I want to learn")
                .font(.system(size: 17))
                .foregroundColor(.white)

            TextField(
                "",
                text: $vm.subject,
                prompt: Text("Swift").foregroundColor(AppColor.placeholder)
            )
            .font(.system(size: 17))
            .foregroundColor(.white)
            .tint(AppColor.orange)
            .padding(.top, 6)

            Rectangle()
                .fill(AppColor.divider)
                .frame(height: 1)
        }
    }

    // MARK: - اختيار المدة

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("I want to learn it in a")
                .font(.system(size: 17))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                ForEach(LearningDuration.allCases) { item in
                    let isSelected = vm.duration == item
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { vm.duration = item }
                    } label: {
                        Text(item.rawValue)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(isSelected ? .white : AppColor.secondaryText)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 11)
                            .background(
                                Group {
                                    if isSelected {
                                        OrangeCapsuleBackground()
                                    } else {
                                        GrayCapsuleBackground()
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
}
