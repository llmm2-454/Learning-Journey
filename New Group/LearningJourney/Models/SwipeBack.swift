import UIKit

// يخلي السحب من اليسار للرجوع يشتغل حتى لو أخفينا زر الرجوع الافتراضي
extension UINavigationController: UIGestureRecognizerDelegate {

    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    // السحب يشتغل فقط إذا فيه أكثر من شاشة (يمنع تجمّد التطبيق)
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
