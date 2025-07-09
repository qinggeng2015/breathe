//
//  breatheApp.swift
//  breathe
//
//  Created by qinggeng on 2025/7/9.
//

import SwiftUI
import AppKit
import ImageIO

// MARK: - GifAnimationPlayer
class GifAnimationPlayer: ObservableObject {
    private var animationTimer: Timer?
    private var frames: [NSImage] = []
    private var currentFrame = 0
    private var frameDurations: [Double] = []
    
    init() {
        loadGifFrames()
    }
    
    private func loadGifFrames() {
        createBreathingFrames()
    }
    
    private func createBreathingFrames() {
        // 创建呼吸动画：吸气4秒 → 屏息2秒 → 呼气4秒
        let totalFrames = 100  // 10秒总时长 (每帧0.1秒)
        let inhaleFrames = 40   // 吸气4秒
        let holdFrames = 20     // 屏息2秒
        let exhaleFrames = 40   // 呼气4秒
        
        let maxSize: CGFloat = 20
        let minSize: CGFloat = 0.5  // 缩小到几乎一个点
        let maxAlpha: CGFloat = 0.9
        let minAlpha: CGFloat = 0.1
        
        // 增加图标宽度以容纳文字，并给圆圈右侧增加边距
        let iconWidth: CGFloat = 50
        let iconHeight: CGFloat = 24
        
        for i in 0..<totalFrames {
            var size: CGFloat
            var alpha: CGFloat
            var statusText: String
            
            if i < inhaleFrames {
                // 吸气阶段：从小到大
                let progress = Double(i) / Double(inhaleFrames - 1)
                let easeProgress = sin(progress * .pi / 2) // 缓动效果
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
                let progress = Double(i - inhaleFrames - holdFrames) / Double(exhaleFrames - 1)
                size = maxSize - (maxSize - minSize) * CGFloat(progress)
                alpha = maxAlpha - (maxAlpha - minAlpha) * CGFloat(progress)
                statusText = "呼气"
            }
            
            let image = NSImage(size: NSSize(width: iconWidth, height: iconHeight))
            image.lockFocus()
            
            let context = NSGraphicsContext.current?.cgContext
            let color = NSColor.white.withAlphaComponent(alpha)
            
            // 文字绘制在左侧，垂直居中，一直保持可见
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.white // 文字一直保持白色，不跟随透明度变化
            ]
            
            let attributedString = NSAttributedString(string: statusText, attributes: textAttributes)
            let textSize = attributedString.size()
            
            // 文字绘制在左侧，向左移动避免与圆圈重叠
            let textRect = NSRect(
                x: 0,
                y: (iconHeight - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            attributedString.draw(in: textRect)
            
            // 计算圆圈的中心位置，向右移动2个像素增加与文字的间距
            let circleX = iconWidth - 22 + (20 - size) / 2
            let circleY = iconHeight / 2
            
            // 绘制圆圈，位置向左移动以确保完整显示
            context?.setFillColor(color.cgColor)
            let rect = NSRect(
                x: circleX,
                y: (iconHeight - size) / 2,
                width: size,
                height: size
            )
            context?.fillEllipse(in: rect)
            
            // 添加外环效果（只有在圆圈足够大时才显示）
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
        
        button.image = frames[currentFrame % frames.count]
        currentFrame += 1
    }
    
    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
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
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
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
