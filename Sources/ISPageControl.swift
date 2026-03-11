//
//  ISPageControl.swift
//  ISPageControl
//
//  Created by gwangbeom on 2017. 11. 26..
//  Copyright © 2017년 gwangbeom. All rights reserved.
//

import UIKit

open class ISPageControl: UIControl {

    private let limit = 5
    private var fullScaleIndex = [0, 1, 2]
    private var dotLayers: [CALayer] = []

    private var diameter: CGFloat { return radius * 2 }
    private var centerIndex: Int { return min(fullScaleIndex[1], max(dotLayers.count - 1, 0)) }

    open var currentPage = 0 {
        didSet {
            guard currentPage >= 0, numberOfPages > currentPage else {
                return
            }
            update()
        }
    }

    @IBInspectable open var inactiveTintColor: UIColor = UIColor.lightGray {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable open var currentPageTintColor: UIColor = #colorLiteral(red: 0, green: 0.6276981994, blue: 1, alpha: 1) {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable open var radius: CGFloat = 5 {
        didSet {
            updateDotLayersLayout()
        }
    }

    @IBInspectable open var padding: CGFloat = 8 {
        didSet {
            updateDotLayersLayout()
        }
    }

    @IBInspectable open var minScaleValue: CGFloat = 0.4 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable open var middleScaleValue: CGFloat = 0.7 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable open var numberOfPages: Int = 0 {
        didSet {
            if numberOfPages < 0 { numberOfPages = 0 }
            normalizeStateIfNeeded()
            setupDotLayers()
            isHidden = hideForSinglePage && numberOfPages <= 1
        }
    }

