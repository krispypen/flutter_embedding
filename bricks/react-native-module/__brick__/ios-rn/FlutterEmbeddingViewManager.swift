import Foundation
import Flutter
import flutter_embedding

@objc(FlutterEmbeddingViewManager)
class FlutterEmbeddingViewManager: RCTViewManager {

    override func view() -> (FlutterEmbeddingView) {
        return FlutterEmbeddingView()
    }

    @objc override static func requiresMainQueueSetup() -> Bool {
        return false
    }
}

class FlutterEmbeddingView: UIView {

    weak var flutterViewController: FlutterViewController?
    private var embedScheduled = false
    private var recoverAttempts = 0

    var config: NSDictionary = [:] {
        didSet {
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("nope") }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Flutter cannot create a valid rendering surface at zero size —
        // wait until we have real bounds
        guard !bounds.isEmpty else { return }

        if flutterViewController == nil {
            scheduleEmbed(delay: 0)
        } else if let vc = flutterViewController, vc.view.superview == self {
            // Only resize while we still own the view: another instance may have
            // adopted the (shared) view controller after a remount
            vc.view.frame = flutterFrame()
        }
    }

    /// React Native lays views out at fractional sizes (e.g. 687.6667pt). A
    /// Flutter view whose size is not pixel-integral gets a Metal drawable that
    /// doesn't match the engine's viewport metrics, and the rasterizer silently
    /// drops every frame (gray view). Round down to whole points.
    private func flutterFrame() -> CGRect {
        return CGRect(x: 0, y: 0, width: floor(bounds.width), height: floor(bounds.height))
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            detach()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            recoverAttempts = 0
            setNeedsLayout()
        }
    }

    /// Whether the view can actually be seen: embedding while hidden or
    /// offscreen wedges the engine's rendering surface.
    private func isDisplayable() -> Bool {
        guard let window = window, !bounds.isEmpty else { return false }
        var v: UIView? = self
        while let cur = v {
            if cur.isHidden || cur.alpha < 0.01 { return false }
            v = cur.superview
        }
        return convert(bounds, to: window).intersects(window.bounds)
    }

    private func scheduleEmbed(delay: TimeInterval) {
        guard !embedScheduled else { return }
        embedScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.embedScheduled = false
            guard self.window != nil, self.flutterViewController == nil else { return }
            if self.isDisplayable() {
                self.embed()
            } else {
                // There is no UIKit callback for ancestor visibility/transform
                // changes, so poll until the view becomes displayable
                self.scheduleEmbed(delay: 0.25)
            }
        }
    }

    private func detach() {
        guard let vc = flutterViewController, vc.view.superview == self else { return }
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
        flutterViewController = nil
    }

    private func embed() {
        guard let parentVC = parentViewController else {
            return
        }

        do {
            let vc = try FlutterEmbedding.shared.getViewController()
            // If the controller is still attached to a previous host, release it first
            if vc.parent != nil || vc.view.superview != nil {
                vc.willMove(toParent: nil)
                vc.view.removeFromSuperview()
                vc.removeFromParent()
            }
            // Size the view before it enters the window so the rendering surface
            // is created at the right dimensions
            vc.loadViewIfNeeded()
            vc.view.frame = flutterFrame()
            parentVC.addChild(vc)
            addSubview(vc.view)
            vc.didMove(toParent: parentVC)
            // Make sure appearance callbacks run even when the parent view
            // controller is not in an appearance transition of its own —
            // they drive the engine's surface/lifecycle state
            vc.beginAppearanceTransition(true, animated: false)
            vc.endAppearanceTransition()
            self.flutterViewController = vc
            scheduleRenderCheck(vc: vc)
        } catch {
            NSLog("FlutterEmbeddingView failed to embed Flutter content: %@", String(describing: error))
        }
    }

    /// Verify the engine actually presented a first frame; if not, the surface
    /// wedged — detach and re-embed with a fresh view controller.
    private func scheduleRenderCheck(vc: FlutterViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self, weak vc] in
            guard let self = self, let vc = vc, vc.view.superview == self else { return }
            if vc.isDisplayingFlutterUI {
                self.recoverAttempts = 0
                return
            }
            guard self.recoverAttempts < 5 else {
                NSLog("FlutterEmbeddingView: Flutter engine never rendered a first frame, giving up recovery")
                return
            }
            self.recoverAttempts += 1
            NSLog("FlutterEmbeddingView: no first frame yet, re-embedding (attempt %d)", self.recoverAttempts)
            self.detach()
            self.scheduleEmbed(delay: 0)
        }
    }

    @objc var color: String = "" {
        didSet {
            self.backgroundColor = hexStringToUIColor(hexColor: color)
        }
    }

    func hexStringToUIColor(hexColor: String) -> UIColor {
        let stringScanner = Scanner(string: hexColor)

        if(hexColor.hasPrefix("#")) {
            stringScanner.scanLocation = 1
        }
        var color: UInt32 = 0
        stringScanner.scanHexInt32(&color)

        let r = CGFloat(Int(color >> 16) & 0x000000FF)
        let g = CGFloat(Int(color >> 8) & 0x000000FF)
        let b = CGFloat(Int(color) & 0x000000FF)

        return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
