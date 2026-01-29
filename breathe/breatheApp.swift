//
//  breatheApp.swift
//  breathe
//
//  Created by qinggeng on 2025/7/9.
//

import SwiftUI
import AppKit
import ImageIO

// MARK: - Breathing Mode Enum
enum BreathingMode: String, CaseIterable {
    case deepRelaxation = "深度放松训练"
    case lightMeditation = "轻松冥想"
    case quickAdjustment = "快速调节情绪"
    
    var inhaleSeconds: Double {
        switch self {
        case .deepRelaxation: return 4.0
        case .lightMeditation: return 3.0
        case .quickAdjustment: return 2.0
        }
    }
    
    var holdSeconds: Double {
        switch self {
        case .deepRelaxation: return 2.0
        case .lightMeditation: return 0.0
        case .quickAdjustment: return 0.0
        }
    }
    
    var exhaleSeconds: Double {
        switch self {
        case .deepRelaxation: return 4.0
        case .lightMeditation: return 5.0
        case .quickAdjustment: return 4.0
        }
    }
    
    var description: String {
        switch self {
        case .deepRelaxation: return "吸气4秒 → 屏息2秒 → 呼气4秒"
        case .lightMeditation: return "吸气3秒 → 呼气5秒"
        case .quickAdjustment: return "吸气2秒 → 呼气4秒"
        }
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    private enum Keys {
        static let selectedBreathingMode = "selectedBreathingMode"
        static let isSoundEnabled = "isSoundEnabled"
    }
    
    var selectedBreathingMode: BreathingMode {
        get {
            if let rawValue = string(forKey: Keys.selectedBreathingMode),
               let mode = BreathingMode(rawValue: rawValue) {
                return mode
            }
            return .deepRelaxation // 默认模式
        }
        set {
            set(newValue.rawValue, forKey: Keys.selectedBreathingMode)
        }
    }
    
    var isSoundEnabled: Bool {
        get {
            return bool(forKey: Keys.isSoundEnabled)
        }
        set {
            set(newValue, forKey: Keys.isSoundEnabled)
        }
    }
}

// MARK: - GifAnimationPlayer
class GifAnimationPlayer: ObservableObject {
    private var animationTimer: Timer?
    private var frames: [NSImage] = []
    private var currentFrame = 0
    private var frameDurations: [Double] = []
    private var currentMode: BreathingMode = .deepRelaxation
    private var inhaleFrames: Int = 0
    private var holdFrames: Int = 0
    
    init() {
        // 从UserDefaults加载上次选择的模式
        currentMode = UserDefaults.standard.selectedBreathingMode
        loadGifFrames()
    }
    
    private func loadGifFrames() {
        createBreathingFrames()
    }
    
    func setBreathingMode(_ mode: BreathingMode) {
        currentMode = mode
        // 保存到UserDefaults
        UserDefaults.standard.selectedBreathingMode = mode
        createBreathingFrames()
    }
    
    private func createBreathingFrames() {
        // 根据当前模式创建呼吸动画
        let inhaleSeconds = currentMode.inhaleSeconds
        let holdSeconds = currentMode.holdSeconds
        let exhaleSeconds = currentMode.exhaleSeconds
        
        let totalSeconds = inhaleSeconds + holdSeconds + exhaleSeconds
        let totalFrames = Int(totalSeconds * 10)  // 每0.1秒一帧
        self.inhaleFrames = Int(inhaleSeconds * 10)
        self.holdFrames = Int(holdSeconds * 10)
        let exhaleFrames = Int(exhaleSeconds * 10)
        
        frames.removeAll()
        frameDurations.removeAll()
        
        let maxSize: CGFloat = 20
        let minSize: CGFloat = 0.5
        let maxAlpha: CGFloat = 0.9
        let minAlpha: CGFloat = 0.1
        
        let iconWidth: CGFloat = 50
        let iconHeight: CGFloat = 24
        
        for i in 0..<totalFrames {
            var size: CGFloat
            var alpha: CGFloat
            var statusText: String
            
            if i < inhaleFrames {
                // 吸气阶段：从小到大
                let progress = Double(i) / Double(max(inhaleFrames - 1, 1))
                let easeProgress = sin(progress * .pi / 2)
                size = minSize + (maxSize - minSize) * CGFloat(easeProgress)
                alpha = minAlpha + (maxAlpha - minAlpha) * CGFloat(easeProgress)
                statusText = "吸气"
            } else if i < inhaleFrames + holdFrames {
                // 屏息阶段：保持最大
                size = maxSize
                alpha = maxAlpha
                statusText = "屏息"
            } else {
                // 呼气阶段：从大到小
                let progress = Double(i - inhaleFrames - holdFrames) / Double(max(exhaleFrames - 1, 1))
                size = maxSize - (maxSize - minSize) * CGFloat(progress)
                alpha = maxAlpha - (maxAlpha - minAlpha) * CGFloat(progress)
                statusText = "呼气"
            }
            
            let image = NSImage(size: NSSize(width: iconWidth, height: iconHeight))
            image.lockFocus()
            
            let context = NSGraphicsContext.current?.cgContext
            let color = NSColor.white.withAlphaComponent(alpha)
            
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.white
            ]
            
            let attributedString = NSAttributedString(string: statusText, attributes: textAttributes)
            let textSize = attributedString.size()
            
            let textRect = NSRect(
                x: 0,
                y: (iconHeight - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            attributedString.draw(in: textRect)
            
            let circleX = iconWidth - 22 + (20 - size) / 2
            let _ = iconHeight / 2
            
            context?.setFillColor(color.cgColor)
            let rect = NSRect(
                x: circleX,
                y: (iconHeight - size) / 2,
                width: size,
                height: size
            )
            context?.fillEllipse(in: rect)
            
            if size > 5 {
                let outerSize = size + 2
                let outerRect = NSRect(
                    x: circleX - 1,
                    y: (iconHeight - outerSize) / 2,
                    width: outerSize,
                    height: outerSize
                )
                context?.setStrokeColor(color.cgColor)
                context?.setLineWidth(0.5)
                context?.strokeEllipse(in: outerRect)
            }
            
            image.unlockFocus()
            image.isTemplate = true
            frames.append(image)
            frameDurations.append(0.1)
        }
    }
    
    func startAnimation(for statusItem: NSStatusItem) {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.nextFrame(for: statusItem)
        }
    }
    
