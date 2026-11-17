import SwiftUI

// VIEW: تعرض فقط. الخانات والحالات من CalendarViewModel
struct CalendarView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: CalendarViewModel

    // نستقبل ActivityViewModel ونبني منه CalendarViewModel
    init(activity: ActivityViewModel) {
        _vm = StateObject(wrappedValue: CalendarViewModel(activity: activity))
    }

    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]   // عناوين الأعمدة
    private let columns = Array(repeating: GridItem(.fixed(54), spacing: 0), count: 7)   // 7 أعمدة

    // تقويم ميلادي ثابت (حتى لو جوالك على التقويم الهجري)
    private let gregorian = Calendar(identifier: .gregorian)

    /// كل شهور السنة الحالية: يناير → ديسمبر (أول يوم من كل شهر)
    private var yearMonths: [Date] {
        let year = gregorian.component(.year, from: Date())
        return (1...12).compactMap { month in
            gregorian.date(from: DateComponents(year: year, month: month, day: 1))
        }
    }

    /// الشهر الحالي من القائمة (عشان نروح له أول ما تفتح الصفحة)
    private var currentMonth: Date? {
        yearMonths.first { gregorian.isDate($0, equalTo: Date(), toGranularity: .month) }
    }

    var body: some View {
        VStack(spacing: 0) {

            // 1) الشريط العلوي: رجوع + العنوان
            ZStack {
                Text("Activities")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                HStack {
                    GlassIconButton(systemName: "chevron.left") { dismiss() }
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            // 2) كل شهور السنة (سكرول)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(yearMonths, id: \.self) { month in
                            monthSection(month).id(month)
                        }
                    }
                    .padding(.top, 9)
                }
                // أول ما تفتح الصفحة نروح للشهر الحالي
                .onAppear {
                    if let current = currentMonth {
                        proxy.scrollTo(current, anchor: .top)
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .englishUI()
    }

    // MARK: - شهر واحد

    private func monthSection(_ month: Date) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {

                // اسم الشهر
                Text(vm.monthTitle(month))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.leading, 20)

                // عناوين الأيام
                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) {
                        Text($0)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColor.secondaryText)
                            .frame(width: 54)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

                // شبكة الأيام
                LazyVGrid(columns: columns, spacing: 13) {
                    ForEach(Array(vm.cells(for: month).enumerated()), id: \.offset) { _, date in
                        if let date {
                            // يوم حقيقي: دائرة بلون حالته
                            DayCircleView(number: vm.dayNumber(date),
                                          status: vm.status(for: date),
                                          isToday: vm.isToday(date),
                                          size: 38)
                                .frame(width: 54, height: 38)
                        } else {
                            // خانة فاضية قبل بداية الشهر
                            Color.clear.frame(width: 54, height: 38)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 9)
            }

            // خط فاصل بين الشهور
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)
                .padding(.horizontal, 12)
                .padding(.top, 11)
        }
        .padding(.top, 15)
    }
}

#Preview { CalendarView(activity: ActivityViewModel()).preferredColorScheme(.dark) }
