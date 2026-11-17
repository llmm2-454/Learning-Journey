import SwiftUI

// MARK: - الألوان (كل ألوان التطبيق في مكان واحد)
enum AppColor {
    static let orange = Color(red: 1.00, green: 0.57, blue: 0.19)   // البرتقالي #FF9230
    static let blue = Color(red: 0.24, green: 0.83, blue: 1.00)     // الأزرق (التجميد) #3DD4FF
    static let learnedFill = orange.opacity(0.18)                   // خلفية يوم "تعلّمت"
    static let frozenFill = blue.opacity(0.18)                      // خلفية يوم "تجميد"
    static let secondaryText = Color(white: 0.55)                   // النص الرمادي
    static let placeholder = Color(white: 0.30)                     // نص الـ placeholder
    static let darkGlass = Color(white: 0.11)                       // زجاج داكن (الأزرار المعطلة)
    static let disabledText = Color(white: 0.36)                    // نص الأزرار المعطلة
}

// MARK: - أدوات مشتركة
extension View {
    // قلاس إيفكت (iOS 26) مع لون tint اختياري وتفاعل اختياري
    func appGlass<S: Shape>(_ shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        let base = tint == nil ? Glass.regular : Glass.regular.tint(tint!)
        return self.glassEffect(interactive ? base.interactive() : base, in: shape)
    }

    // يثبّت الواجهة إنجليزي ولتر (مثل التصميم) حتى لو الجوال عربي
    func englishUI() -> some View {
        self.environment(\.locale, Locale(identifier: "en_US"))
            .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - زر دائري زجاجي 44×44 (رجوع، تقويم، تعديل هدف، تأكيد)
struct GlassIconButton: View {
    let systemName: String        // اسم الأيقونة
    var tint: Color? = nil        // لون الزجاج (اختياري)
    let action: () -> Void        // اللي يصير عند الضغط

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .appGlass(Circle(), tint: tint, interactive: true)
    }
}

// MARK: - شيب المدة (Week / Month / Year)
struct DurationChip: View {
    let title: String             // النص
    let selected: Bool            // هل هو المختار؟
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(selected ? .white : AppColor.placeholder)
                .padding(.horizontal, 20)
                .frame(height: 44)
        }
        .buttonStyle(.plain)
        // برتقالي إذا مختار، داكن إذا لا
        .appGlass(Capsule(), tint: selected ? AppColor.orange : AppColor.darkGlass, interactive: true)
    }
}

// MARK: - نموذج الهدف (مشترك بين Onboarding و GoalView)
struct GoalForm: View {
    @Binding var subject: String                // الموضوع (من الـ ViewModel)
    @Binding var duration: LearningDuration     // المدة (من الـ ViewModel)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // العنوان الأول
            Text("I want to learn")
                .font(.system(size: 17))
                .foregroundColor(.white)

            // حقل الموضوع
            TextField("", text: $subject,
                      prompt: Text("Swift").foregroundColor(AppColor.placeholder))
                .font(.system(size: 17))
                .foregroundColor(.white)
                .padding(.top, 16)

            // الخط تحت الحقل
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)
                .padding(.top, 13)

            // العنوان الثاني
            Text("I want to learn it in a")
                .font(.system(size: 17))
                .foregroundColor(.white)
                .padding(.top, 28)

            // الشيبس: Week / Month / Year
            HStack(spacing: 13) {
                ForEach(LearningDuration.allCases) { item in
                    DurationChip(title: item.rawValue, selected: duration == item) {
                        duration = item
                    }
                }
            }
            .padding(.top, 13)
            .padding(.leading, 2)
        }
    }
}
