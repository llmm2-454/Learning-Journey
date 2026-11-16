import SwiftUI
import Combine

struct ActivityView: View {

    @StateObject private var vm = ActivityViewModel()

    @State private var showGoal = false
    @State private var showCalendar = false

    // مؤقت كل 30 ثانية (عشان الأزرار تتفعل الساعة 12 صباحًا)
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    header
                    weekStrip.padding(.top, 20)
                    statCards.padding(.top, 14)

                    Spacer()

                    // الهدف شغّال؟ نعرض الأزرار. انتهى؟ نعرض النتيجة
                    if vm.state == .active {
                        activeContent
                    } else {
                        goalEndedContent
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .preferredColorScheme(.dark)
            .onReceive(timer) { _ in vm.tick() }
            .onAppear { vm.reload() }
            .navigationDestination(isPresented: $showGoal) {
                GoalView(goalEnded: vm.state != .active)
            }
            .navigationDestination(isPresented: $showCalendar) {
                CalendarView(vm: vm)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Text(vm.headerDate)
                    .font(.system(size: 17))
                    .foregroundColor(AppColor.secondaryText)
            }
            Spacer()
            HStack(spacing: 12) {
                circleIconButton("calendar") { showCalendar = true }
                circleIconButton("pencil.and.outline") { showGoal = true }
            }
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    // زر دائري زجاجي بأيقونة (التقويم والهدف)
    private func circleIconButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(GlassBackground(shape: Circle()))
        }
        .buttonStyle(.plain)
    }

    // MARK: - شريط الأسبوع

    private var weekStrip: some View {
        HStack {
            ForEach(vm.weekDays, id: \.self) { day in
                VStack(spacing: 8) {
                    Text(vm.weekdayLetter(day))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColor.secondaryText)
                    DayCircleView(
                        number: vm.dayNumber(day),
                        status: vm.status(for: day),
                        isToday: vm.isToday(day)
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - بطاقتا Learned و Freezed

    private var statCards: some View {
        HStack(spacing: 12) {
            statCard(icon: "flame.fill", color: AppColor.orange,
                     value: vm.daysText(vm.learnedCount), caption: "Learned")
            statCard(icon: "snowflake", color: AppColor.blue,
                     value: vm.daysText(vm.frozenCount), caption: "Freezed")
        }
    }

    // بطاقة زجاجية
    private func statCard(icon: String, color: Color, value: String, caption: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Text(caption)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            GlassBackground(shape: RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
    }

    // MARK: - الدائرة البرتقالية + زر التجميد

    private var activeContent: some View {
        VStack(spacing: 40) {

            // الدائرة الكبيرة: برتقالية إذا تشتغل، رمادية إذا معطّلة
            Button { vm.logLearned() } label: {
                Text(vm.isLearnedToday ? "Logged as Learned" : "Log as Learned")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(vm.canLog ? .white : AppColor.secondaryText)
                    .frame(width: 270, height: 270)
                    .background(
                        GlassBackground(shape: Circle(),
                                        color: vm.canLog ? AppColor.orange : nil)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!vm.canLog)

            VStack(spacing: 14) {
                // زر التجميد: أزرق إذا يشتغل، رمادي إذا معطّل
                Button { vm.freezeDay() } label: {
                    Text(vm.canFreeze ? "Freeze for a day" : "Freezed for a day")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(vm.canFreeze ? .white : AppColor.secondaryText)
                        .frame(width: 270, height: 46)
                        .background(
                            GlassBackground(shape: Capsule(),
                                            color: vm.canFreeze ? AppColor.blue : nil)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!vm.canFreeze)

                Text("\(vm.frozenCount) out of \(vm.maxFreezes) Freezes used")
                    .font(.system(size: 13))
                    .foregroundColor(AppColor.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - انتهاء الهدف (Well done / ما حققتي الهدف)

    private var goalEndedContent: some View {
        let completed = vm.state == .completed

        return VStack(spacing: 8) {
            Image(systemName: completed ? "hands.clap.fill" : "xmark.seal")
                .font(.system(size: 44))
                .foregroundColor(AppColor.orange)
                .padding(.bottom, 10)

            Text(completed ? "Well done!" : "You didn't reach your goal this time.")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(completed ? "Ready for your next goal?" : "Want to set another goal?")
                .font(.system(size: 14))
                .foregroundColor(AppColor.secondaryText)

            Button { showGoal = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.and.outline")
                    Text("Set a goal")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(OrangeCapsuleBackground())
            }
            .buttonStyle(.plain)
            .padding(.top, 50)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ActivityView()
}