    private func nextFrame(for statusItem: NSStatusItem) {
        guard !frames.isEmpty, let button = statusItem.button else { return }
        
        let index = currentFrame % frames.count
        
        // 播放声音逻辑
        if UserDefaults.standard.isSoundEnabled {
            if index == 0 {
                // 吸气开始 - 滴
                NSSound(named: "Tink")?.play()
            } else if holdFrames > 0 && index == inhaleFrames {
                // 屏息开始 - 滴
                NSSound(named: "Tink")?.play()
            } else if index == inhaleFrames + holdFrames {
                // 呼气开始 - 滴
                NSSound(named: "Tink")?.play()
            }
        }
        
        button.image = frames[index]
        currentFrame += 1
    }
    
    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    func getCurrentMode() -> BreathingMode {
        return currentMode
    }
    
    deinit {
        stopAnimation()
    }
}

// MARK: - StatusBarManager
class StatusBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var gifPlayer: GifAnimationPlayer?
    private var menu: NSMenu?
    private var modeMenu: NSMenu?
    
    init() {
        setupStatusBar()
        setupGifAnimation()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Breathe")
            button.imagePosition = .imageOnly
            button.action = #selector(statusItemClicked)
            button.target = self
            
            setupMenu()
        }
    }
    
    private func setupMenu() {
        menu = NSMenu()
        
        let startItem = NSMenuItem(title: "开始呼吸", action: #selector(startBreathing), keyEquivalent: "")
        startItem.target = self
        menu?.addItem(startItem)
        
        let stopItem = NSMenuItem(title: "停止动画", action: #selector(stopBreathing), keyEquivalent: "")
        stopItem.target = self
        menu?.addItem(stopItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // 声音开关
        let soundItem = NSMenuItem(title: "播放声音", action: #selector(toggleSound), keyEquivalent: "")
        soundItem.target = self
        soundItem.state = UserDefaults.standard.isSoundEnabled ? .on : .off
        menu?.addItem(soundItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // 添加切换模式菜单
        let modeItem = NSMenuItem(title: "切换模式", action: nil, keyEquivalent: "")
        modeMenu = NSMenu()
        setupModeSubmenu()
        modeItem.submenu = modeMenu
        menu?.addItem(modeItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func setupModeSubmenu() {
        modeMenu?.removeAllItems()
        
        let currentMode = gifPlayer?.getCurrentMode() ?? .deepRelaxation
        
        for mode in BreathingMode.allCases {
            let modeItem = NSMenuItem(title: mode.rawValue, action: #selector(switchMode(_:)), keyEquivalent: "")
            modeItem.target = self
            modeItem.representedObject = mode
            
            // 设置选中态
            if mode == currentMode {
                modeItem.state = .on
            } else {
                modeItem.state = .off
            }
            
            modeMenu?.addItem(modeItem)
        }
    }
    
    private func setupGifAnimation() {
        gifPlayer = GifAnimationPlayer()
        
        if let statusItem = statusItem {
            gifPlayer?.startAnimation(for: statusItem)
        }
    }
    
    @objc private func statusItemClicked() {
        print("Status item clicked")
    }
    
    @objc private func startBreathing() {
        if let statusItem = statusItem {
            gifPlayer?.startAnimation(for: statusItem)
        }
    }
    
    @objc private func stopBreathing() {
        gifPlayer?.stopAnimation()
    }
    
    @objc private func toggleSound(_ sender: NSMenuItem) {
        let newState = !UserDefaults.standard.isSoundEnabled
        UserDefaults.standard.isSoundEnabled = newState
        sender.state = newState ? .on : .off
    }
    
    @objc private func switchMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? BreathingMode else { return }
        
        // 停止当前动画
        gifPlayer?.stopAnimation()
        
        // 切换到新模式
        gifPlayer?.setBreathingMode(mode)
        
        // 重新开始动画
        if let statusItem = statusItem {
            gifPlayer?.startAnimation(for: statusItem)
        }
        
        // 更新菜单选中态
        updateMenuSelection()
        
        print("切换到模式: \(mode.rawValue) - \(mode.description)")
    }
    
    private func updateMenuSelection() {
        guard let modeMenu = modeMenu else { return }
        
        let currentMode = gifPlayer?.getCurrentMode() ?? .deepRelaxation
        
        for item in modeMenu.items {
            if let mode = item.representedObject as? BreathingMode {
                if mode == currentMode {
                    item.state = .on
                } else {
                    item.state = .off
                }
            }
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    deinit {
        gifPlayer?.stopAnimation()
        statusItem = nil
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarManager: StatusBarManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用为辅助应用（不显示在Dock中）
        NSApp.setActivationPolicy(.accessory)
        
        // 初始化状态栏管理器
        statusBarManager = StatusBarManager()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        statusBarManager = nil
    }
}

// MARK: - Main App
@main
struct breatheApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
