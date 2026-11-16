import SwiftUI

// شاشة التقويم (Task 5): كل أشهر السنة، للعرض فقط بدون تفاعل
struct CalendarView: View {

    @ObservedObject var vm: ActivityViewModel
    @Environment(\.dismiss) private var dismiss

    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1
        return c
    }()

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols: [String] = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    // MARK: - الأشهر

    // من يناير لأقدم سنة فيها نشاط، إلى ديسمبر السنة الحالية
    private var months: [Date] {
        let firstYear = cal.component(.year, from: vm.calendarStartDate)
        let lastYear = cal.component(.year, from: vm.now)
        var result: [Date] = []

        for year in firstYear...max(firstYear, lastYear) {
            for month in 1...12 {
                var comps = DateComponents()
                comps.year = year
                comps.month = month
                comps.day = 1
                if let date = cal.date(from: comps) {
                    result.append(date)
                }
            }
        }
        return result
    }

    private var currentMonth: Date {
        cal.date(from: cal.dateComponents([.year, .month], from: vm.now)) ?? vm.now
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(months, id: \.self) { month in
                                monthSection(month)
                                    .id(month)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                    .onAppear {
                        // يفتح على الشهر الحالي، والأشهر السابقة فوقه
                        proxy.scrollTo(currentMonth, anchor: .top)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - الشريط العلوي

    private var topBar: some View {
        ZStack {
            Text("Activities")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(GlassBackground(shape: Circle()))
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    // MARK: - قسم شهر واحد

    private func monthSection(_ month: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(monthTitle(month))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColor.secondaryText)
                }
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(cells(for: month)) { cell in
                    if let date = cell.date {
                        DayCircleView(
                            number: String(cal.component(.day, from: date)),
                            status: vm.calendarStatus(for: date),
                            isToday: vm.isToday(date),
                            size: 38
                        )
                    } else {
                        Color.clear.frame(width: 38, height: 38)
                    }
                }
            }
            .padding(.horizontal, 16)

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
                .padding(.top, 14)
                .padding(.bottom, 14)
        }
    }

    // MARK: - خلايا الشهر

    private struct CalendarCell: Identifiable {
        let id: Int
        let date: Date?
    }

    // خلايا فاضية في البداية (عشان اليوم الأول يجي تحت اسم يومه) ثم أيام الشهر
    private func cells(for month: Date) -> [CalendarCell] {
        let offset = cal.component(.weekday, from: month) - 1
        let count = cal.range(of: .day, in: .month, for: month)?.count ?? 30

        var result: [CalendarCell] = []
        for i in 0..<offset {
            result.append(CalendarCell(id: i, date: nil))
        }
        for d in 0..<count {
            let date = cal.date(byAdding: .day, value: d, to: month)
            result.append(CalendarCell(id: offset + d, date: date))
        }
        return result
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: date)
    }
}
