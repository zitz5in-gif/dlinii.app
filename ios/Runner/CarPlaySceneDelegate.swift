import CarPlay
import Foundation

struct DliniiCarPlayHud {
  var navigating = false
  var arrow = "↑"
  var instruction = "افتح دلّيني وابدأ الملاحة"
  var street = ""
  var eta = "—"
  var remainingKm = "—"
  var remainingMinutes = "—"
  var speedKmh = 0
}

final class DliniiCarPlayStore {
  static let shared = DliniiCarPlayStore()
  static let changedNotification = Notification.Name("DliniiCarPlayHudChanged")
  private(set) var hud = DliniiCarPlayHud()

  func update(_ arguments: [String: Any]?) {
    guard let arguments = arguments else { return }
    hud.navigating = arguments["navigating"] as? Bool ?? false
    hud.arrow = arguments["arrow"] as? String ?? "↑"
    hud.instruction = arguments["instruction"] as? String ?? "—"
    hud.street = arguments["street"] as? String ?? ""
    hud.eta = arguments["eta"] as? String ?? "—"
    hud.remainingKm = arguments["remainingKm"] as? String ?? "—"
    hud.remainingMinutes = arguments["remainingMinutes"] as? String ?? "—"
    hud.speedKmh = (arguments["speedKmh"] as? NSNumber)?.intValue ?? 0
    NotificationCenter.default.post(name: Self.changedNotification, object: nil)
  }

  func clear() {
    hud = DliniiCarPlayHud()
    NotificationCenter.default.post(name: Self.changedNotification, object: nil)
  }
}

@available(iOS 14.0, *)
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private var interfaceController: CPInterfaceController?

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    self.interfaceController = interfaceController
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(renderHud),
      name: DliniiCarPlayStore.changedNotification,
      object: nil
    )
    renderHud()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnect interfaceController: CPInterfaceController
  ) {
    NotificationCenter.default.removeObserver(self)
    self.interfaceController = nil
  }

  @objc private func renderHud() {
    guard let interfaceController = interfaceController else { return }
    let hud = DliniiCarPlayStore.shared.hud
    let items = [
      CPInformationItem(
        title: "\(hud.arrow) \(hud.instruction)",
        detail: hud.street.isEmpty ? "دلّيني" : hud.street
      ),
      CPInformationItem(
        title: "الوقت والمسافة",
        detail: "\(hud.remainingMinutes) د · \(hud.remainingKm) كم · \(hud.eta)"
      ),
      CPInformationItem(title: "السرعة", detail: "\(hud.speedKmh) كم/س")
    ]
    let template = CPInformationTemplate(
      title: hud.navigating ? "دلّيني — ملاحة نشطة" : "دلّيني",
      layout: .leading,
      items: items,
      actions: []
    )
    interfaceController.setRootTemplate(template, animated: false)
  }
}
