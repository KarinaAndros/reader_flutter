import Cocoa
import FlutterMacOS
import Sparkle

class MainFlutterWindow: NSWindow, SPUUpdaterDelegate {
  private var updaterController: SPUStandardUpdaterController?
  private var updateChannel: FlutterMethodChannel?
  private var updateError: String?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.title = "MYB"
    self.contentMinSize = NSSize(width: 960, height: 640)
    self.tabbingMode = .disallowed
    self.setFrameAutosaveName("MYBMainWindow")
    if !self.setFrameUsingName("MYBMainWindow") {
      let available = NSScreen.main?.visibleFrame.size ?? NSSize(width: 1280, height: 900)
      self.setContentSize(NSSize(
        width: min(1200, available.width - 40),
        height: min(820, available.height - 40)
      ))
      self.center()
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    configureUpdates(flutterViewController)

    super.awakeFromNib()
  }

  private func configureUpdates(_ flutter: FlutterViewController) {
    let updater = SPUStandardUpdaterController(
      startingUpdater: false, updaterDelegate: self, userDriverDelegate: nil
    )
    updaterController = updater
    do {
      try updater.updater.start()
    } catch {
      updateError = error.localizedDescription
    }
    let channel = FlutterMethodChannel(
      name: "myb/app_updates", binaryMessenger: flutter.engine.binaryMessenger
    )
    updateChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "configuration":
        result([
          "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
          "build": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
          "feedURL": Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? "",
          "canCheckForUpdates": self.updaterController?.updater.canCheckForUpdates ?? false,
          "error": self.updateError ?? ""
        ])
      case "checkForUpdates":
        if let error = self.updateError {
          result(FlutterError(code: "updater_unavailable", message: error, details: nil))
        } else if let updater = self.updaterController, updater.updater.canCheckForUpdates {
          updater.checkForUpdates(nil)
          result(nil)
        } else {
          result(FlutterError(
            code: "update_in_progress", message: "Проверка обновлений уже выполняется.", details: nil
          ))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func updater(
    _ updater: SPUUpdater,
    shouldPostponeRelaunchForUpdate item: SUAppcastItem,
    untilInvokingBlock installHandler: @escaping () -> Void
  ) -> Bool {
    saveBeforeUpdate(installHandler)
    return true
  }

  private func saveBeforeUpdate(_ installHandler: @escaping () -> Void) {
    guard let channel = updateChannel else { return }
    channel.invokeMethod("prepareForUpdate", arguments: nil) { [weak self] result in
      if result is FlutterError || (result as AnyObject?) === FlutterMethodNotImplemented {
        let alert = NSAlert()
        alert.messageText = "Не удалось сохранить прогресс чтения"
        alert.informativeText = "Можно повторить сохранение перед установкой обновления."
        alert.addButton(withTitle: "Повторить сохранение")
        alert.addButton(withTitle: "Обновить без сохранения")
        if alert.runModal() == .alertFirstButtonReturn {
          self?.saveBeforeUpdate(installHandler)
        } else {
          installHandler()
        }
      } else {
        installHandler()
      }
    }
  }
}
