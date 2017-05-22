//
//  DataMediator.swift
//  Mensa
//
//  Created by Jordan Kay on 6/21/16.
//  Copyright © 2016 Jordan Kay. All rights reserved.
//

final class DataMediator<Item, View: UIView>: NSObject, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    typealias Sections = () -> [Section<Item>]
    typealias SectionInsets = (Int) -> UIEdgeInsets?
    typealias SizeInsets = (IndexPath) -> UIEdgeInsets
    typealias Variant = (Item, View.Type) -> DisplayVariant
    typealias UseViewWithItem = (View, Item, DisplayVariant, Bool) -> Void
    typealias HandleScrollEvent = (ScrollEvent) -> Void
    
    fileprivate let variant: Variant
    fileprivate let sectionInsets: SectionInsets
    fileprivate let useViewWithItem: UseViewWithItem
    
    fileprivate var currentSections: [Section<Item>]
    fileprivate var viewTypes: [String: View.Type] = [:]
    fileprivate var viewControllerTypes: [String: () -> ItemDisplayingViewController] = Registration.viewControllerTypes
    fileprivate var metricsViewControllers: [String: ItemDisplayingViewController] = [:]
    fileprivate var rowHeightCache: [String: CGFloat] = [:]
    fileprivate var needsHandleResting = true
    
    private let sections: Sections
    private let handleScrollEvent: HandleScrollEvent
    private let tableViewCellSeparatorInset: CGFloat?
    private let hidesLastTableViewCellSeparator: Bool
    private let collectionViewSizeInsets: SizeInsets
    
    private var registeredIdentifiers = Set<String>()
    private var sizes: [IndexPath: CGSize] = [:]
    private var prefetchedCells: [IndexPath: HostingCell]?
    private weak var parentViewController: UIViewController!
    
    init(parentViewController: UIViewController, sections: @escaping Sections, variant: @escaping Variant, useViewWithItem: @escaping UseViewWithItem, handleScrollEvent: @escaping HandleScrollEvent, tableViewCellSeparatorInset: CGFloat?, hidesLastTableViewCellSeparator: Bool, sectionInsets: @escaping SectionInsets, collectionViewSizeInsets: @escaping SizeInsets) {
        self.parentViewController = parentViewController
        self.sections = sections
        self.variant = variant
        self.useViewWithItem = useViewWithItem
        self.handleScrollEvent = handleScrollEvent
        self.tableViewCellSeparatorInset = tableViewCellSeparatorInset
        self.hidesLastTableViewCellSeparator = hidesLastTableViewCellSeparator
        self.sectionInsets = sectionInsets
        self.collectionViewSizeInsets = collectionViewSizeInsets
        self.currentSections = sections()
        
        super.init()
        
        for (key, value) in Registration.viewTypes {
            if value is View.Type {
                viewTypes[key] = value as? View.Type
            }
        }
    }
    
    var sectionCount: Int {
        return currentSections.count
    }
    
    func register<Item, ViewController: UIViewController>(itemType: Item.Type, conformingTypes: [Any.Type] = [], viewType: View.Type, controllerType: ViewController.Type) where Item == ViewController.Item, ViewController: ItemDisplaying {
        let types = [itemType] + conformingTypes
        for type in types {
            let key = String(describing: type)
            viewTypes[key] = viewType
            viewControllerTypes[key] = {
                let viewController = controllerType.init()
                return ItemDisplayingViewController(viewController)
            }            
        }
    }
    
    func prefetchContent(at indexPaths: [IndexPath], in scrollView: UIScrollView) {
        if prefetchedCells == nil {
            prefetchedCells = [:]
            for indexPath in indexPaths {
                guard currentSections.count > indexPath.section, currentSections[indexPath.section].count > indexPath.row else { return }
                if let tableView = scrollView as? UITableView {
                    prefetchedCells?[indexPath] = self.tableView(tableView, cellForRowAt: indexPath) as? HostingCell
                } else if let collectionView = scrollView as? UICollectionView {
                    prefetchedCells?[indexPath] = self.collectionView(collectionView, cellForItemAt: indexPath) as? HostingCell
                }
            }
        }
    }
    
    func reset() {
        sizes = [:]
        currentSections = sections()
        needsHandleResting = true
    }

    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return currentSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentSections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (item, variant, identifier) = info(for: indexPath)
        if let cell = prefetchedCells?[indexPath] as? UITableViewCell {
            prefetchedCells?[indexPath] = nil
            return cell
        }
        
        let hostingCell: HostingCell? = tableView.dequeueReusableCell(withIdentifier: identifier) as? HostingCell ?? {
            let hostedViewController = viewController(for: type(of: item as Any))
            let cell = TableViewCell<Item>(parentViewController: parentViewController, hostedViewController: hostedViewController, variant: variant, reuseIdentifier: identifier)
            if let inset = tableViewCellSeparatorInset {
                cell.separatorInset.left = inset
                cell.layoutMargins.left = inset
            }
            return cell
        }()
        
        guard let cell = hostingCell else { return UITableViewCell() }
        let view = cell.hostedViewController.view as! View
        useViewWithItem(view, item, variant, false)

        cell.hostedViewController.update(with: item, variant: variant, displayed: true)
        cell.hostedViewController.view.layoutIfNeeded()
        return cell as! UITableViewCell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let (item, variant, _) = info(for: indexPath)
        let type = type(of: item as Any)
        let key = String(describing: type)
        return rowHeightCache[key] ?? {
            let height: CGFloat
            let controller = viewController(for: type)
            if controller.isItemHeightBasedOnTemplate(displayedWith: variant) {
                controller.loadViewFromNib(for: variant)
                height = controller.view.bounds.height
            } else {
                height = UITableViewAutomaticDimension
            }
            rowHeightCache[key] = height
            return height
        }()
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let (item, variant, identifier) = info(for: indexPath)
        let metricsViewController = metricsViewControllers[identifier] ?? {
            let viewController = self.viewController(for: type(of: item as Any))
            metricsViewControllers[identifier] = viewController
            return viewController
        }()
        let strategy = metricsViewController.itemSizingStrategy(for: item, displayedWith: variant)
        if case let .average(height) = strategy.heightReference {
            return height
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sectionInsets(section)?.top ?? UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return sectionInsets(section)?.bottom ?? 0
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .clear
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = .clear
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        return cell?.hostedViewController.canSelectItem(item) ?? false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.selectItem(item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.setItemHighlighted(item, highlighted: true, animated: false)
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        let animated = !tableView.isTracking
        cell?.hostedViewController.setItemHighlighted(item, highlighted: false, animated: animated)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let (item, variant, _) = info(for: indexPath)
        let view = (cell as! TableViewCell<Item>).hostedViewController.view as! View
        useViewWithItem(view, item, variant, true)
        
        cell.backgroundColor = tableView.backgroundColor
        if hidesLastTableViewCellSeparator {
            let isLastCell = (indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1)
            if isLastCell {
                cell.separatorInset.left = cell.bounds.width
            }
        }
        
        if needsHandleResting {
            needsHandleResting = false
            DispatchQueue.main.async {
                self.handleResting(for: tableView)
            }
        }
    }
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return currentSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentSections[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (item, variant, identifier) = info(for: indexPath)
        if let cell = prefetchedCells?[indexPath] as? UICollectionViewCell {
            prefetchedCells?[indexPath] = nil
            return cell
        }
        
        if !registeredIdentifiers.contains(identifier) {
            collectionView.register(CollectionViewCell<Item>.self, forCellWithReuseIdentifier: identifier)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CollectionViewCell<Item>
        if !cell.hostingContent {
            let hostedViewController = viewController(for: type(of: item as Any))
            cell.setup(parentViewController: parentViewController, hostedViewController: hostedViewController, variant: variant)
            print("Setting up cell at \(indexPath) in \(hostedViewController.parent!) for \(type(of: item as Any)).")
        }
        
        cell.hostedViewController.update(with: item, variant: variant, displayed: true)
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let (item, variant, _) = info(for: indexPath)
        let view = (cell as! CollectionViewCell<Item>).hostedViewController.view as! View
        useViewWithItem(view, item, variant, true)
        
        if needsHandleResting {
            needsHandleResting = false
            DispatchQueue.main.async {
                self.handleResting(for: collectionView)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.selectItem(item)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        cell?.hostedViewController.setItemHighlighted(item, highlighted: true, animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? HostingCell
        let (item, _, _) = info(for: indexPath)
        let animated = !collectionView.isTracking
        cell?.hostedViewController.setItemHighlighted(item, highlighted: false, animated: animated)
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var sectionInsets: UIEdgeInsets = .zero
        let defaultSize = CGSize(width: 50, height: 50)
        let sizeInsets = collectionViewSizeInsets(indexPath)
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            guard flowLayout.itemSize == defaultSize else {
                let size = flowLayout.itemSize
                return CGSize(width: size.width - sizeInsets.left - sizeInsets.right, height: size.height - sizeInsets.top - sizeInsets.bottom)
            }
            sectionInsets = collectionViewSectionInset(for: indexPath.section, with: flowLayout)
        }
        
        return sizes[indexPath] ?? {
            let containerSize = UIEdgeInsetsInsetRect(collectionView.superview!.bounds, sectionInsets).size
            let scrollViewSize = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.scrollIndicatorInsets).size
            let size = viewSize(at: indexPath, withContainerSize: containerSize, scrollViewSize: scrollViewSize)
            let insetSize = CGSize(width: size.width - sizeInsets.left - sizeInsets.right, height: size.height - sizeInsets.top - sizeInsets.bottom)
            sizes[indexPath] = insetSize
            return insetSize
        }()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return collectionViewSectionInset(for: section, with: flowLayout)
        }
        return .zero
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) { handleScrollEvent(.didScroll) }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { handleScrollEvent(.willBeginDragging) }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) { handleScrollEvent(.willEndDragging(velocity: velocity, targetContentOffset: targetContentOffset)) }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) { handleScrollEvent(.willBeginDecelerating) }
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool { handleScrollEvent(.willScrollToTop); return true }
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) { handleScrollEvent(.didScrollToTop) }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { handleScrollEvent(.didEndScrollingAnimation) }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleResting(for: scrollView)
        handleScrollEvent(.didEndDecelerating)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            handleResting(for: scrollView)
        }
        handleScrollEvent(.didEndDragging(decelerate: decelerate))
    }
}

