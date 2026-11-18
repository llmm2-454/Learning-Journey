import SwiftUI
import Combine

// MARK: - نتيجة الهدف (تستخدم للمعاينة فقط)

enum GoalResult {
    case success
    case failure
}

// MARK: - Colors (من التصميم)

private enum Palette {
    static let orange       = Color(red: 1.00, green: 0.60, blue: 0.20)
    static let orangeDeep   = Color(red: 0.96, green: 0.54, blue: 0.15)
    static let orangeText   = Color(red: 0.96, green: 0.55, blue: 0.13)
    static let orangeBG     = Color(red: 0.16, green: 0.10, blue: 0.06)
    static let cyan         = Color(red: 0.18, green: 0.77, blue: 0.95)
    static let cyanBG       = Color(red: 0.05, green: 0.15, blue: 0.20)
    static let circleBG     = Color(white: 0.17)
    static let cardBG       = Color(white: 0.055)
    static let gray         = Color(white: 0.56)
    static let disabledText = Color(white: 0.35)
}

// MARK: - Main View

struct ActivityView: View {

    // MARK: الـ ViewModel (مصدر الحقيقة الوحيد)
    // كل الأرقام والحالات والأفعال تجي منه، والـ View بس تعرض

    @StateObject private var activity = ActivityViewModel()

    // MARK: حالة العرض فقط (فتح الشاشات)

    @State private var showCalendar = false   // أيقونة التقويم
    @State private var showGoal = false       // أيقونة الهدف + زر Set a goal

    // للمعاينة فقط: لو حطيتي قيمة هنا تظهر شاشة النجاح أو الفشل مباشرة
    // في التطبيق الحقيقي تكون nil، والنتيجة تجي من حالة الهدف الحقيقية
    private let previewResult: GoalResult?

    // مؤقت كل 30 ثانية يحدّث الوقت وحالة الأزرار (قاعدة الـ 32 ساعة)
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    init(previewResult: GoalResult? = nil) {
        self.previewResult = previewResult
    }

    // MARK: حالات مساعدة

    /// النتيجة اللي تنعرض: nil = الهدف شغال
    private var resultToShow: GoalResult? {
        if let previewResult { return previewResult }       // وضع المعاينة
        if activity.state == .completed { return .success } // الهدف اكتمل
        if activity.state == .failed { return .failure }    // الهدف فشل
        return nil                                          // الهدف شغال
    }

    /// ما فيه هدف محفوظ؟ نوقف الأزرار
    private var hasGoal: Bool { activity.goal != nil }

