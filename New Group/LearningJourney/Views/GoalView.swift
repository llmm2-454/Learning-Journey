import SwiftUI

// VIEW: تعرض فقط. المنطق في GoalViewModel
struct GoalView: View {

    @Environment(\.dismiss) private var dismiss      // للرجوع للصفحة السابقة
    @StateObject private var vm = GoalViewModel()    // الـ ViewModel
    @State private var showConfirm = false           // إظهار نافذة التأكيد (حالة واجهة بحتة)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // 1) الشريط العلوي
                ZStack {
                    Text("Learning Goal")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    HStack {
                        GlassIconButton(systemName: "chevron.left") { dismiss() }
                        Spacer()
                        // زر الصح: إذا فيه تغيير نطلع التأكيد، وإذا ما تغيّر شي نرجع مباشرة
                        GlassIconButton(systemName: "checkmark", tint: AppColor.orange) {
                            if vm.hasChanges { showConfirm = true } else { dismiss() }
                        }
                        .disabled(!vm.canSave)              // معطل إذا الموضوع فاضي
                        .opacity(vm.canSave ? 1 : 0.4)
                    }
                }

                // 2) النموذج مربوط بالـ ViewModel
                GoalForm(subject: $vm.subject, duration: $vm.duration)
                    .padding(.top, 43)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)

            // 3) نافذة التأكيد
            if showConfirm {
                // التصميم يعرض الخلفية رمادية. للتعتيم العادي بدّلها بـ Color.black.opacity(0.5)
                Color(white: 0.48).opacity(0.92)
                    .ignoresSafeArea()
                    .onTapGesture { showConfirm = false }   // الضغط برا يقفلها
                confirmCard
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: showConfirm)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .englishUI()
    }

    // MARK: - نافذة التأكيد (300 × 183، زوايا 40)

    private var confirmCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            // العنوان والنص
            VStack(alignment: .leading, spacing: 12) {
                Text("Update goal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("If you update now, your streak will start over.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(white: 0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)

            HStack(spacing: 8) {
                // Dismiss: يقفل النافذة بس
                Button { showConfirm = false } label: {
                    Text("Dismiss")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 47)
                }
                .buttonStyle(.plain)
                .appGlass(Capsule(), tint: Color(white: 0.2), interactive: true)

                // Update: الـ ViewModel يحفظ الهدف الجديد ويصفّر الستريك، والـ View ترجع
                Button {
                    vm.update()
                    showConfirm = false
                    dismiss()
                } label: {
                    Text("Update")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 47)
                }
                .buttonStyle(.plain)
                .appGlass(Capsule(), tint: AppColor.orange, interactive: true)
            }
            .padding(.top, 30)
        }
        .padding(EdgeInsets(top: 23, leading: 14, bottom: 15, trailing: 14))
        .frame(width: 300)
        .appGlass(RoundedRectangle(cornerRadius: 40, style: .continuous), tint: Color(white: 0.11))
        .shadow(color: .black.opacity(0.35), radius: 28, y: 12)
    }
}

#Preview { GoalView().preferredColorScheme(.dark) }
