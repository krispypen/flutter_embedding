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
        
        if flutterViewController == nil {
            embed()
        } else {
            flutterViewController?.view.frame = bounds
        }
    }
    
    private func embed() {
        guard let parentVC = parentViewController else {
            return
        }
        
        do {
            let vc = try FlutterEmbedding.shared.getViewController()
            vc.willMove(toParent: parentVC)
            parentVC.addChild(vc)
            addSubview(vc.view)
            vc.view.frame = bounds
            vc.didMove(toParent: parentVC)
            self.flutterViewController = vc
        } catch {
            fatalError()
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
