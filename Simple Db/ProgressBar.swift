//
//  ProgressBar.swift
//  Simple Db
//
//  Created by Daniel Husiuk on 08.06.2024.
//

import UIKit

// MARK: - Line Cap Enum

public enum LineCap : Int{
    case round, butt, square
    
    public func style() -> CAShapeLayerLineCap {
        switch self {
        case .round:
            return CAShapeLayerLineCap.round
        case .butt:
            return CAShapeLayerLineCap.butt
        case .square:
            return CAShapeLayerLineCap.square
        }
    }
}

// MARK: - Orientation Enum

public enum Orientation: Int  {
    case left, top, right, bottom
    
}

// MARK: - Variables

@IBDesignable
open class ProgressBar: UIView {
    
    // Stroke background color
    @IBInspectable open var clockwise: Bool = true {
        didSet {
            layoutSubviews()
        }
    }
    
    // Stroke background color
    @IBInspectable open var backgroundShapeColor: UIColor = UIColor(white: 0.9, alpha: 0.5) {
        didSet {
            updateShapes()
        }
    }
    
    // Progress stroke color
    @IBInspectable open var progressShapeColor: UIColor   = .blue {
        didSet {
            updateShapes()
        }
    }
    
    // Line width
    @IBInspectable open var lineWidth: CGFloat = 8.0 {
        didSet {
            updateShapes()
        }
    }
    
    // Space value
    @IBInspectable open var spaceDegree: CGFloat = 45.0 {
        didSet {
//            if spaceDegree < 45.0{
//                spaceDegree = 45.0
//            }
//
//            if spaceDegree > 135.0{
//                spaceDegree = 135.0
//            }
            
            layoutSubviews()

            updateShapes()
        }
    }
    
    // The progress shapes line width will be the `line width` minus the `inset`.
    @IBInspectable open var inset: CGFloat = 0.0 {
        didSet {
            updateShapes()
        }
    }
    
    // progress Orientation
    open var orientation: Orientation = .bottom {
        didSet {
            updateShapes()
        }
    }

    // Progress shapes line cap.
    open var lineCap: LineCap = .round {
        didSet {
            updateShapes()
        }
    }
    
    // Returns the current progress.
    @IBInspectable open private(set) var progress: CGFloat {
        set {
            progressShape?.strokeEnd = newValue
        }
        get {
            return progressShape.strokeEnd
        }
    }
    
    // Duration for a complete animation from 0.0 to 1.0.
    open var completeDuration: Double = 2.0
    
    private var backgroundShape: CAShapeLayer!
    private var progressShape: CAShapeLayer!
    
    private var progressAnimation: CABasicAnimation!
    
    // MARK: - Init
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        
        backgroundShape = CAShapeLayer()
        backgroundShape.fillColor = nil
        backgroundShape.strokeColor = backgroundShapeColor.cgColor
        layer.addSublayer(backgroundShape)
        
        progressShape = CAShapeLayer()
        progressShape.fillColor   = nil
        progressShape.strokeStart = 0.0
        progressShape.strokeEnd   = 0.1
        layer.addSublayer(progressShape)
        
        progressAnimation = CABasicAnimation(keyPath: "strokeEnd")
        
    }
    
    // MARK: - Progress Animation
    
    public func setProgress(progress: CGFloat, animated: Bool = true) {
        
        if progress > 1.0 {
            return
        }
        
        var start = progressShape.strokeEnd
        if let presentationLayer = progressShape.presentation(){
            if let count = progressShape.animationKeys()?.count, count > 0  {
            start = presentationLayer.strokeEnd
            }
        }
        
        let duration = abs(Double(progress - start)) * completeDuration
        progressShape.strokeEnd = progress
        
        if animated {
            progressAnimation.fromValue = start
            progressAnimation.toValue   = progress
            progressAnimation.duration  = duration
            
            progressAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressShape.add(progressAnimation, forKey: progressAnimation.keyPath)
        }
    }
    
    // MARK: - Layout
    
    open override func layoutSubviews() {
        
        super.layoutSubviews()
        
        backgroundShape.frame = bounds
        progressShape.frame   = bounds
        
        let rect = rectForShape()
        backgroundShape.path = pathForShape(rect: rect).cgPath
        progressShape.path   = pathForShape(rect: rect).cgPath
        
        updateShapes()

    }
    
    private func updateShapes() {
        backgroundShape?.lineWidth  = lineWidth
        backgroundShape?.strokeColor = backgroundShapeColor.cgColor
        backgroundShape?.lineCap     = lineCap.style()
        
        progressShape?.strokeColor = progressShapeColor.cgColor
        progressShape?.lineWidth   = lineWidth - inset
        progressShape?.lineCap     = lineCap.style()
        
        switch orientation {
        case .left:
            self.progressShape.transform = CATransform3DMakeRotation( CGFloat.pi / 2, 0, 0, 1.0)
            self.backgroundShape.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1.0)
        case .right:
            self.progressShape.transform = CATransform3DMakeRotation( CGFloat.pi * 1.5, 0, 0, 1.0)
            self.backgroundShape.transform = CATransform3DMakeRotation(CGFloat.pi * 1.5, 0, 0, 1.0)
        case .bottom:
            self.progressShape.transform = CATransform3DMakeRotation( CGFloat.pi * 2, 0, 0, 1.0)
            self.backgroundShape.transform = CATransform3DMakeRotation(CGFloat.pi * 2, 0, 0, 1.0)
        case .top:
            self.progressShape.transform = CATransform3DMakeRotation( CGFloat.pi, 0, 0, 1.0)
            self.backgroundShape.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1.0)
        }
    }
    
    // MARK: - Helper
    
    private func rectForShape() -> CGRect {
        return bounds.insetBy(dx: lineWidth / 2.0, dy: lineWidth / 2.0)
    }
    private func pathForShape(rect: CGRect) -> UIBezierPath {
        let startAngle:CGFloat!
        let endAngle:CGFloat!
        
        if clockwise{
            startAngle = CGFloat(spaceDegree * .pi / 180.0) + (0.5 * .pi)
            endAngle = CGFloat((360.0 - spaceDegree) * (.pi / 180.0)) + (0.5 * .pi)
        }else{
            startAngle = CGFloat((360.0 - spaceDegree) * (.pi / 180.0)) + (0.5 * .pi)
            endAngle = CGFloat(spaceDegree * .pi / 180.0) + (0.5 * .pi)
        }
        let path = UIBezierPath(arcCenter: CGPoint(x: rect.midX, y: rect.midY), radius: rect.size.width / 2.0, startAngle: startAngle, endAngle: endAngle
            , clockwise: clockwise)
    
        return path
    }
}
