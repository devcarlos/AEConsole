/**
 *  https://github.com/tadija/AEConsole
 *  Copyright (c) Marko Tadić 2016-2018
 *  Licensed under the MIT license. See LICENSE file.
 */

import UIKit
import AELog

class View: UIView {
    
    // MARK: - Constants
    
    fileprivate struct Layout {
        static let filterHeight: CGFloat = 64

        static let menuWidth: CGFloat = 300
        static let menuHeight: CGFloat = 50
        static let menuExpandedLeading: CGFloat = -Layout.menuWidth
        static let menuCollapsedLeading: CGFloat = -75
        
        static let magicNumber: CGFloat = 10
    }
    
    // MARK: - Outlets
    
    let tableView = UITableView()
    let textField = UITextField()
    
    fileprivate let filterView = UIView()
    fileprivate let filterStack = UIStackView()
    fileprivate var filterViewTop: NSLayoutConstraint!
    fileprivate var filterViewBottom: NSLayoutConstraint!
    
    fileprivate let exportLogButton = UIButton()
    fileprivate let linesCountStack = UIStackView()
    fileprivate let linesTotalLabel = UILabel()
    fileprivate let linesFilteredLabel = UILabel()
    fileprivate let clearFilterButton = UIButton()
    
    fileprivate let menuView = UIView()
    fileprivate let menuStack = UIStackView()
    fileprivate var menuViewLeading: NSLayoutConstraint!
    
    fileprivate let toggleToolbarButton = UIButton()
    fileprivate let forwardTouchesButton = UIButton()
    fileprivate let autoFollowButton = UIButton()
    fileprivate let clearLogButton = UIButton()
    
    fileprivate let updateOpacityGesture = UIPanGestureRecognizer()
    fileprivate let hideConsoleGesture = UITapGestureRecognizer()
    
    // MARK: - Properties
    
    var isOnScreen = false {
        didSet {
            isHidden = !isOnScreen
            
            if isOnScreen {
                updateUI()
            }
        }
    }
    
    var currentOffsetX = -Layout.magicNumber
    
    fileprivate let brain = Console.shared.brain
    fileprivate let settings = Console.shared.settings
    
    fileprivate var isToolbarActive = false {
        didSet {
            currentTopInset = isToolbarActive ? topInsetLarge : topInsetSmall
        }
    }
    
    fileprivate var opacity: CGFloat = 1.0 {
        didSet {
            configureColors(with: opacity)
        }
    }
    
    fileprivate var currentTopInset = Layout.magicNumber
    fileprivate var topInsetSmall = Layout.magicNumber
    fileprivate var topInsetLarge = Layout.magicNumber + Layout.filterHeight
    
    // MARK: - Init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        configureUI()
        opacity = settings.opacity
    }
    
    // MARK: - Override
    
    override func layoutSubviews() {
        super.layoutSubviews()

        updateFilterViewLayout()
        updateContentLayout()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        let filter = hitView?.superview == filterStack
        let menu = hitView?.superview == menuStack
        if !filter && !menu && forwardTouchesButton.isSelected {
            return nil
        }
        
        return hitView
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if settings.isShakeGestureEnabled {
                toggleUI()
            }
        }
    }
    
    // MARK: - API
    
    func toggleUI() {
        textField.resignFirstResponder()
        
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: { () -> Void in
            self.isOnScreen = !self.isOnScreen
        }, completion:nil)
    }
    
    func updateUI() {
        tableView.reloadData()
        
        updateLinesCountLabels()
        updateContentLayout()
        
        if autoFollowButton.isSelected {
            scrollToBottom()
        }
    }
    
}

extension View {
    
    // MARK: - Helpers
    
    fileprivate func updateLinesCountLabels() {
        linesTotalLabel.text = "□ \(brain.lines.count)"
        let filteredCount = brain.isFilterActive ? brain.filteredLines.count : 0
        linesFilteredLabel.text = "■ \(filteredCount)"
    }
    
    fileprivate func updateContentLayout() {
        let maxWidth = max(brain.contentWidth, bounds.width)
        
        let newFrame = CGRect(x: 0.0, y: 0.0, width: maxWidth, height: bounds.height)
        tableView.frame = newFrame
        
        UIView.animate(withDuration: 0.3, animations: { [unowned self] () -> Void in
            let inset = Layout.magicNumber
            let newInset = UIEdgeInsets(top: self.currentTopInset, left: inset, bottom: inset, right: maxWidth)
            self.tableView.contentInset = newInset
        })
        
        updateContentOffset()
    }
    
