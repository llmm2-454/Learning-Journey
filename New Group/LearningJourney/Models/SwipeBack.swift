import UIKit

// هذا الملف يخلي السحب من اليسار للرجوع يشتغل
// حتى لو أخفينا زر الرجوع الافتراضي (.navigationBarBackButtonHidden)
// لأن iOS يعطّل السحب تلقائيًا لما نخفي الزر
extension UINavigationController: UIGestureRecognizerDelegate {

    override open func viewDidLoad() {
        super.viewDidLoad()
        // نخلي هذا الكلاس هو اللي يقرر هل السحب يشتغل
        interactivePopGestureRecognizer?.delegate = self
    }

    // السحب يشتغل فقط إذا فيه أكثر من شاشة في الستاك
    // (لو كنا في أول شاشة، السحب ما يسوي شي، وهذا يمنع تجمّد التطبيق)
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
