//
//  breatheApp.swift
//  breathe
//
//  Created by qinggeng on 2025/7/9.
//

import SwiftUI
import AppKit
import ImageIO
import AVFoundation

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

// MARK: - Phase Sound Enum
enum PhaseSound: String, CaseIterable {
    case none   = "关闭"
    case sound1 = "声音1"
    case sound2 = "声音2"
    case sound3 = "声音3"
    case tts    = "TTS语音"
}

// MARK: - Phase Sound Selection (ObjC-compatible wrapper)
class PhaseSoundSelection: NSObject {
    let phase: String   // "inhale" | "hold" | "exhale"
    let sound: PhaseSound
    init(phase: String, sound: PhaseSound) {
        self.phase = phase
        self.sound = sound
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    private enum Keys {
        static let selectedBreathingMode = "selectedBreathingMode"
        static let inhaleSound = "inhaleSound"
        static let holdSound   = "holdSound"
        static let exhaleSound = "exhaleSound"
    }
    
    var selectedBreathingMode: BreathingMode {
        get {
            if let rawValue = string(forKey: Keys.selectedBreathingMode),
               let mode = BreathingMode(rawValue: rawValue) {
                return mode
            }
            return .deepRelaxation
        }
        set { set(newValue.rawValue, forKey: Keys.selectedBreathingMode) }
    }
    
    private func phaseSound(forKey key: String, default defaultValue: PhaseSound) -> PhaseSound {
        if let raw = string(forKey: key), let s = PhaseSound(rawValue: raw) { return s }
        return defaultValue
    }
    
    var inhaleSound: PhaseSound {
        get { phaseSound(forKey: Keys.inhaleSound, default: .tts) }
        set { set(newValue.rawValue, forKey: Keys.inhaleSound) }
    }
    
    var holdSound: PhaseSound {
        get { phaseSound(forKey: Keys.holdSound, default: .tts) }
        set { set(newValue.rawValue, forKey: Keys.holdSound) }
    }
    
    var exhaleSound: PhaseSound {
        get { phaseSound(forKey: Keys.exhaleSound, default: .tts) }
        set { set(newValue.rawValue, forKey: Keys.exhaleSound) }
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
    private let synthesizer = AVSpeechSynthesizer()

    private func playPhaseSound(_ sound: PhaseSound, text: String) {
        switch sound {
        case .none:   break
        case .sound1: NSSound(named: "Tink")?.play()
        case .sound2: NSSound(named: "Funk")?.play()
        case .sound3: NSSound(named: "Pop")?.play()
        case .tts:    speak(text)
        }
    }

    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }
    
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
        if index == 0 {
            playPhaseSound(UserDefaults.standard.inhaleSound, text: "吸气")
        } else if holdFrames > 0 && index == inhaleFrames {
            playPhaseSound(UserDefaults.standard.holdSound, text: "屏息")
        } else if index == inhaleFrames + holdFrames {
            playPhaseSound(UserDefaults.standard.exhaleSound, text: "呼气")
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

// MARK: - AboutView
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 60, height: 60)
            }
            .frame(width: 80, height: 80)
            
            Text("Breathe")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("GitHub Repository") {
                if let url = URL(string: "https://github.com/qinggeng2015/breathe") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Text("一个简单的呼吸训练应用，\n帮助你放松身心。")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 10)
        }
        .padding(30)
        .frame(width: 300, height: 350)
    }
}

