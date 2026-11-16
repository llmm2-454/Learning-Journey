import SwiftUI

// شاشة تعديل الهدف، وتُستخدم كمان لبدء هدف جديد بعد ما ينتهي الهدف (Task 3)
struct GoalView: View {

    // هل الهدف الحالي انتهى؟ إذا إي، ✓ تبدأ الهدف مباشرة بدون تنبيه
    var goalEnded: Bool = false

    @StateObject private var vm = GoalViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                topBar
                subjectField.padding(.top, 36)
                durationPicker.padding(.top, 32)
                Spacer()
            }
            .padding(.horizontal, 16)
            .disabled(showAlert)

            if showAlert {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { showAlert = false }
                alertCard
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.2), value: showAlert)
        .onAppear { focused = true }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // وش يصير لما نضغط ✓
    private func confirmTapped() {
        focused = false

        if goalEnded {
            vm.update()
            dismiss()
        } else if vm.hasChanges {
            showAlert = true      // نحذّر إن الـ streak يبدأ من جديد
        } else {
            dismiss()             // ما تغيّر شي
        }
    }

    // MARK: - الشريط العلوي

    private var topBar: some View {
        ZStack {
            Text("Learning Goal")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            HStack {
                // زر الرجوع (زجاجي رمادي)
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(GlassBackground(shape: Circle()))
                }
                .buttonStyle(.plain)

                Spacer()

                // علامة ✓ (زجاجية برتقالية)
                Button { confirmTapped() } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(GlassBackground(shape: Circle(), color: AppColor.orange))
                        .shadow(color: AppColor.orange.opacity(0.35), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(!vm.canSave)
                .opacity(vm.canSave ? 1 : 0.5)
            }
        }
        .padding(.top, 8)
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
            .focused($focused)
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

    // MARK: - تنبيه Update goal

    private var alertCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Update goal")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Text("If you update now, your streak will start over.")
                .font(.system(size: 15))
                .foregroundColor(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button { showAlert = false } label: {
                    Text("Dismiss")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(GrayCapsuleBackground())
                }
                Button {
                    vm.update()
                    dismiss()
                } label: {
                    Text("Update")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(OrangeCapsuleBackground())
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
        }
        .padding(18)
        .frame(width: 300)
        .background(
            GlassBackground(shape: RoundedRectangle(cornerRadius: 30, style: .continuous))
        )
    }
}

#Preview {
    NavigationStack {
        GoalView()
    }
}