    // الأزرار تنفتح أو تنقفل حسب قواعد الـ ViewModel
    private var logDisabled: Bool { !hasGoal || !activity.canLog }
    private var freezeDisabled: Bool { !hasGoal || !activity.canFreeze }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 16)

                weekRow
                    .padding(.leading, 9)
                    .padding(.trailing, 6)
                    .padding(.top, resultToShow == nil ? 16 : 20)

                statsCards
                    .padding(.horizontal, 14)
                    .padding(.top, 12)

                // نختار الشاشة: نتيجة (Well done / فشل) أو الأزرار
                if let result = resultToShow {
                    resultSection(success: result == .success)
                        .padding(.top, 67)
                } else {
                    activeSection
                        .padding(.top, 49)
                }

                Spacer(minLength: 0)
            }
        }
        .preferredColorScheme(.dark)
        .englishUI()
        // نحدّث البيانات كل ما تفتح الشاشة، وكل 30 ثانية
        .onAppear { activity.reload() }
        .onReceive(timer) { _ in activity.tick() }
        // الشاشات اللي تنفتح لما تضغط الأزرار
        .fullScreenCover(isPresented: $showCalendar) {
            CalendarView(activity: activity)
        }
        // لما تتسكر شاشة الهدف نعيد قراءة الهدف الجديد المحفوظ
        .fullScreenCover(isPresented: $showGoal, onDismiss: { activity.reload() }) {
            GoalView()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                // التاريخ الحقيقي من الـ ViewModel (مو نص ثابت)
                Text(activity.headerDate)
                    .font(.system(size: 17))
                    .foregroundColor(Palette.gray)
            }
            Spacer()
            HStack(spacing: 12) {
                circleButton(systemName: "calendar") { showCalendar = true }
                circleButton(systemName: "pencil.tip.crop.circle") { showGoal = true }
            }
            .padding(.top, 2)
        }
        .padding(.top, 6)
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Palette.circleBG)
                .clipShape(Circle())
                .overlay(Circle().stroke(rim(top: 0.22, bottom: 0.05), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Week Row (الأسبوع الحقيقي من الـ ViewModel)

    private var weekRow: some View {
        HStack(spacing: 0) {
            ForEach(activity.weekDays, id: \.self) { date in
                VStack(spacing: 6) {
                    Text(activity.weekdayLetter(date))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text(activity.dayNumber(date))
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(dayTextColor(for: date))
                        .frame(width: 44, height: 44)
                        .background(dayBackgroundColor(for: date))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // لون رقم اليوم: تعلّم = برتقالي، تجميد = أزرق، غير ذلك = أبيض
    private func dayTextColor(for date: Date) -> Color {
        guard let status = activity.status(for: date) else { return .white }
        return status == .learned ? Palette.orangeText : Palette.cyan
    }

    // خلفية الدائرة: اليوم الحالي بدون تسجيل = برتقالي كامل، الأيام العادية = شفاف
    private func dayBackgroundColor(for date: Date) -> Color {
        if let status = activity.status(for: date) {
            return status == .learned ? Palette.orangeBG : Palette.cyanBG
        }
        return activity.isToday(date) ? Palette.orange : Color.clear
    }

    // MARK: - Stats Cards

    private var statsCards: some View {
        HStack(spacing: 14) {
            statCard(icon: "flame.fill", color: Palette.orange,
                     value: activity.daysText(activity.learnedCount), label: "Learned")
            statCard(icon: "snowflake", color: Palette.cyan,
                     value: activity.daysText(activity.frozenCount), label: "Freezed")
        }
    }

    private func statCard(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(height: 24)
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 10)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 100, alignment: .top)
        .background(Palette.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(rim(top: 0.28, bottom: 0.06), lineWidth: 1)
        )
    }

    // MARK: - Active Section (الهدف شغال)

    private var activeSection: some View {
        VStack(spacing: 0) {

            // الدائرة الكبيرة (272 × 272)
            // الضغطة تنادي الـ ViewModel اللي يحفظ DayLog بالتاريخ الحقيقي
            Button(action: { activity.logLearned() }) {
                Text(activity.isLearnedToday ? "Logged as Learned" : "Log as Learned")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(logDisabled ? Palette.disabledText : .white)
                    .frame(width: 272, height: 272)
                    .background(logDisabled ? Color(white: 0.11) : Palette.orangeDeep)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(rim(top: 0.40, bottom: 0.08), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .disabled(logDisabled)

            // زر Freeze (272 × 45)
            Button(action: { activity.freezeDay() }) {
                Text(activity.isFrozenToday ? "Freezed for a day" : "Freeze for a day")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(freezeDisabled ? Palette.disabledText : .white)
                    .frame(width: 272, height: 45)
                    .background(freezeDisabled ? Color(white: 0.10) : Palette.cyan)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(rim(top: 0.40, bottom: 0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(freezeDisabled)
            .padding(.top, 49)

            // الحد الأقصى حسب مدة الهدف (أسبوع / شهر / سنة)
            Text("\(activity.frozenCount) out of \(activity.maxFreezes) Freezes used")
                .font(.system(size: 14))
                .foregroundColor(Palette.gray)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Result Section (الهدف انتهى)

    private func resultSection(success: Bool) -> some View {
        VStack(spacing: 0) {
            Image(systemName: success ? "hands.sparkles.fill" : "xmark.seal")
                .font(.system(size: 42))
                .foregroundColor(Palette.orange)
                .frame(height: 46)

            Text(success ? "Well done!" : "You didn't reach your goal this time.")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 20)

            Text(success ? "Ready for your next goal?" : "Want to set another goal?")
                .font(.system(size: 14))
                .foregroundColor(Palette.gray)
                .padding(.top, 5)

            Button {
                showGoal = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.tip.crop.circle")
                        .font(.system(size: 17))
                    Text("Set a goal")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 23)
                .frame(height: 50)
                .background(Palette.orange)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 74)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper

    /// الحدود اللامعة الخفيفة اللي حوالين العناصر في التصميم
    private func rim(top: Double, bottom: Double) -> LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(top), Color.white.opacity(bottom)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Previews

#Preview("Interactive") {
    ActivityView()
}

#Preview("Success - Well done") {
    ActivityView(previewResult: .success)
}

#Preview("Failure") {
    ActivityView(previewResult: .failure)
}
