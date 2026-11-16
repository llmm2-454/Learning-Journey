import SwiftUI

// خلفية زجاجية (Liquid Glass) نستخدمها لكل الأزرار والبطاقات
// shape: شكل الزر (Capsule / Circle / RoundedRectangle)
// color: لون الزر (برتقالي / أزرق)، وإذا nil يطلع رمادي
struct GlassBackground<S: Shape>: View {
    let shape: S
    var color: Color? = nil

    var body: some View {
        ZStack {
            // طبقة اللون تحت الزجاج، عشان اللون يبقى واضح على الخلفية السوداء
            shape.fill(color?.opacity(0.85) ?? Color(white: 0.16))
            glassLayer
        }
    }

    // طبقة الزجاج: حقيقية على iOS 26، وعلى الأنظمة الأقدم حدّ خفيف بس
    @ViewBuilder
    private var glassLayer: some View {
        if #available(iOS 26.0, *) {
            Color.clear.glassEffect(.regular.tint(color?.opacity(0.35)), in: shape)
        } else {
            shape.stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
    }
}

// كبسولة برتقالية زجاجية (الأزرار والخيار المختار)
struct OrangeCapsuleBackground: View {
    var body: some View {
        GlassBackground(shape: Capsule(), color: AppColor.orange)
    }
}

// كبسولة رمادية زجاجية (الخيار غير المختار)
struct GrayCapsuleBackground: View {
    var body: some View {
        GlassBackground(shape: Capsule())
    }
}
