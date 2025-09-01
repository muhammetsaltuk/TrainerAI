import UIKit

class GlitchLabel: UILabel {
    private var timer: Timer?
    private var currentIndex = 0
    private var isGlitching = false
    private var originalText: String = ""
    private var glitchText: [Character] = []
    private var glitchStep = 0
    private let glitchColors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemPink, .systemYellow, .systemPurple, .systemOrange]
    private var originalColor: UIColor = .systemBlue
    private let stepInterval: TimeInterval = 0.12 // slower for visibility
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        font = UIFont.systemFont(ofSize: 36, weight: .bold)
        textAlignment = .center
        textColor = .systemBlue
        originalColor = .systemBlue
    }
    
    func startGlitchAnimation() {
        originalText = text ?? ""
        glitchText = Array(originalText)
        currentIndex = 0
        glitchStep = 0
        isGlitching = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: stepInterval, target: self, selector: #selector(updateAnimation), userInfo: nil, repeats: true)
    }
    
    @objc private func updateAnimation() {
        guard isGlitching else { return }
        if currentIndex < glitchText.count {
            // Color glitch the current letter
            if glitchStep < 3 {
                let color = glitchColors.randomElement() ?? originalColor
                let attrString = NSMutableAttributedString(string: String(glitchText))
                attrString.addAttribute(.foregroundColor, value: color, range: NSRange(location: glitchText.count - 1 - currentIndex, length: 1))
                self.attributedText = attrString
                glitchStep += 1
            } else {
                // Remove the letter
                var temp = glitchText
                temp[glitchText.count - 1 - currentIndex] = " "
                self.attributedText = NSAttributedString(string: String(temp), attributes: [.foregroundColor: originalColor])
                glitchText = temp
                glitchStep = 0
                currentIndex += 1
            }
        } else {
            // All letters removed, reset after a pause
            isGlitching = false
            timer?.invalidate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self = self else { return }
                self.textColor = self.originalColor
                self.text = self.originalText
                self.glitchText = Array(self.originalText)
                self.currentIndex = 0
                self.glitchStep = 0
                self.isGlitching = true
                self.timer = Timer.scheduledTimer(timeInterval: self.stepInterval, target: self, selector: #selector(self.updateAnimation), userInfo: nil, repeats: true)
            }
        }
    }
    
    func stopAnimation() {
        timer?.invalidate()
        timer = nil
        textColor = originalColor
        text = originalText
    }
} 