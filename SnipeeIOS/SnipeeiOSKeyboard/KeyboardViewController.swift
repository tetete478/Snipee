//
//  KeyboardViewController.swift
//  SnipeeiOSKeyboard
//
//  Created by てててMac on 2026/02/01.
//

import UIKit

// MARK: - Models (Shared with main app)

private enum SnippetType: String, Codable {
    case master
    case personal
}

private struct Snippet: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var folder: String
    var type: SnippetType
    var order: Int
    var createdAt: Date
    var updatedAt: Date
}

private struct SnippetFolder: Identifiable, Codable {
    var id: String
    var name: String
    var snippets: [Snippet]
    var order: Int
}

private struct AppSettingsForKeyboard: Codable {
    var userName: String
}

// MARK: - KeyboardViewController

class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    private let appGroupId = "group.com.addness.snipee"
    private let snippetsKey = "snippets"

    private var folders: [SnippetFolder] = []
    private var selectedFolderIndex: Int = 0

    // MARK: - UI Components

    private var containerView: UIView!
    private var folderTabScrollView: UIScrollView!
    private var folderTabStackView: UIStackView!
    private var snippetCollectionView: UICollectionView!
    private var bottomBarView: UIView!
    private var nextKeyboardButton: UIButton!
    private var deleteButton: UIButton!
    private var emptyLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSnippets()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSnippets()
        updateFolderTabs()
        snippetCollectionView.reloadData()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        nextKeyboardButton.isHidden = !needsInputModeSwitchKey
    }

    override func textWillChange(_ textInput: UITextInput?) {}

    override func textDidChange(_ textInput: UITextInput?) {
        updateColors()
    }

    // MARK: - Data Loading

    private func loadSnippets() {
        guard let userDefaults = UserDefaults(suiteName: appGroupId),
              let data = userDefaults.data(forKey: snippetsKey),
              let decoded = try? JSONDecoder().decode([SnippetFolder].self, from: data) else {
            folders = []
            return
        }
        folders = decoded.sorted { $0.order < $1.order }

        if selectedFolderIndex >= folders.count {
            selectedFolderIndex = max(0, folders.count - 1)
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Container
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 260)
        ])

        setupFolderTabs()
        setupSnippetGrid()
        setupBottomBar()
        setupEmptyState()
        updateColors()
    }

    private func setupFolderTabs() {
        folderTabScrollView = UIScrollView()
        folderTabScrollView.translatesAutoresizingMaskIntoConstraints = false
        folderTabScrollView.showsHorizontalScrollIndicator = false
        folderTabScrollView.showsVerticalScrollIndicator = false
        containerView.addSubview(folderTabScrollView)

        folderTabStackView = UIStackView()
        folderTabStackView.translatesAutoresizingMaskIntoConstraints = false
        folderTabStackView.axis = .horizontal
        folderTabStackView.spacing = 8
        folderTabStackView.alignment = .center
        folderTabStackView.distribution = .fill
        folderTabScrollView.addSubview(folderTabStackView)

        NSLayoutConstraint.activate([
            folderTabScrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            folderTabScrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            folderTabScrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            folderTabScrollView.heightAnchor.constraint(equalToConstant: 36),

            folderTabStackView.topAnchor.constraint(equalTo: folderTabScrollView.topAnchor),
            folderTabStackView.leadingAnchor.constraint(equalTo: folderTabScrollView.leadingAnchor, constant: 8),
            folderTabStackView.trailingAnchor.constraint(equalTo: folderTabScrollView.trailingAnchor, constant: -8),
            folderTabStackView.bottomAnchor.constraint(equalTo: folderTabScrollView.bottomAnchor),
            folderTabStackView.heightAnchor.constraint(equalTo: folderTabScrollView.heightAnchor)
        ])

        updateFolderTabs()
    }

    private func updateFolderTabs() {
        folderTabStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, folder) in folders.enumerated() {
            let button = createFolderTabButton(title: "📁 \(folder.name)", index: index)
            folderTabStackView.addArrangedSubview(button)
        }

        updateTabSelection()
    }

    private func createFolderTabButton(title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.tag = index
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.layer.cornerRadius = 14
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(folderTabTapped(_:)), for: .touchUpInside)
        return button
    }

    private func updateTabSelection() {
        for case let button as UIButton in folderTabStackView.arrangedSubviews {
            let isSelected = button.tag == selectedFolderIndex
            let isDark = traitCollection.userInterfaceStyle == .dark

            if isSelected {
                button.backgroundColor = isDark ? UIColor.white.withAlphaComponent(0.2) : UIColor.black.withAlphaComponent(0.1)
                button.setTitleColor(isDark ? .white : .black, for: .normal)
            } else {
                button.backgroundColor = .clear
                button.setTitleColor(isDark ? UIColor.white.withAlphaComponent(0.6) : UIColor.black.withAlphaComponent(0.5), for: .normal)
            }
        }
    }

    private func setupSnippetGrid() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        snippetCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        snippetCollectionView.translatesAutoresizingMaskIntoConstraints = false
        snippetCollectionView.backgroundColor = .clear
        snippetCollectionView.delegate = self
        snippetCollectionView.dataSource = self
        snippetCollectionView.register(SnippetCell.self, forCellWithReuseIdentifier: SnippetCell.identifier)
        containerView.addSubview(snippetCollectionView)

        NSLayoutConstraint.activate([
            snippetCollectionView.topAnchor.constraint(equalTo: folderTabScrollView.bottomAnchor, constant: 4),
            snippetCollectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            snippetCollectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            snippetCollectionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -44)
        ])
    }

    private func setupBottomBar() {
        bottomBarView = UIView()
        bottomBarView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bottomBarView)

        // Next Keyboard Button
        nextKeyboardButton = UIButton(type: .system)
        nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.titleLabel?.font = .systemFont(ofSize: 20)
        nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        bottomBarView.addSubview(nextKeyboardButton)

        // Delete Button
        deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setTitle("削除 ⌫", for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        // Long press for continuous delete
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(deleteLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        deleteButton.addGestureRecognizer(longPress)
        bottomBarView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            bottomBarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomBarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomBarView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomBarView.heightAnchor.constraint(equalToConstant: 44),

            nextKeyboardButton.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: 12),
            nextKeyboardButton.centerYAnchor.constraint(equalTo: bottomBarView.centerYAnchor),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 44),

            deleteButton.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -12),
            deleteButton.centerYAnchor.constraint(equalTo: bottomBarView.centerYAnchor),
            deleteButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            deleteButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        deleteButton.layer.cornerRadius = 6
        deleteButton.layer.masksToBounds = true
    }

    private func setupEmptyState() {
        emptyLabel = UILabel()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "スニペットがありません\nアプリで同期してください"
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.isHidden = true
        containerView.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: snippetCollectionView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: snippetCollectionView.centerYAnchor)
        ])
    }

    // MARK: - Colors

    private func updateColors() {
        let isDark = textDocumentProxy.keyboardAppearance == .dark || traitCollection.userInterfaceStyle == .dark
        let textColor: UIColor = isDark ? .white : .black
        let secondaryColor: UIColor = isDark ? UIColor.white.withAlphaComponent(0.6) : UIColor.black.withAlphaComponent(0.5)

        deleteButton.setTitleColor(textColor, for: .normal)
        deleteButton.backgroundColor = isDark ? UIColor.white.withAlphaComponent(0.15) : UIColor.black.withAlphaComponent(0.08)
        emptyLabel.textColor = secondaryColor

        updateTabSelection()
        snippetCollectionView.reloadData()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateColors()
        }
    }

    // MARK: - Actions

    @objc private func folderTabTapped(_ sender: UIButton) {
        selectedFolderIndex = sender.tag
        updateTabSelection()
        snippetCollectionView.reloadData()
        updateEmptyState()
    }

    @objc private func deleteTapped() {
        textDocumentProxy.deleteBackward()
    }

    private var deleteTimer: Timer?

    @objc private func deleteLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.textDocumentProxy.deleteBackward()
            }
        case .ended, .cancelled:
            deleteTimer?.invalidate()
            deleteTimer = nil
        default:
            break
        }
    }

    private func insertSnippet(_ snippet: Snippet) {
        let processedContent = processVariables(snippet.content)
        textDocumentProxy.insertText(processedContent)
    }

    private func updateEmptyState() {
        let currentSnippets = currentFolderSnippets
        emptyLabel.isHidden = !currentSnippets.isEmpty || folders.isEmpty == false

        if folders.isEmpty {
            emptyLabel.isHidden = false
        }
    }

    // MARK: - Helpers

    private var currentFolderSnippets: [Snippet] {
        guard selectedFolderIndex < folders.count else { return [] }
        return folders[selectedFolderIndex].snippets.sorted { $0.order < $1.order }
    }

    // MARK: - Variable Processing
    
    private func processVariables(_ text: String) -> String {
        var result = text
        let now = Date()
        let calendar = Calendar.current
        
        // {名前} - User name (App Groupから取得)
        if let userDefaults = UserDefaults(suiteName: appGroupId),
           let data = userDefaults.data(forKey: "settings"),
           let settings = try? JSONDecoder().decode(AppSettingsForKeyboard.self, from: data) {
            result = result.replacingOccurrences(of: "{名前}", with: settings.userName)
            result = result.replacingOccurrences(of: "{name}", with: settings.userName)
        }
        
        // {日付} - Today's date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        result = result.replacingOccurrences(of: "{日付}", with: dateFormatter.string(from: now))
        result = result.replacingOccurrences(of: "{date}", with: dateFormatter.string(from: now))
        
        // {年}, {月}, {日}
        result = result.replacingOccurrences(of: "{年}", with: String(calendar.component(.year, from: now)))
        result = result.replacingOccurrences(of: "{月}", with: String(calendar.component(.month, from: now)))
        result = result.replacingOccurrences(of: "{日}", with: String(calendar.component(.day, from: now)))
        
        // {時刻}
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        result = result.replacingOccurrences(of: "{時刻}", with: timeFormatter.string(from: now))
        result = result.replacingOccurrences(of: "{time}", with: timeFormatter.string(from: now))
        
        // {曜日}
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        let weekdayIndex = calendar.component(.weekday, from: now) - 1
        result = result.replacingOccurrences(of: "{曜日}", with: weekdays[weekdayIndex])
        
        // {明日}
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
            result = result.replacingOccurrences(of: "{明日}", with: dateFormatter.string(from: tomorrow))
        }
        
        // {今日:MM/DD}
        let mmddFormatter = DateFormatter()
        mmddFormatter.dateFormat = "MM/dd"
        result = result.replacingOccurrences(of: "{今日:MM/DD}", with: mmddFormatter.string(from: now))
        
        // {タイムスタンプ}
        let timestampFormatter = DateFormatter()
        timestampFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        result = result.replacingOccurrences(of: "{タイムスタンプ}", with: timestampFormatter.string(from: now))
        
        // 連動日程の処理
        result = processLinkedSchedules(result, from: now)
        
        return result
    }
    
    private func processLinkedSchedules(_ text: String, from date: Date) -> String {
        var result = text
        let calendar = Calendar.current
        
        // ペアB: 1日後 & 2日後
        let (scheduleB1, scheduleB2) = calculateLinkedSchedule(baseDays: 1, alternativeDays: 2, from: date)
        result = result.replacingOccurrences(
            of: "{1日後:M月D日:曜日短（毎月1日は除外して2日後）}",
            with: formatWithWeekday(scheduleB1)
        )
        result = result.replacingOccurrences(
            of: "{2日後:M月D日:曜日短（毎月1日は除外して3日後）}",
            with: formatWithWeekday(scheduleB2)
        )
        
        // ペアC: 2日後 & 3日後
        let (scheduleC1, scheduleC2) = calculateLinkedSchedule(baseDays: 2, alternativeDays: 3, from: date)
        result = result.replacingOccurrences(
            of: "{2日後:M月D日:曜日短（毎月1日は除外して3日後）}",
            with: formatWithWeekday(scheduleC1)
        )
        result = result.replacingOccurrences(
            of: "{3日後:M月D日:曜日短（毎月1日は除外して4日後）}",
            with: formatWithWeekday(scheduleC2)
        )
        
        return result
    }
    
    private func calculateLinkedSchedule(baseDays: Int, alternativeDays: Int, from date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let schedule1 = addDaysExcluding1st(date, days: baseDays, alternativeDays: alternativeDays)
        
        guard let schedule2Base = calendar.date(byAdding: .day, value: 1, to: schedule1) else {
            return (schedule1, schedule1)
        }
        
        let schedule2: Date
        if calendar.component(.day, from: schedule2Base) == 1 {
            schedule2 = calendar.date(byAdding: .day, value: 1, to: schedule2Base) ?? schedule2Base
        } else {
            schedule2 = schedule2Base
        }
        
        return (schedule1, schedule2)
    }
    
    private func addDaysExcluding1st(_ date: Date, days: Int, alternativeDays: Int) -> Date {
        let calendar = Calendar.current
        guard let result = calendar.date(byAdding: .day, value: days, to: date) else {
            return date
        }
        if calendar.component(.day, from: result) == 1 {
            return calendar.date(byAdding: .day, value: alternativeDays, to: date) ?? date
        }
        return result
    }
    
    private func formatWithWeekday(_ date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        return "\(month)月\(day)日（\(weekdays[weekdayIndex])）"
    }
}