// MARK: - StatusBarManager
class StatusBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var gifPlayer: GifAnimationPlayer?
    private var menu: NSMenu?
    private var modeMenu: NSMenu?
    private var soundMenu: NSMenu?
    private var inhaleSoundMenu: NSMenu?
    private var holdSoundMenu: NSMenu?
    private var exhaleSoundMenu: NSMenu?
    private var aboutWindowController: NSWindowController?
    
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
        
        // 播放声音 → 子菜单
        let soundItem = NSMenuItem(title: "播放声音", action: nil, keyEquivalent: "")
        soundMenu = NSMenu()
        setupSoundSubmenu()
        soundItem.submenu = soundMenu
        menu?.addItem(soundItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // 切换模式子菜单
        let modeItem = NSMenuItem(title: "切换模式", action: nil, keyEquivalent: "")
        modeMenu = NSMenu()
        setupModeSubmenu()
        modeItem.submenu = modeMenu
        menu?.addItem(modeItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(title: "关于", action: #selector(openAboutWindow), keyEquivalent: "")
        aboutItem.target = self
        menu?.addItem(aboutItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func setupSoundSubmenu() {
        soundMenu?.removeAllItems()
        
        let phases: [(title: String, phase: String, menu: NSMenu?)] = [
            ("吸气", "inhale", nil),
            ("屏息", "hold",   nil),
            ("呼气", "exhale", nil),
        ]
        
        inhaleSoundMenu = NSMenu()
        holdSoundMenu   = NSMenu()
        exhaleSoundMenu = NSMenu()
        
        setupPhaseSoundMenu(inhaleSoundMenu!, phase: "inhale", current: UserDefaults.standard.inhaleSound)
        setupPhaseSoundMenu(holdSoundMenu!,   phase: "hold",   current: UserDefaults.standard.holdSound)
        setupPhaseSoundMenu(exhaleSoundMenu!, phase: "exhale", current: UserDefaults.standard.exhaleSound)
        
        let phaseData: [(String, NSMenu)] = [
            ("吸气", inhaleSoundMenu!),
            ("屏息", holdSoundMenu!),
            ("呼气", exhaleSoundMenu!),
        ]
        
        for (title, submenu) in phaseData {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.submenu = submenu
            soundMenu?.addItem(item)
        }
    }
    
    private func setupPhaseSoundMenu(_ menu: NSMenu, phase: String, current: PhaseSound) {
        menu.removeAllItems()
        for sound in PhaseSound.allCases {
            let item = NSMenuItem(title: sound.rawValue, action: #selector(switchPhaseSound(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = PhaseSoundSelection(phase: phase, sound: sound)
            item.state = (sound == current) ? .on : .off
            menu.addItem(item)
        }
    }
    
    private func updateSoundMenuSelection() {
        updatePhaseSoundMenu(inhaleSoundMenu, phase: "inhale", current: UserDefaults.standard.inhaleSound)
        updatePhaseSoundMenu(holdSoundMenu,   phase: "hold",   current: UserDefaults.standard.holdSound)
        updatePhaseSoundMenu(exhaleSoundMenu, phase: "exhale", current: UserDefaults.standard.exhaleSound)
    }
    
    private func updatePhaseSoundMenu(_ menu: NSMenu?, phase: String, current: PhaseSound) {
        guard let menu = menu else { return }
        for item in menu.items {
            if let sel = item.representedObject as? PhaseSoundSelection, sel.phase == phase {
                item.state = (sel.sound == current) ? .on : .off
            }
        }
    }
    
    private func setupModeSubmenu() {
        modeMenu?.removeAllItems()
        
        let currentMode = gifPlayer?.getCurrentMode() ?? .deepRelaxation
        
        for mode in BreathingMode.allCases {
            let modeItem = NSMenuItem(title: mode.rawValue, action: #selector(switchMode(_:)), keyEquivalent: "")
            modeItem.target = self
            modeItem.representedObject = mode
            modeItem.state = (mode == currentMode) ? .on : .off
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
    
    @objc private func switchPhaseSound(_ sender: NSMenuItem) {
        guard let sel = sender.representedObject as? PhaseSoundSelection else { return }
        switch sel.phase {
        case "inhale": UserDefaults.standard.inhaleSound = sel.sound
        case "hold":   UserDefaults.standard.holdSound   = sel.sound
        case "exhale": UserDefaults.standard.exhaleSound = sel.sound
        default: break
        }
        updateSoundMenuSelection()
    }
    
    @objc private func switchMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? BreathingMode else { return }
        
        gifPlayer?.stopAnimation()
        gifPlayer?.setBreathingMode(mode)
        
        if let statusItem = statusItem {
            gifPlayer?.startAnimation(for: statusItem)
        }
        
        updateMenuSelection()
        print("切换到模式: \(mode.rawValue) - \(mode.description)")
    }
    
    @objc private func openAboutWindow() {
        if aboutWindowController == nil {
            let aboutView = AboutView()
            let hostingController = NSHostingController(rootView: aboutView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.title = "关于 Breathe"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.center()
            window.isReleasedWhenClosed = false
            
            aboutWindowController = NSWindowController(window: window)
        }
        
        aboutWindowController?.showWindow(nil)
        aboutWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func updateMenuSelection() {
        guard let modeMenu = modeMenu else { return }
        
        let currentMode = gifPlayer?.getCurrentMode() ?? .deepRelaxation
        
        for item in modeMenu.items {
            if let mode = item.representedObject as? BreathingMode {
                item.state = (mode == currentMode) ? .on : .off
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