private extension DataMediator {
    func info(for indexPath: IndexPath) -> (Item, DisplayVariant, String) {
        let item = currentSections[indexPath.section][indexPath.row]
        let key = String(describing: type(of: item as Any))
        let variant = self.variant(item, viewTypes[key]!)
        let identifier = key + String(variant.rawValue)
        return (item, variant, identifier)
    }
    
    func viewController(for type: Any) -> ItemDisplayingViewController {
        let key = String(describing: type)
        return viewControllerTypes[key]!()
    }
    
    func hostedViewController(for cell: UITableViewCell) -> UIViewController? {
        return (cell as? HostingCell)?.hostedViewController
    }
    
    func collectionViewSectionInset(for section: Int, with layout: UICollectionViewFlowLayout) -> UIEdgeInsets {
        return sectionInsets(section) ?? layout.sectionInset
    }
    
    func viewSize(at indexPath: IndexPath, withContainerSize containerSize: CGSize, scrollViewSize: CGSize) -> CGSize {
        let (item, variant, identifier) = info(for: indexPath)
        let metricsViewController = metricsViewControllers[identifier] ?? {
            let viewController = self.viewController(for: type(of: item as Any))
            metricsViewControllers[identifier] = viewController
            return viewController
        }()
        
        var size: CGSize = .zero
        let strategy = metricsViewController.itemSizingStrategy(for: item, displayedWith: variant)
        
        var fittedSize: CGSize? = nil
        if case .constraints = strategy.widthReference, case .constraints = strategy.heightReference {
            metricsViewController.loadViewFromNib(for: variant)
            let metricsView = metricsViewController.view as! View
            useViewWithItem(metricsView, item, variant, false)
            metricsViewController.update(with: item, variant: variant, displayed: false)
            
            if case .constraints = strategy.heightReference {
                switch strategy.widthReference {
                case .containerView:
                    metricsView.frame.size.width = containerSize.width
                case .scrollView:
                    metricsView.frame.size.width = scrollViewSize.width
                default:
                    break
                }
            } else {
                switch strategy.heightReference {
                case .containerView:
                    metricsView.frame.size.height = containerSize.height
                case .scrollView:
                    metricsView.frame.size.height = scrollViewSize.height
                default:
                    break
                }
            }
            
            metricsView.setNeedsLayout()
            metricsView.layoutIfNeeded()
            fittedSize = metricsView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        }
        
        var templateSize: CGSize? = nil
        if case .template = strategy.widthReference, case .template = strategy.heightReference {
            templateSize = metricsViewController.sizeOfNib(for: variant)
        }

        switch strategy.widthReference {
        case .constraints, .average:
            size.width = fittedSize!.width
        case .containerView:
            size.width = containerSize.width
        case .scrollView:
            size.width = scrollViewSize.width
        case .template:
            size.width = templateSize!.width
        }

        switch strategy.heightReference {
        case .constraints, .average:
            size.height = fittedSize!.height
        case .containerView:
            size.height = containerSize.height
        case .scrollView:
            size.height = scrollViewSize.height
        case .template:
            size.height = templateSize!.height
        }
        
        if let margin = strategy.maxContainerMargin {
            size.width = min(size.width, containerSize.width - margin * 2)
        }

        return size
    }
    
    func handleResting(for scrollView: UIScrollView) {
        var cells: [HostingCell] = []
        var indexPaths: [IndexPath] = []
        if let tableView = scrollView as? UITableView {
            cells = tableView.visibleCells.map { $0 as! TableViewCell<Item> }
            indexPaths = tableView.indexPathsForVisibleRows!
        } else if let collectionView = scrollView as? UICollectionView {
            cells = collectionView.visibleCells.map { $0 as! CollectionViewCell<Item> }
            indexPaths = collectionView.indexPathsForVisibleItems
        }
        
        for (cell, indexPath) in zip(cells, indexPaths) {
            let (item, _, _) = info(for: indexPath)
            cell.hostedViewController.updateForResting(with: item)
        }
    }
}
