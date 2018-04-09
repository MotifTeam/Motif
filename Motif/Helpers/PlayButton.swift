import UIKit
import Foundation

func CGPointMake(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    return CGPoint(x: x, y: y)
}

func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    return CGRect(x: x, y: y, width: width, height: height)
}

@IBDesignable
class PlayPauseView: UIView {
    
    fileprivate var state: State = .pause
    fileprivate let dalay: Double = 2
    
    lazy var playLayer: CAShapeLayer = {
        let playLayer = CAShapeLayer()
        playLayer.fillColor = UIColor.white.cgColor
        return playLayer
    }()
    
    lazy var pauseLayer: CAShapeLayer = {
        let pauseLayer = CAShapeLayer()
        pauseLayer.fillColor = UIColor.white.cgColor
        return pauseLayer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInitialization()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInitialization()
    }
    
    func sharedInitialization() {
        clipsToBounds = true
        layer.addSublayer(playLayer)
        layer.addSublayer(pauseLayer)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let beziers = PlayPauseView.generate(frame: bounds)
        playLayer.frame = bounds
        playLayer.path = playAnimationValues.toValue
        
        pauseLayer.frame = bounds
        pauseLayer.path = beziers.pause.cgPath
        pauseLayer.position.x = pauseAnimationValues.toValue
    }
    
    struct Beziers {
        var playPart1: UIBezierPath
        var playPart2: UIBezierPath
        var pause: UIBezierPath 
    }
    
    static func generate(frame: CGRect = CGRect(x: 0, y: 0, width: 384, height: 384)) -> Beziers {
        func fastFloor(_ x: CGFloat) -> CGFloat { return floor(x) }
        
        let playPart1 = UIBezierPath()
        playPart1.move(to: CGPointMake(frame.minX + 0.33333 * frame.width, frame.minY + 0.00000 * frame.height))
        playPart1.addLine(to: CGPointMake(frame.minX + 0.00000 * frame.width, frame.minY + 0.00000 * frame.height))
        playPart1.addLine(to: CGPointMake(frame.minX + 0.00000 * frame.width, frame.minY + 1.00000 * frame.height))
        playPart1.addLine(to: CGPointMake(frame.minX + 0.33333 * frame.width, frame.minY + 1.00000 * frame.height))
        
        let playPart2 = UIBezierPath()
        playPart2.move(to: CGPointMake(frame.minX + 1.00000 * frame.width, frame.minY + 0.50000 * frame.height))
        playPart2.addLine(to: CGPointMake(frame.minX + 0.00000 * frame.width, frame.minY + 0.00000 * frame.height))
        playPart2.addLine(to: CGPointMake(frame.minX + 0.00000 * frame.width, frame.minY + 1.00000 * frame.height))
        playPart2.addLine(to: CGPointMake(frame.minX + 0.00000 * frame.width, frame.minY + 1.00000 * frame.height))
        
        let pause = UIBezierPath()
        pause.move(to: CGPointMake(frame.minX + 1.00000 * frame.width, frame.minY + 0.00000 * frame.height))
        pause.addLine(to: CGPointMake(frame.minX + 0.66667 * frame.width, frame.minY + 0.00000 * frame.height))
        pause.addLine(to: CGPointMake(frame.minX + 0.66667 * frame.width, frame.minY + 1.00000 * frame.height))
        pause.addLine(to: CGPointMake(frame.minX + 1.00000 * frame.width, frame.minY + 1.00000 * frame.height))
        
        return Beziers(playPart1: playPart1, playPart2: playPart2, pause: pause)
    }
    
    var playAnimationValues: (fromValue: CGPath, toValue: CGPath) {
        let playPart1 = PlayPauseView.generate(frame: bounds).playPart1.cgPath
        let playPart2 = PlayPauseView.generate(frame: bounds).playPart2.cgPath
        
        return state == .pause ? (playPart1, playPart2) : (playPart2, playPart1)
    }
    
    var pauseAnimationValues: (fromValue: CGFloat, toValue: CGFloat) {
        let value1 = bounds.midX
        let value2 = -0.66667 * bounds.width
        
        return state == .pause ? (value1, value2) : (value2, value1)
    }
    
    func animate() {
        let playDuration: Double = state == .play ? 0.45 : 0.45
        let playBeginTime: Double = state == .play ? 0.2 : 0
        let playTimingFunction = CAMediaTimingFunction(controlPoints: 0.1, 0.2, 0.1, 1)
        
        let pauseDuration: Double = state == .play ? 0.25 : 0.35
        let pauseBeginTime: Double = state == .play ? 0 : 0
        let pauseTimingFunction = state == .play ?
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn) : CAMediaTimingFunction(controlPoints: 0.1, 0.2, 0.1, 1)
        
        state = state == .play ? .pause : .play
        
        let playAnimationGroup = CAAnimationGroup()
        playAnimationGroup.delegate = self
        playAnimationGroup.timingFunction = playTimingFunction
        playAnimationGroup.duration = playDuration
        playAnimationGroup.beginTime = CACurrentMediaTime() + dalay + playBeginTime
        playAnimationGroup.fillMode = kCAFillModeForwards
        playAnimationGroup.isRemovedOnCompletion = false
        
        let animatePlayPath = CABasicAnimation(keyPath: "path")
        animatePlayPath.fromValue = playAnimationValues.fromValue
        animatePlayPath.toValue = playAnimationValues.toValue
        
        playAnimationGroup.animations = [animatePlayPath]
        playLayer.add(playAnimationGroup, forKey: nil)
        
        let pauseAnimationGroup = CAAnimationGroup()
        pauseAnimationGroup.delegate = self
        pauseAnimationGroup.timingFunction = pauseTimingFunction
        pauseAnimationGroup.duration = pauseDuration
        pauseAnimationGroup.beginTime = CACurrentMediaTime() + dalay + pauseBeginTime
        pauseAnimationGroup.fillMode = kCAFillModeForwards
        pauseAnimationGroup.isRemovedOnCompletion = false
        
        let animatePausePositionX = CABasicAnimation(keyPath: "position.x")
        animatePausePositionX.fromValue = pauseAnimationValues.fromValue
        animatePausePositionX.toValue = pauseAnimationValues.toValue
        
        pauseAnimationGroup.animations = [animatePausePositionX]
        pauseLayer.add(pauseAnimationGroup, forKey: nil)
    }
}

extension PlayPauseView {
    enum State {
        case play, pause
    }
}

extension PlayPauseView: CAAnimationDelegate{
    func animationDidStart(_ anim: CAAnimation) {
        
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        
    }
}