    private func updateContentOffset() {
        if isToolbarActive {
            if tableView.contentOffset.y == -topInsetSmall {
                let offset = CGPoint(x: tableView.contentOffset.x, y: -topInsetLarge)
                tableView.setContentOffset(offset, animated: true)
            }
        } else {
            if tableView.contentOffset.y == -topInsetLarge {
                let offset = CGPoint(x: tableView.contentOffset.x, y: -topInsetSmall)
                tableView.setContentOffset(offset, animated: true)
            }
        }
        tableView.flashScrollIndicators()
    }
    
    fileprivate func scrollToBottom() {
        let diff = tableView.contentSize.height - tableView.bounds.size.height
        if diff > 0 {
            let offsetY = diff + Layout.magicNumber
            let bottomOffset = CGPoint(x: currentOffsetX, y: offsetY)
            tableView.setContentOffset(bottomOffset, animated: false)
        }
    }
    
    fileprivate func configureColors(with opacity: CGFloat) {
        tableView.backgroundColor = settings.backColor.withAlphaComponent(opacity)
        
        let textOpacity = max(0.3, opacity * 1.1)
        settings.textColorWithOpacity = settings.textColor.withAlphaComponent(textOpacity)
        
        let toolbarOpacity = min(0.7, opacity * 1.5)
        filterView.backgroundColor = settings.backColor.withAlphaComponent(toolbarOpacity)
        menuView.backgroundColor = settings.backColor.withAlphaComponent(toolbarOpacity)
        
        let borderOpacity = toolbarOpacity / 2
        filterView.layer.borderColor = settings.backColor.withAlphaComponent(borderOpacity).cgColor
        filterView.layer.borderWidth = 1.0
        menuView.layer.borderColor = settings.backColor.withAlphaComponent(borderOpacity).cgColor
        menuView.layer.borderWidth = 1.0
        
        // refresh text color
        tableView.reloadData()
    }
    
}

extension View {
    
    // MARK: - UI
    
    fileprivate func configureUI() {
        configureOutlets()
        configureLayout()
    }
    
    private func configureOutlets() {
        configureTableView()
        configureFilterView()
        configureMenuView()
        configureGestures()
    }
    
    private func configureTableView() {
        tableView.rowHeight = settings.rowHeight
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.identifier)