// MARK: - UICollectionViewDataSource

extension KeyboardViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = currentFolderSnippets.count
        emptyLabel.isHidden = count > 0 || folders.isEmpty
        if folders.isEmpty {
            emptyLabel.isHidden = false
        }
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SnippetCell.identifier, for: indexPath) as! SnippetCell
        let snippet = currentFolderSnippets[indexPath.item]
        let isDark = textDocumentProxy.keyboardAppearance == .dark || traitCollection.userInterfaceStyle == .dark
        cell.configure(with: snippet.title, isDark: isDark)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension KeyboardViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let snippet = currentFolderSnippets[indexPath.item]
        insertSnippet(snippet)

        // Visual feedback
        if let cell = collectionView.cellForItem(at: indexPath) as? SnippetCell {
            cell.showTapFeedback()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension KeyboardViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 8 * 3 // left, right, middle
        let availableWidth = collectionView.bounds.width - padding
        let cellWidth = availableWidth / 2
        return CGSize(width: cellWidth, height: 44)
    }
}

// MARK: - SnippetCell

private class SnippetCell: UICollectionViewCell {
    static let identifier = "SnippetCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true

        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    func configure(with title: String, isDark: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isDark ? .white : .black
        contentView.backgroundColor = isDark ? UIColor.white.withAlphaComponent(0.15) : UIColor.black.withAlphaComponent(0.08)
    }

    func showTapFeedback() {
        let originalColor = contentView.backgroundColor
        UIView.animate(withDuration: 0.1, animations: {
            self.contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.contentView.backgroundColor = originalColor
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.contentView.alpha = self.isHighlighted ? 0.6 : 1.0
            }
        }
    }
}
