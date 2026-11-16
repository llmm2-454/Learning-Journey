import SwiftUI

// دائرة رقم اليوم: في شريط الأسبوع وفي التقويم
struct DayCircleView: View {
    let number: String
    let status: DayStatus?
    let isToday: Bool
    var size: CGFloat = 44

    var body: some View {
        Text(number)
            .font(.system(size: size * 0.45, weight: .regular))
            .foregroundColor(textColor)
            .frame(width: size, height: size)
            .background(Circle().fill(backgroundColor))
    }

    private var textColor: Color {
        switch status {
        case .learned: return AppColor.orange
        case .frozen:  return AppColor.blue
        case nil:      return .white
        }
    }

    // الحالة أولًا، وإذا ما فيه حالة: اليوم الحالي برتقالي
    private var backgroundColor: Color {
        switch status {
        case .learned: return AppColor.learnedFill
        case .frozen:  return AppColor.frozenFill
        case nil:      return isToday ? AppColor.orange : .clear
        }
    }
}
