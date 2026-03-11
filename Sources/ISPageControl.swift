//
//  ISPageControl.swift
//  ISPageControl
//
//  Created by gwangbeom on 2017. 11. 26..
//  Copyright © 2017년 gwangbeom. All rights reserved.
//

import UIKit

open class ISPageControl: UIControl {

    private let maxVisibleDots = 7
    private var dotLayers: [CALayer] = []

    // MARK: - Public properties

    open var numberOfPages: Int = 0 {
        didSet {
            rebuildDots()
        }
    }

    open var currentPage: Int = 0 {
        didSet {
            updateDots()
        }
    }

    open var radius: CGFloat = 4 {
        didSet { setNeedsLayout() }
    }

    open var padding: CGFloat = 8 {
        didSet { setNeedsLayout() }
    }

    open var inactiveTintColor: UIColor = .lightGray
    open var currentPageTintColor: UIColor = .systemBlue

    open var minScale: CGFloat = 0.4
    open var midScale: CGFloat = 0.7

    open var inactiveTransparency: CGFloat = 0.4
    open var hideForSinglePage: Bool = true

    // MARK: - Private

    private var diameter: CGFloat { radius * 2 }

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Layout

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutDots()
        updateDots()
    }

    open override var intrinsicContentSize: CGSize {
        let count = min(maxVisibleDots, numberOfPages)
        return CGSize(
            width: CGFloat(count) * diameter + CGFloat(count - 1) * padding,
            height: diameter
        )
    }
}

// MARK: - Setup

private extension ISPageControl {

    func rebuildDots() {

        dotLayers.forEach { $0.removeFromSuperlayer() }
        dotLayers.removeAll()

        let count = min(maxVisibleDots, numberOfPages)

        for _ in 0..<count {
            let dot = CALayer()
            dot.cornerRadius = radius
            layer.addSublayer(dot)
            dotLayers.append(dot)
        }

        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    func layoutDots() {

        let count = dotLayers.count

        let totalWidth =
            CGFloat(count) * diameter +
            CGFloat(count - 1) * padding

        var x = (bounds.width - totalWidth) / 2
        let y = (bounds.height - diameter) / 2

        for dot in dotLayers {

            dot.frame = CGRect(
                x: x,
                y: y,
                width: diameter,
                height: diameter
            )

            x += diameter + padding
        }
    }
}

// MARK: - Update

private extension ISPageControl {

    func updateDots() {

        guard numberOfPages > 0 else { return }

        let visibleCount = dotLayers.count

        let startIndex = max(
            0,
            min(
                currentPage - visibleCount / 2,
                numberOfPages - visibleCount
            )
        )

        for (i, dot) in dotLayers.enumerated() {

            let pageIndex = startIndex + i

            let isCurrent = pageIndex == currentPage

            dot.backgroundColor = isCurrent
                ? currentPageTintColor.cgColor
                : inactiveTintColor
                    .withAlphaComponent(inactiveTransparency)
                    .cgColor

            let distance = abs(pageIndex - currentPage)

            let scale: CGFloat

            switch distance {
            case 0: scale = 1
            case 1: scale = midScale
            case 2: scale = minScale
            default: scale = minScale * 0.7
            }

            dot.setAffineTransform(
                CGAffineTransform(scaleX: scale, y: scale)
            )
        }

        isHidden = hideForSinglePage && numberOfPages <= 1
    }
}
