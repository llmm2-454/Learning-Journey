import SwiftUI

// MARK: - Model

enum WeekDayStatus {
    case learned   // دائرة بنية + رقم برتقالي
    case frozen    // دائرة كحلية + رقم أزرق
    case today     // اليوم الحالي ولسا ما سجلته
    case none      // يوم عادي
}

struct WeekDay: Identifiable {
    let id = UUID()
    let letter: String
    let number: Int
    let status: WeekDayStatus

    /// يبني أسبوع كامل (S M T W T F S من 20 إلى 26) من قائمة حالات
    static func week(_ statuses: [WeekDayStatus]) -> [WeekDay] {
        let letters = ["S", "M", "T", "W", "T", "F", "S"]
        return statuses.enumerated().map { index, status in
            WeekDay(letter: letters[index], number: 20 + index, status: status)
        }
    }
}

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

    // MARK: الحالة (تتغير لما تضغط الأزرار)

    @State private var learnedDays: Int
    @State private var frozenDays: Int
    @State private var weekDays: [WeekDay]
    @State private var isLoggedToday = false
    @State private var isFrozenToday = false
    @State private var freezesUsed = 0

    // فتح الشاشات الثانية
    @State private var showCalendar = false   // أيقونة التقويم
    @State private var showGoal = false       // أيقونة الهدف + زر Set a goal

    // التقويم يحتاج ActivityViewModel عشان يعرض حالات الأيام
    @StateObject private var activity = ActivityViewModel()

    // MARK: قيم ثابتة

    private let maxFreezes = 2
    private let todayIndex = 4          // اليوم 24 (الخانة الخامسة في الأسبوع)
    private let dateText = "Thursday, 24 October"

    /// nil = الهدف شغال، .success / .failure = الهدف انتهى
    private let goalResult: GoalResult?

    // MARK: init
    // ActivityView() بدون أي شي تشتغل مثل ما هي، والباقي للمعاينة

    init(
        goalResult: GoalResult? = nil,
        learnedDays: Int = 4,
        frozenDays: Int = 0,
        weekDays: [WeekDay] = WeekDay.week([.learned, .learned, .learned, .learned, .today, .none, .none])
    ) {
        self.goalResult = goalResult
        _learnedDays = State(initialValue: learnedDays)
        _frozenDays = State(initialValue: frozenDays)
        _weekDays = State(initialValue: weekDays)
    }

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
                    .padding(.top, goalResult == nil ? 16 : 20)

                statsCards
                    .padding(.horizontal, 14)
                    .padding(.top, 12)

                if let goalResult {
                    resultSection(goalResult)
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
        // الشاشات اللي تنفتح لما تضغط الأزرار
        .fullScreenCover(isPresented: $showCalendar) {
            CalendarView(activity: activity)
        }
        .fullScreenCover(isPresented: $showGoal) {
            GoalView()
        }
    }

    // MARK: - المنطق (اللي يصير لما تضغط)

    /// زر Log as Learned
    private func logAsLearned() {
        guard !isLoggedToday else { return }

        // إذا اليوم كان مجمّد، نلغي التجميد أول
        if isFrozenToday {
            frozenDays -= 1
            freezesUsed -= 1
            isFrozenToday = false
        }

        learnedDays += 1
        isLoggedToday = true
        setTodayStatus(.learned)
    }

    /// زر Freeze for a day
    private func freezeToday() {
        guard !isFrozenToday, freezesUsed < maxFreezes else { return }

        // إذا اليوم كان مسجّل Learned، نلغيه أول
        if isLoggedToday {
            learnedDays -= 1
            isLoggedToday = false
        }

        frozenDays += 1
        freezesUsed += 1
        isFrozenToday = true
        setTodayStatus(.frozen)
    }

    /// يغيّر لون دائرة اليوم في شريط الأسبوع
    private func setTodayStatus(_ status: WeekDayStatus) {
        let old = weekDays[todayIndex]
        weekDays[todayIndex] = WeekDay(letter: old.letter, number: old.number, status: status)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Text(dateText)
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

    // MARK: - Week Row

    private var weekRow: some View {
        HStack(spacing: 0) {
            ForEach(weekDays) { day in
                VStack(spacing: 6) {
                    Text(day.letter)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(day.number)")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(textColor(for: day.status))
                        .frame(width: 44, height: 44)
                        .background(backgroundColor(for: day.status))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func textColor(for status: WeekDayStatus) -> Color {
        switch status {
        case .learned: return Palette.orangeText
        case .frozen:  return Palette.cyan
        case .today:   return .white
        case .none:    return .white
        }
    }

    private func backgroundColor(for status: WeekDayStatus) -> Color {
        switch status {
        case .learned: return Palette.orangeBG
        case .frozen:  return Palette.cyanBG
        case .today:   return Palette.orange
        case .none:    return .clear
        }
    }

    // MARK: - Stats Cards

    private var statsCards: some View {
        HStack(spacing: 14) {
            statCard(icon: "flame.fill", color: Palette.orange,
                     value: "\(learnedDays) days", label: "Learned")
            statCard(icon: "snowflake", color: Palette.cyan,
                     value: "\(frozenDays) days", label: "Freezed")
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

    private var freezeDisabled: Bool {
        isFrozenToday || freezesUsed >= maxFreezes
    }

    private var activeSection: some View {
        VStack(spacing: 0) {

            // الدائرة الكبيرة (272 × 272)
            Button(action: logAsLearned) {
                Text(isLoggedToday ? "Logged as Learned" : "Log as Learned")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isLoggedToday ? Palette.disabledText : .white)
                    .frame(width: 272, height: 272)
                    .background(isLoggedToday ? Color(white: 0.11) : Palette.orangeDeep)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(rim(top: 0.40, bottom: 0.08), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .disabled(isLoggedToday)

            // زر Freeze (272 × 45)
            Button(action: freezeToday) {
                Text(isFrozenToday ? "Freezed for a day" : "Freeze for a day")
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

            Text("\(freezesUsed) out of \(maxFreezes) Freezes used")
                .font(.system(size: 14))
                .foregroundColor(Palette.gray)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Result Section (الهدف انتهى)

    private func resultSection(_ result: GoalResult) -> some View {
        VStack(spacing: 0) {
            Image(systemName: result == .success ? "hands.sparkles.fill" : "xmark.seal")
                .font(.system(size: 42))
                .foregroundColor(Palette.orange)
                .frame(height: 46)

            // النص مطابق للتصميم حرفيًا "Will done!"
            // الصحيح إملائيًا "Well done!" — غيّره لو تبي
            Text(result == .success
                 ? "Will done!"
                 : "You didn't reach your goal this time.")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 20)

            Text(result == .success
                 ? "Ready for your next goal?"
                 : "Want to set another goal?")
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

#Preview("Success") {
    ActivityView(
        goalResult: .success,
        learnedDays: 3,
        frozenDays: 2,
        weekDays: WeekDay.week([.learned, .learned, .learned, .frozen, .frozen, .none, .none])
    )
}

#Preview("Failure") {
    ActivityView(
        goalResult: .failure,
        learnedDays: 2,
        frozenDays: 2,
        weekDays: WeekDay.week([.learned, .learned, .none, .frozen, .frozen, .none, .none])
    )
}
