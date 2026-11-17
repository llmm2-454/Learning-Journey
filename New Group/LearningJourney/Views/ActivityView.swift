import SwiftUI
import Combine

// VIEW: تعرض فقط. الحالة والقواعد كلها في ActivityViewModel
struct ActivityView: View {

    // الـ ViewModel الرئيسي للصفحة
    @StateObject private var vm = ActivityViewModel()

    // حالة واجهة بحتة (فتح الصفحات الداخلية): مكانها الـ View
    @State private var showCalendar = false
    @State private var showGoal = false

    // مؤقت كل 30 ثانية: يحدّث الوقت وقاعدة الـ 32 ساعة وتفعيل الأزرار
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    // هل الهدف منتهي (نجاح أو فشل)؟ يغيّر بعض المسافات
    private var isEnd: Bool { vm.state != .active }

    // نص زر التجميد: "Freezed" إذا اليوم متجمّد أو خلصت الفريزات
    private var freezeLabel: String {
        (vm.isFrozenToday || vm.frozenCount >= vm.maxFreezes) ? "Freezed for a day" : "Freeze for a day"
    }

    // MARK: - الجسم الرئيسي

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // 1) العنوان والتاريخ وأزرار التقويم والهدف
                header.padding(.horizontal, 16).padding(.top, 4)

                // 2) شريط الأسبوع
                weekRow.padding(.top, isEnd ? 21 : 17)

                // 3) كرت Learned وكرت Freezed
                statsRow.padding(.horizontal, 14).padding(.top, 13)

                // 4) المحتوى حسب حالة الهدف (من الـ ViewModel)
                switch vm.state {
                case .active:
                    activeContent
                case .completed:
                    endContent(icon: "hands.clap.fill",
                               title: "Well done!",
                               subtitle: "Ready for your next goal?")
                case .failed:
                    endContent(icon: "xmark.seal",
                               title: "You didn't reach your goal this time.",
                               subtitle: "Want to set another goal?")
                }

                Spacer(minLength: 0)
            }
            .background(Color.black.ignoresSafeArea())
            // صفحة التقويم: نمرر لها نفس الـ ViewModel
            .navigationDestination(isPresented: $showCalendar) { CalendarView(activity: vm) }
            // صفحة تعديل الهدف
            .navigationDestination(isPresented: $showGoal) { GoalView() }
            .toolbar(.hidden, for: .navigationBar)
            // كل ما نرجع للصفحة (مثلاً بعد تحديث الهدف) نعيد قراءة البيانات
            .onAppear { vm.reload() }
            // كل 30 ثانية نحدّث الوقت
            .onReceive(timer) { _ in vm.tick() }
        }
        .englishUI()
    }

    // MARK: - 1) الهيدر

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Text(vm.headerDate)   // مثال: Thursday, 24 October
                    .font(.system(size: 17))
                    .foregroundColor(AppColor.secondaryText)
            }
            Spacer()
            HStack(spacing: 12) {
                GlassIconButton(systemName: "calendar") { showCalendar = true }
                GlassIconButton(systemName: "pencil.tip.crop.circle") { showGoal = true }
            }
        }
    }

    // MARK: - 2) شريط الأسبوع

    private var weekRow: some View {
        HStack(spacing: 10) {
            ForEach(vm.weekDays, id: \.self) { date in
                VStack(spacing: 5) {
                    // حرف اليوم
                    Text(vm.weekdayLetter(date))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    // دائرة اليوم: لونها حسب حالته
                    DayCircleView(number: vm.dayNumber(date),
                                  status: vm.status(for: date),
                                  isToday: vm.isToday(date))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 3) الكروت

    private var statsRow: some View {
        HStack(spacing: 14) {
            statCard(icon: "flame.fill", color: AppColor.orange,
                     text: vm.daysText(vm.learnedCount), label: "Learned")
            statCard(icon: "snowflake", color: AppColor.blue,
                     text: vm.daysText(vm.frozenCount), label: "Freezed")
        }
    }

    // كرت واحد: أيقونة + العدد + الاسم
    private func statCard(icon: String, color: Color, text: String, label: String) -> some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, isEnd ? 10 : 9)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.top, isEnd ? 6 : 3)
        }
        .frame(maxWidth: .infinity)
        .frame(height: isEnd ? 100 : 90)
        // ✏️ قلاس داكن مثل التصميم (قبل: tint أبيض كان يخلي الكرت فاتح)
        .appGlass(RoundedRectangle(cornerRadius: 30, style: .continuous),
                  tint: Color(white: 0.05))
        // حدّ رفيع شفاف يعطي حافة الزجاج
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
        )
    }

    // MARK: - 4-أ) أثناء الهدف

    private var activeContent: some View {
        VStack(spacing: 0) {

            // الدائرة الكبيرة: تسجيل التعلّم (تتعطل حسب قواعد الـ ViewModel)
            Button(action: vm.logLearned) {
                Text(vm.isLearnedToday ? "Logged as Learned" : "Log as Learned")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(vm.canLog ? .white : AppColor.disabledText)
                    .frame(width: 272, height: 272)
            }
            .buttonStyle(.plain)
            .disabled(!vm.canLog)
            .appGlass(Circle(),
                      tint: vm.canLog ? AppColor.orange : AppColor.darkGlass,
                      interactive: vm.canLog)
            .padding(.top, 59)

            // زر التجميد
            Button(action: vm.freezeDay) {
                Text(freezeLabel)
                    .font(.system(size: 17))
                    .foregroundColor(vm.canFreeze ? .white : AppColor.disabledText)
                    .frame(width: 272, height: 46)
            }
            .buttonStyle(.plain)
            .disabled(!vm.canFreeze)
            .appGlass(Capsule(),
                      tint: vm.canFreeze ? AppColor.blue : AppColor.darkGlass,
                      interactive: vm.canFreeze)
            .padding(.top, 48)

            // عدّاد التجميد
            Text("\(vm.frozenCount) out of \(vm.maxFreezes) Freezes used")
                .font(.system(size: 14))
                .foregroundColor(AppColor.secondaryText)
                .padding(.top, 16)
        }
    }

    // MARK: - 4-ب) نجاح / فشل

    private func endContent(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(AppColor.orange)
                .padding(.top, 68)

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 18)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(AppColor.secondaryText)
                .padding(.top, 2)

            // زر وضع هدف جديد → يفتح صفحة الهدف
            Button { showGoal = true } label: {
                Label("Set a goal", systemImage: "pencil.tip.crop.circle")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .appGlass(Capsule(), tint: AppColor.orange, interactive: true)
            .padding(.top, 74)
        }
    }
}

#Preview { ActivityView().preferredColorScheme(.dark) }
