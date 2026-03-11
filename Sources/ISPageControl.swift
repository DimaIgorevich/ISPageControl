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
    private let visibleLimit = 7

    private var fullScaleIndex = [0, 1, 2]
    private var dotLayers: [CALayer] = []

    private var diameter: CGFloat { radius * 2 }
    private var centerIndex: Int { fullScaleIndex[1] }

    open var currentPage = 0 {
        didSet {
            guard numberOfPages > currentPage else { return }
            update()
        }
    }

    @IBInspectable open var inactiveTintColor: UIColor = .lightGray {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var currentPageTintColor: UIColor = #colorLiteral(red: 0, green: 0.6276981994, blue: 1, alpha: 1) {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var radius: CGFloat = 5 {
        didSet { updateDotLayersLayout() }
    }

    @IBInspectable open var padding: CGFloat = 8 {
        didSet { updateDotLayersLayout() }
    }

    @IBInspectable open var minScaleValue: CGFloat = 0.4 {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var middleScaleValue: CGFloat = 0.7 {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var numberOfPages: Int = 0 {
        didSet {
            setupDotLayers()
            isHidden = hideForSinglePage && numberOfPages <= 1
        }
    }

    @IBInspectable open var hideForSinglePage: Bool = true {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var inactiveTransparency: CGFloat = 0.4 {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var borderWidth: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }

    @IBInspectable open var borderColor: UIColor = .clear {
        didSet { setNeedsLayout() }
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    required public init(frame: CGRect, numberOfPages: Int) {
        super.init(frame: frame)
        self.numberOfPages = numberOfPages
        setupDotLayers()
    }

    override open var intrinsicContentSize: CGSize {
        sizeThatFits(.zero)
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {

        let count = min(visibleLimit, numberOfPages)

        return CGSize(
            width: CGFloat(count) * diameter + CGFloat(max(count - 1, 0)) * padding,
            height: diameter
        )
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        updateDotLayersLayout()

        dotLayers.forEach {
            if borderWidth > 0 {
                $0.borderWidth = borderWidth
                $0.borderColor = borderColor.cgColor
            }
        }

        update()
    }
}

private extension ISPageControl {

    func setupDotLayers() {

        dotLayers.forEach { $0.removeFromSuperlayer() }
        dotLayers.removeAll()

        guard numberOfPages > 0 else { return }

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

        let visibleCount = min(visibleLimit, numberOfPages)
        let floatCount = CGFloat(visibleCount)

        let totalWidth =
            diameter * floatCount +
            padding * (floatCount - 1)

        let x = (bounds.width - totalWidth) * 0.5
        let y = (bounds.height - diameter) * 0.5

        var frame = CGRect(x: x, y: y, width: diameter, height: diameter)

        for i in 0..<visibleCount {

            let layer = dotLayers[i]

            layer.cornerRadius = radius
            layer.frame = frame

            frame.origin.x += diameter + padding
        }

        if dotLayers.count > visibleCount {
            for i in visibleCount..<dotLayers.count {
                dotLayers[i].frame = .zero
            }
        }
    }

    func setupDotLayersPosition() {

        guard dotLayers.count > centerIndex else { return }

        let centerLayer = dotLayers[centerIndex]

        centerLayer.position = CGPoint(
            x: frame.width / 2,
            y: frame.height / 2
        )

        dotLayers.enumerated()
            .filter { $0.offset != centerIndex }
            .forEach {

                let index = abs($0.offset - centerIndex)

                let interval =
                    $0.offset > centerIndex
                    ? diameter + padding
                    : -(diameter + padding)

                $0.element.position = CGPoint(
                    x: centerLayer.position.x + interval * CGFloat(index),
                    y: $0.element.position.y
                )
            }
    }

    func setupDotLayersScale() {

        dotLayers.enumerated().forEach {

            guard let first = fullScaleIndex.first,
                  let last = fullScaleIndex.last
            else { return }

            var transform = CGAffineTransform.identity

            if !fullScaleIndex.contains($0.offset) {

                var scaleValue: CGFloat = 0

                if abs($0.offset - first) == 1 || abs($0.offset - last) == 1 {
                    scaleValue = min(middleScaleValue, 1)

                } else if abs($0.offset - first) == 2 || abs($0.offset - last) == 2 {
                    scaleValue = min(minScaleValue, 1)

                } else {
                    scaleValue = 0
                }

                transform = transform.scaledBy(
                    x: scaleValue,
                    y: scaleValue
                )
            }

            $0.element.setAffineTransform(transform)
        }
    }

    func update() {

        guard !dotLayers.isEmpty else { return }

        dotLayers.enumerated().forEach {

            $0.element.backgroundColor =
                $0.offset == currentPage
                ? currentPageTintColor.cgColor
                : inactiveTintColor
                    .withAlphaComponent(inactiveTransparency)
                    .cgColor
        }

        guard numberOfPages > limit else { return }

        changeFullScaleIndexsIfNeeded()

        setupDotLayersPosition()
        setupDotLayersScale()
    }

    func changeFullScaleIndexsIfNeeded() {

        guard !fullScaleIndex.contains(currentPage) else { return }

        let moreThanBefore = (fullScaleIndex.last ?? 0) < currentPage

        if moreThanBefore {

            fullScaleIndex[0] = currentPage - 2
            fullScaleIndex[1] = currentPage - 1
            fullScaleIndex[2] = currentPage

        } else {

            fullScaleIndex[0] = currentPage
            fullScaleIndex[1] = currentPage + 1
            fullScaleIndex[2] = currentPage + 2
        }
    }
}
