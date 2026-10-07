import Cocoa
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Fenêtre transparente : l'application dessine elle-même la bulle
    // et le cadre arrondi de la fenêtre.
    flutterViewController.backgroundColor = .clear
    self.isOpaque = false
    self.backgroundColor = .clear

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  // Garde la fenêtre cachée jusqu'à ce que Flutter l'ait placée.
  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}
