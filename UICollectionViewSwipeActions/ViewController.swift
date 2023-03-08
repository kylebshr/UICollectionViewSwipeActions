//
//  ViewController.swift
//  UICollectionViewSwipeActions
//
//  Created by Kyle Bashour on 3/8/23.
//

import UIKit

class ViewController: UIViewController {

    // Enable to compare to UITableView swipe actions
    let tableViewDemo = false

    typealias CollectionDataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias TableDataSource = UITableViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    let cellID = "cell"

    var sidebarPlants: [Plant] = [
        Plant(id: UUID(), name: "Asparagus Fern", isFavorite: false),
        Plant(id: UUID(), name: "False Shamrock Plant", isFavorite: false),
        Plant(id: UUID(), name: "English Ivy", isFavorite: false),
    ]

    var groupedPlants: [Plant] = [
        Plant(id: UUID(), name: "Asparagus Fern", isFavorite: false),
        Plant(id: UUID(), name: "False Shamrock Plant", isFavorite: false),
        Plant(id: UUID(), name: "English Ivy", isFavorite: false),
    ]

    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    lazy var tableView = UITableView(frame: .zero, style: .plain)

    lazy var collectionDataSource = CollectionDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemIdentifier in
        self?.provideCollectionCell(for: indexPath, identifier: itemIdentifier)
    }

    lazy var tableDataSource = TableDataSource(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in
        self?.provideTableCell(for: indexPath, identifier: itemIdentifier)
    }

    override func loadView() {
        if tableViewDemo {
            view = tableView
        } else {
            view = collectionView
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = collectionDataSource
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellID)

        tableView.delegate = self
        tableView.dataSource = tableDataSource
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)

        updateSnapshot()
    }

    func provideCollectionCell(for indexPath: IndexPath, identifier: Item) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
        cell.contentConfiguration = configuration(for: indexPath, identifier: identifier)
        cell.contentView.backgroundColor = .systemBackground
        return cell
    }

    func provideTableCell(for indexPath: IndexPath, identifier: Item) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        cell.contentConfiguration = configuration(for: indexPath, identifier: identifier)
        return cell
    }

    func updateSnapshot() {
        var snapshot = Snapshot()

        snapshot.appendSections([.sidebar])
        snapshot.appendItems(sidebarPlants.map { .sidebar($0.id) })

        snapshot.appendSections([.grouped])
        snapshot.appendItems(groupedPlants.map { .grouped($0.id) })

        collectionDataSource.apply(snapshot)
        tableDataSource.apply(snapshot)
    }

    func reconfigureItems(_ items: [Item]) {
        var snapshot = collectionDataSource.snapshot()

        let items = items.filter {
            snapshot.indexOfItem($0) != nil
        }

        snapshot.reconfigureItems(items)
        collectionDataSource.apply(snapshot)
        tableDataSource.apply(snapshot)
    }

    func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { section, environment in
            var config = UICollectionLayoutListConfiguration(appearance: section == 0 ? .sidebarPlain : .insetGrouped)
            config.backgroundColor = .systemGroupedBackground

            config.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                self?.swipeActions(for: indexPath)
            }

            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
        }
    }

    func swipeActions(for indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let identifier = self.collectionDataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        let favorite = UIContextualAction(style: .normal, title: "Favorite") { [weak self] _, _, completion in
            switch identifier {
            case .sidebar:
                self?.sidebarPlants[indexPath.item].isFavorite.toggle()
            case . grouped:
                self?.groupedPlants[indexPath.item].isFavorite.toggle()
            }

            self?.reconfigureItems([identifier])
            completion(true)
        }
        favorite.backgroundColor = .systemYellow

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.confirmDelete {
                switch identifier {
                case .sidebar:
                    self?.sidebarPlants.remove(at: indexPath.item)
                case . grouped:
                    self?.groupedPlants.remove(at: indexPath.item)
                }
            } completion: { didDelete in
                if didDelete {
                    self?.updateSnapshot()
                }

                completion(didDelete)
            }
        }

        return UISwipeActionsConfiguration(actions: [favorite, delete])
    }

    func configuration(for indexPath: IndexPath, identifier: Item) -> UIListContentConfiguration {
        let plant: Plant
        var config: UIListContentConfiguration

        switch identifier {
        case .sidebar(let plantID):
            plant = sidebarPlants.first(where: { $0.id == plantID })!
            config = .sidebarCell()
        case .grouped(let plantID):
            plant = groupedPlants.first(where: { $0.id == plantID })!
            config = .cell()
        }

        config.text = plant.name
        config.image = UIImage(systemName: plant.isFavorite ? "star.fill" : "star")
        config.imageProperties.tintColor = plant.isFavorite ? .systemYellow : .systemFill

        return config
    }

    func confirmDelete(delete: @escaping () -> Void, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Delete Item?", message: nil, preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "Delete", style: .destructive) { _ in
            delete()
            completion(true)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        }

        alert.addAction(delete)
        alert.addAction(cancel)

        present(alert, animated: true)
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        swipeActions(for: indexPath)
    }
}

enum Section: Hashable {
    case sidebar
    case grouped
}

enum Item: Hashable {
    case sidebar(Plant.ID)
    case grouped(Plant.ID)
}

struct Plant: Identifiable, Hashable {
    var id: UUID
    var name: String
    var isFavorite: Bool
}