    @IBInspectable open var hideForSinglePage: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable open var inactiveTransparency: CGFloat = 0.4 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable open var borderWidth: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable open var borderColor: UIColor = UIColor.clear {
        didSet {
            setNeedsLayout()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    required public init(frame: CGRect, numberOfPages: Int) {
        super.init(frame: frame)
        self.numberOfPages = max(0, numberOfPages)
        normalizeStateIfNeeded()
        setupDotLayers()
    }

    override open var intrinsicContentSize: CGSize {
        return sizeThatFits(.zero)
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        let count = max(0, numberOfPages)
        let width = count > 0
            ? CGFloat(count) * diameter + CGFloat(count - 1) * padding
            : 0
        return CGSize(width: width, height: diameter)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        updateDotLayersLayout()
        applyBorderIfNeeded()
        update()
    }
}

// MARK: - Public helper for reusable cell
public extension ISPageControl {

    func resetForReuse() {
        currentPage = 0
        fullScaleIndex = [0, 1, 2]

        dotLayers.forEach {
            $0.removeAllAnimations()
            $0.setAffineTransform(.identity)
        }

        updateDotLayersLayout()
        update()
    }
}

private extension ISPageControl {

    func normalizeStateIfNeeded() {
        if currentPage >= numberOfPages {
            currentPage = max(0, numberOfPages - 1)
        }

        fullScaleIndex = [0, 1, 2].filter { $0 < max(numberOfPages, 0) }
        while fullScaleIndex.count < 3 {
            fullScaleIndex.append(fullScaleIndex.last ?? 0)
        }
    }

    func setupDotLayers() {
        dotLayers.forEach { $0.removeFromSuperlayer() }
        dotLayers.removeAll()

        guard numberOfPages > 0 else {
            invalidateIntrinsicContentSize()
            return
        }

        for _ in 0..<numberOfPages {
            let dotLayer = CALayer()
            layer.addSublayer(dotLayer)
            dotLayers.append(dotLayer)
        }

        updateDotLayersLayout()
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    func updateDotLayersLayout() {
        guard !dotLayers.isEmpty else { return }
        guard bounds.width > 0, bounds.height > 0 else { return }

        let floatCount = CGFloat(numberOfPages)
        let totalWidth = diameter * floatCount + padding * (floatCount - 1)
        let x = (bounds.size.width - totalWidth) * 0.5
        let y = (bounds.size.height - diameter) * 0.5

        var frame = CGRect(x: x, y: y, width: diameter, height: diameter)

        dotLayers.forEach {
            $0.cornerRadius = radius
            $0.frame = frame
            $0.setAffineTransform(.identity)
            frame.origin.x += diameter + padding
        }
    }

    func applyBorderIfNeeded() {
        dotLayers.forEach {
            $0.borderWidth = borderWidth
            $0.borderColor = borderColor.cgColor
        }
    }

    func setupDotLayersPosition() {
        guard dotLayers.indices.contains(centerIndex) else { return }

        let centerLayer = dotLayers[centerIndex]
        centerLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)

        dotLayers.enumerated()
            .filter { $0.offset != centerIndex }
            .forEach {
                let index = abs($0.offset - centerIndex)
                let interval = $0.offset > centerIndex ? diameter + padding : -(diameter + padding)
                $0.element.position = CGPoint(
                    x: centerLayer.position.x + interval * CGFloat(index),
                    y: centerLayer.position.y
                )
            }
    }

    func setupDotLayersScale() {
        guard let first = fullScaleIndex.first, let last = fullScaleIndex.last else { return }

        dotLayers.enumerated().forEach {
            var transform = CGAffineTransform.identity

            if !fullScaleIndex.contains($0.offset) {
                let distanceToFirst = abs($0.offset - first)
                let distanceToLast = abs($0.offset - last)

                let scaleValue: CGFloat
                if distanceToFirst == 1 || distanceToLast == 1 {
                    scaleValue = min(middleScaleValue, 1)
                } else if distanceToFirst == 2 || distanceToLast == 2 {
                    scaleValue = min(minScaleValue, 1)
                } else {
                    scaleValue = 0
                }

                transform = transform.scaledBy(x: scaleValue, y: scaleValue)
            }

            $0.element.setAffineTransform(transform)
        }
    }

    func resetDotsToBaseState() {
        guard !dotLayers.isEmpty else { return }

        let floatCount = CGFloat(numberOfPages)
        let totalWidth = diameter * floatCount + padding * (floatCount - 1)
        let startX = (bounds.size.width - totalWidth) * 0.5
        let y = (bounds.size.height - diameter) * 0.5

        for (index, layer) in dotLayers.enumerated() {
            let x = startX + CGFloat(index) * (diameter + padding)
            layer.frame = CGRect(x: x, y: y, width: diameter, height: diameter)
            layer.cornerRadius = radius
            layer.setAffineTransform(.identity)
            layer.position = CGPoint(x: x + diameter / 2, y: y + diameter / 2)
        }
    }

    func update() {
        guard !dotLayers.isEmpty else { return }
        guard bounds.width > 0, bounds.height > 0 else { return }

        resetDotsToBaseState()

        dotLayers.enumerated().forEach {
            $0.element.backgroundColor = $0.offset == currentPage
                ? currentPageTintColor.cgColor
                : inactiveTintColor.withAlphaComponent(inactiveTransparency).cgColor
        }

        guard numberOfPages > limit else {
            return
        }

        changeFullScaleIndexsIfNeeded()
        setupDotLayersPosition()
        setupDotLayersScale()
    }

    func changeFullScaleIndexsIfNeeded() {
        guard !fullScaleIndex.contains(currentPage) else {
            return
        }

        let moreThanBefore = (fullScaleIndex.last ?? 0) < currentPage

        if moreThanBefore {
            fullScaleIndex[0] = max(0, currentPage - 2)
            fullScaleIndex[1] = max(0, currentPage - 1)
            fullScaleIndex[2] = currentPage
        } else {
            fullScaleIndex[0] = currentPage
            fullScaleIndex[1] = min(numberOfPages - 1, currentPage + 1)
            fullScaleIndex[2] = min(numberOfPages - 1, currentPage + 2)
        }
    }
}