        if #available(iOS 11.0, *) {
            tableView.insetsContentViewsToSafeArea = true
        }
    }
    
    private func configureFilterView() {
        configureFilterStack()
        configureFilterLinesCount()
        configureFilterTextField()
        configureFilterButtons()
    }
    
    private func configureFilterStack() {
        filterView.alpha = 0.3
        filterStack.axis = .horizontal
        filterStack.alignment = .center
        filterStack.distribution = .fill
        
        let stackInsets = UIEdgeInsets(top: Layout.magicNumber, left: 0, bottom: 0, right: 0)
        filterStack.layoutMargins = stackInsets
        filterStack.isLayoutMarginsRelativeArrangement = true
    }
    
    private func configureFilterLinesCount() {
        linesCountStack.axis = .vertical
        linesCountStack.alignment = .fill
        linesCountStack.distribution = .equalCentering

        linesTotalLabel.font = settings.consoleFont
        linesTotalLabel.textColor = settings.textColor
        linesTotalLabel.textAlignment = .left
        
        linesFilteredLabel.font = settings.consoleFont
        linesFilteredLabel.textColor = settings.textColor
        linesFilteredLabel.textAlignment = .left
    }
    
    private func configureFilterTextField() {
        let textColor = settings.textColor
        textField.autocapitalizationType = .none
        textField.tintColor = textColor
        textField.font = settings.consoleFont.withSize(16)
        textField.textColor = textColor
        let attributes = [NSAttributedStringKey.foregroundColor : textColor.withAlphaComponent(0.5)]
        let placeholderText = NSAttributedString(string: "Type filter here...", attributes: attributes)
        textField.attributedPlaceholder = placeholderText
        textField.layer.sublayerTransform = CATransform3DMakeTranslation(Layout.magicNumber, 0, 0)
    }
    
    private func configureFilterButtons() {
        exportLogButton.setTitle("🌙", for: .normal)
        exportLogButton.addTarget(self, action: #selector(didTapExportButton(_:)), for: .touchUpInside)
        
        clearFilterButton.setTitle("🔥", for: .normal)
        clearFilterButton.addTarget(self, action: #selector(didTapFilterClearButton(_:)), for: .touchUpInside)
    }
    
    private func configureMenuView() {
        configureMenuStack()
        configureMenuButtons()
    }
    
    private func configureMenuStack() {
        menuView.alpha = 0.3
        menuView.layer.cornerRadius = Layout.magicNumber
        
        menuStack.axis = .horizontal
        menuStack.alignment = .fill
        menuStack.distribution = .fillEqually
    }
    
    private func configureMenuButtons() {
        toggleToolbarButton.setTitle("☀️", for: .normal)
        forwardTouchesButton.setTitle("⚡️", for: .normal)
        forwardTouchesButton.setTitle("✨", for: .selected)
        autoFollowButton.setTitle("🌟", for: .normal)
        autoFollowButton.setTitle("💫", for: .selected)
        clearLogButton.setTitle("🔥", for: .normal)
        
        autoFollowButton.isSelected = true
        
        toggleToolbarButton.addTarget(self, action: #selector(didTapToggleToolbarButton(_:)), for: .touchUpInside)
        forwardTouchesButton.addTarget(self, action: #selector(didTapForwardTouchesButton(_:)), for: .touchUpInside)
        autoFollowButton.addTarget(self, action: #selector(didTapAutoFollowButton(_:)), for: .touchUpInside)
        clearLogButton.addTarget(self, action: #selector(didTapClearLogButton(_:)), for: .touchUpInside)
    }
    
    private func configureGestures() {
        configureUpdateOpacityGesture()
        configureHideConsoleGesture()
    }
    
    private func configureUpdateOpacityGesture() {
        updateOpacityGesture.addTarget(self, action: #selector(didRecognizeUpdateOpacityGesture(_:)))
        menuView.addGestureRecognizer(updateOpacityGesture)
    }
    
    private func configureHideConsoleGesture() {
        hideConsoleGesture.numberOfTouchesRequired = 2
        hideConsoleGesture.numberOfTapsRequired = 2
        hideConsoleGesture.addTarget(self, action: #selector(didRecognizeHideConsoleGesture(_:)))
        addGestureRecognizer(hideConsoleGesture)
    }
    
}

extension View {
    
    // MARK: - Layout
    
    fileprivate func configureLayout() {
        configureHierarchy()
        configureViewsForLayout()
        configureConstraints()
    }
    
    private func configureHierarchy() {
        addSubview(tableView)
        
        filterStack.addArrangedSubview(exportLogButton)
        
        linesCountStack.addArrangedSubview(linesTotalLabel)
        linesCountStack.addArrangedSubview(linesFilteredLabel)
        filterStack.addArrangedSubview(linesCountStack)
        
        filterStack.addArrangedSubview(textField)
        filterStack.addArrangedSubview(clearFilterButton)
        
        filterView.addSubview(filterStack)
        addSubview(filterView)
        
        menuStack.addArrangedSubview(toggleToolbarButton)
        menuStack.addArrangedSubview(forwardTouchesButton)
        menuStack.addArrangedSubview(autoFollowButton)
        menuStack.addArrangedSubview(clearLogButton)
        menuView.addSubview(menuStack)
        addSubview(menuView)
    }
    
    private func configureViewsForLayout() {
        filterView.translatesAutoresizingMaskIntoConstraints = false
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            filterStack.insetsLayoutMarginsFromSafeArea = false
        }
        
        menuView.translatesAutoresizingMaskIntoConstraints = false
        menuStack.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            menuStack.insetsLayoutMarginsFromSafeArea = false
        }
    }
    
    private func configureConstraints() {
        configureFilterViewConstraints()
        configureFilterStackConstraints()
        configureFilterStackSubviewConstraints()
        
        configureMenuViewConstraints()
        configureMenuStackConstraints()
    }
    
    private func configureFilterViewConstraints() {
        let leading = filterView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = filterView.trailingAnchor.constraint(equalTo: trailingAnchor)
        filterViewTop = filterView.topAnchor.constraint(equalTo: topAnchor, constant: -Layout.filterHeight)
        filterViewBottom = filterView.bottomAnchor.constraint(equalTo: topAnchor)
        NSLayoutConstraint.activate([leading, trailing, filterViewTop, filterViewBottom])
    }
    
    private func configureFilterStackConstraints() {
        let leading = filterStack.leadingAnchor.constraint(equalTo: filterView.leadingAnchor)
        let trailing = filterStack.trailingAnchor.constraint(equalTo: filterView.trailingAnchor)
        let top = filterStack.topAnchor.constraint(equalTo: filterView.topAnchor)
        let bottom = filterStack.bottomAnchor.constraint(equalTo: filterView.bottomAnchor)
        NSLayoutConstraint.activate([leading, trailing, top, bottom])
    }
    
    private func configureFilterStackSubviewConstraints() {
        let exportButtonWidth = exportLogButton.widthAnchor.constraint(equalToConstant: 75)
        let linesCountWidth = linesCountStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 50)
        let clearFilterButtonWidth = clearFilterButton.widthAnchor.constraint(equalToConstant: 75)
        NSLayoutConstraint.activate([exportButtonWidth, linesCountWidth, clearFilterButtonWidth])
    }
    
    private func configureMenuViewConstraints() {
        let width = menuView.widthAnchor.constraint(equalToConstant: Layout.menuWidth + Layout.magicNumber)
        let height = menuView.heightAnchor.constraint(equalToConstant: Layout.menuHeight)
        let centerY = menuView.centerYAnchor.constraint(equalTo: centerYAnchor)
        menuViewLeading = menuView.leadingAnchor.constraint(equalTo: trailingAnchor, constant: Layout.menuCollapsedLeading)
        NSLayoutConstraint.activate([width, height, centerY, menuViewLeading])
    }
    
    private func configureMenuStackConstraints() {
        let leading = menuStack.leadingAnchor.constraint(equalTo: menuView.leadingAnchor)
        let trailing = menuStack.trailingAnchor.constraint(equalTo: menuView.trailingAnchor, constant: -Layout.magicNumber)
        let top = menuStack.topAnchor.constraint(equalTo: menuView.topAnchor)
        let bottom = menuStack.bottomAnchor.constraint(equalTo: menuView.bottomAnchor)
        NSLayoutConstraint.activate([leading, trailing, top, bottom])
    }
    
}

extension View {
    
    // MARK: - Actions
    
    @objc func didTapToggleToolbarButton(_ sender: UIButton) {
        toggleToolbar()
    }
    
    @objc func didTapForwardTouchesButton(_ sender: UIButton) {
        forwardTouchesButton.isSelected = !forwardTouchesButton.isSelected
        logToDebugger("Forward Touches [\(forwardTouchesButton.isSelected)]")
    }
    
    @objc func didTapAutoFollowButton(_ sender: UIButton) {
        autoFollowButton.isSelected = !autoFollowButton.isSelected
        logToDebugger("Auto Follow [\(autoFollowButton.isSelected)]")
    }
    
    @objc func didTapClearLogButton(_ sender: UIButton) {
        brain.clearLog()
    }
    
    @objc func didTapExportButton(_ sender: UIButton) {
        brain.exportAllLogLines()
    }
    
    @objc func didTapFilterClearButton(_ sender: UIButton) {
        textField.resignFirstResponder()
        if !brain.isEmpty(textField.text) {
            brain.filterText = nil
        }
        textField.text = nil
    }
    
    @objc func didRecognizeUpdateOpacityGesture(_ sender: UIPanGestureRecognizer) {
        if sender.state == .ended {
            if isToolbarActive {
                let xTranslation = sender.translation(in: menuView).x
                if abs(xTranslation) > (3 * Layout.magicNumber) {
                    let location = sender.location(in: menuView)
                    let opacity = opacityForLocation(location)
                    self.opacity = opacity
                }
            }
        }
    }
    
    @objc func didRecognizeHideConsoleGesture(_ sender: UITapGestureRecognizer) {
        toggleUI()
    }
    
    // MARK: - Helpers
    
    private func opacityForLocation(_ location: CGPoint) -> CGFloat {
        let calculatedOpacity = ((location.x * 1.0) / 300)
        let minOpacity = max(0.1, calculatedOpacity)
        let maxOpacity = min(0.9, minOpacity)
        return maxOpacity
    }
    
    private func toggleToolbar() {
        isToolbarActive = !isToolbarActive

        updateFilterViewLayout()

        menuViewLeading.constant = isToolbarActive ? Layout.menuExpandedLeading : Layout.menuCollapsedLeading
        let alpha: CGFloat = isToolbarActive ? 1.0 : 0.3

        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.filterView.alpha = alpha
            self?.menuView.alpha = alpha
            self?.layoutIfNeeded()
        })
        
        if isToolbarActive {
            textField.resignFirstResponder()
        }
    }

    fileprivate func updateFilterViewLayout() {
        var filterTopPadding: CGFloat = 0
        if #available(iOS 11.0, *) {
            filterTopPadding = safeAreaInsets.top
        }
        filterViewTop.constant = isToolbarActive ? 0 : -Layout.filterHeight
        filterViewBottom.constant = isToolbarActive ? (Layout.filterHeight + filterTopPadding) : 0
    }
    
}
