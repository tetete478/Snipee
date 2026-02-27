//
//  FolderSidebar.swift
//  SnipeeMac
//

import SwiftUI
import UniformTypeIdentifiers
import ObjectiveC

// MARK: - NSMenu Helper

private var menuActionsKey: UInt8 = 0

class MenuAction: NSObject {
    private let handler: () -> Void
    init(_ handler: @escaping () -> Void) {
        self.handler = handler
        super.init()
    }
    @objc func execute(_ sender: NSMenuItem) {
        handler()
    }
}

struct MenuItemDef {
    let title: String
    let image: String
    let handler: () -> Void
    let isDestructive: Bool
}

// MARK: - InlineTextField (NSTextField Wrapper)

struct InlineTextField: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat = 13
    var onCommit: () -> Void
    
    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField()
        tf.stringValue = text
        tf.font = .systemFont(ofSize: fontSize)
        tf.isBordered = true
        tf.bezelStyle = .roundedBezel
        tf.backgroundColor = .textBackgroundColor
        tf.focusRingType = .exterior
        tf.delegate = context.coordinator
        tf.lineBreakMode = .byTruncatingTail
        tf.cell?.isScrollable = true
        tf.cell?.wraps = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            tf.window?.makeFirstResponder(tf)
            tf.currentEditor()?.selectAll(nil)
        }
        return tf
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: InlineTextField
        private var hasCommitted = false
        
        init(_ parent: InlineTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let tf = obj.object as? NSTextField {
                parent.text = tf.stringValue
            }
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            guard !hasCommitted else { return }
            hasCommitted = true
            parent.onCommit()
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                guard !hasCommitted else { return true }
                hasCommitted = true
                parent.onCommit()
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                guard !hasCommitted else { return true }
                hasCommitted = true
                parent.onCommit()
                return true
            }
            return false
        }
    }
}

// MARK: - EllipsisMenuButton

struct EllipsisMenuButton: NSViewRepresentable {
    let items: [MenuItemDef]
    var onBeforeShow: (() -> Void)?
    
    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(frame: .zero)
        button.bezelStyle = .inline
        button.isBordered = false
        button.image = NSImage(systemSymbolName: "ellipsis", accessibilityDescription: nil)
        button.imagePosition = .imageOnly
        button.contentTintColor = .secondaryLabelColor
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.target = context.coordinator
        button.action = #selector(Coordinator.showMenu(_:))
        return button
    }
    
    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.items = items
        context.coordinator.onBeforeShow = onBeforeShow
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(items: items, onBeforeShow: onBeforeShow)
    }
    
    class Coordinator: NSObject {
        var items: [MenuItemDef]
        var onBeforeShow: (() -> Void)?
        
        init(items: [MenuItemDef], onBeforeShow: (() -> Void)?) {
            self.items = items
            self.onBeforeShow = onBeforeShow
            super.init()
        }
        
        @objc func showMenu(_ sender: NSButton) {
            onBeforeShow?()
            
            let menu = NSMenu()
            var actions: [MenuAction] = []
            for item in items {
                if item.title == "-" {
                    menu.addItem(.separator())
                    continue
                }
                let action = MenuAction(item.handler)
                actions.append(action)
                let menuItem = NSMenuItem(title: item.title, action: #selector(MenuAction.execute(_:)), keyEquivalent: "")
                menuItem.target = action
                menuItem.image = NSImage(systemSymbolName: item.image, accessibilityDescription: nil)
                if item.isDestructive {
                    menuItem.attributedTitle = NSAttributedString(
                        string: item.title,
                        attributes: [.foregroundColor: NSColor.systemRed]
                    )
                }
                menu.addItem(menuItem)
            }
            objc_setAssociatedObject(menu, &menuActionsKey, actions, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            let point = NSPoint(x: 0, y: sender.bounds.height + 4)
            menu.popUp(positioning: nil, at: point, in: sender)
        }
    }
}

// MARK: - SidebarItem

enum SidebarItem: Hashable {
    case folder(id: String, name: String, isMaster: Bool)
    case snippet(id: String, title: String, folderId: String, isMaster: Bool)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .folder(let id, _, _):
            hasher.combine("folder-\(id)")
        case .snippet(let id, _, _, _):
            hasher.combine("snippet-\(id)")
        }
    }
    
    static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
        switch (lhs, rhs) {
        case (.folder(let id1, _, _), .folder(let id2, _, _)):
            return id1 == id2
        case (.snippet(let id1, _, _, _), .snippet(let id2, _, _, _)):
            return id1 == id2
        default:
            return false
        }
    }
}

// MARK: - SidebarKeyboardMonitor

struct SidebarKeyboardMonitor: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyMonitorView()
        view.onKeyDown = onKeyDown
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? KeyMonitorView)?.onKeyDown = onKeyDown
    }
}

private class KeyMonitorView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    private var monitor: Any?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            // ウィンドウに追加された時だけ登録
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, let handled = self.onKeyDown?(event) else { return event }
                return handled ? nil : event
            }
        } else {
            // ウィンドウから外れたら解除
            if let m = monitor {
                NSEvent.removeMonitor(m)
                monitor = nil
            }
        }
    }
}

// MARK: - FolderSidebar

struct FolderSidebar: View {
    @Binding var personalFolders: [SnippetFolder]
    @Binding var masterFolders: [SnippetFolder]
    @Binding var selectedFolderId: String?
    @Binding var selectedSnippetId: String?
    @Binding var isShowingMaster: Bool
    var isAdmin: Bool
    var isReadOnly: Bool = false
    var onSave: () -> Void
    var onPromoteSnippet: ((Snippet, String) -> Void)?
    var onDemoteSnippet: ((Snippet, String) -> Void)?
    var onPromoteFolder: ((SnippetFolder) -> Void)?
    var onDemoteFolder: ((SnippetFolder) -> Void)?
    
    @State private var isAddingFolder = false
    @State private var newFolderName = ""
    @State private var expandedMasterFolderIds: Set<String> = []
    @State private var expandedPersonalFolderIds: Set<String> = []
    @State private var draggingSnippet: Snippet?
    @State private var draggingSnippetSourceFolder: SnippetFolder?
    @State private var draggingSnippetIsMaster: Bool = false
    @State private var draggingFolder: SnippetFolder?
    @State private var draggingFolderIsMaster: Bool = false
    @State private var isMasterSectionExpanded: Bool = true
    @State private var isPersonalSectionExpanded: Bool = true
    @State private var showDeleteAlert: Bool = false
    @State private var deleteAlertMessage: String = ""
    @State private var pendingDeleteAction: (() -> Void)?
    
    @State private var editingSnippetId: String?
    @State private var editingFolderId: String?
    @State private var focusedItemId: String?
    @State private var flatItems: [SidebarItem] = []
    @State private var isMonitoringKeyboard: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("スニペット")
                    .font(.headline)
                    .foregroundColor(Color(.labelColor))
                Spacer()
                Button(action: { addFolder(isMaster: isShowingMaster && isAdmin) }) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(Color(.labelColor))
                }
                .buttonStyle(.plain)
                .help("個別フォルダを追加")
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - 個別セクション
                    if !isReadOnly {
                        SectionHeader(
                            title: "個別",
                            count: personalFolders.count,
                            isExpanded: isPersonalSectionExpanded,
                            onToggle: { isPersonalSectionExpanded.toggle() }
                        )
                        .onDrop(of: [.text], delegate: SectionDropDelegate(
                            isMasterSection: false,
                            draggingSnippet: $draggingSnippet,
                            draggingSnippetSourceFolder: $draggingSnippetSourceFolder,
                            draggingSnippetIsMaster: $draggingSnippetIsMaster,
                            draggingFolder: $draggingFolder,
                            draggingFolderIsMaster: $draggingFolderIsMaster,
                            onPromoteSnippet: onPromoteSnippet,
                            onDemoteSnippet: onDemoteSnippet,
                            onPromoteFolder: onPromoteFolder,
                            onDemoteFolder: onDemoteFolder
                        ))
                        
                        if isPersonalSectionExpanded {
                            ForEach(personalFolders) { folder in
                                FolderRow(
                                    folder: folder,
                                    isExpanded: expandedPersonalFolderIds.contains(folder.id),
                                    isFocused: focusedItemId == "folder-\(folder.id)",
                                    focusedItemId: focusedItemId,
                                    selectedSnippetId: $selectedSnippetId,
                                    editingSnippetId: $editingSnippetId,
                                    editingFolderId: $editingFolderId,
                                    isShowingMaster: false,
                                    isAdmin: isAdmin,
                                    draggingSnippet: $draggingSnippet,
                                    onToggle: {
                                        togglePersonalFolder(folder.id)
                                        focusedItemId = "folder-\(folder.id)"
                                        isShowingMaster = false
                                    },
                                    onSelectSnippet: { snippet in
                                        editingSnippetId = nil
                                        editingFolderId = nil
                                        isShowingMaster = false
                                        selectedFolderId = folder.id
                                        selectedSnippetId = snippet.id
                                    },
                                    onDeleteFolder: {
                                        deleteAlertMessage = "「\(folder.name)」フォルダを削除しますか？\n（スニペット\(folder.snippets.count)件も削除されます）"
                                        pendingDeleteAction = { deleteFolder(folder) }
                                        showDeleteAlert = true
                                    },
                                    onDeleteSnippet: { snippet in
                                        deleteAlertMessage = "「\(snippet.title)」を削除しますか？"
                                        pendingDeleteAction = { deleteSnippet(snippet, from: folder) }
                                        showDeleteAlert = true
                                    },
                                    onMoveSnippet: { from, to in
                                        movePersonalSnippet(in: folder, from: from, to: to)
                                    },
                                    onRenameFolder: {
                                        editingFolderId = folder.id
                                    },
                                    onRenameSnippet: { snippet in
                                        editingSnippetId = snippet.id
                                    },
                                    onAddSnippet: {
                                        addSnippetInline(to: folder, isMaster: false)
                                    },
                                    onStartDragSnippet: { snippet in
                                        draggingSnippetSourceFolder = folder
                                        draggingSnippetIsMaster = false
                                    },
                                    onPromoteFolder: { onPromoteFolder?(folder) },
                                    onDemoteFolder: { },
                                    onPromoteSnippet: { snippet in onPromoteSnippet?(snippet, folder.name) },
                                    onDemoteSnippet: { _ in },
                                    onAddFolder: { addFolder() },
                                    onDropSnippetToFolder: { snippet in
                                        movePersonalSnippetBetweenFolders(snippet, toFolder: folder)
                                    },
                                    draggingSnippetIsMaster: draggingSnippetIsMaster,
                                    onCommitSnippetRename: { snippetId, newTitle in
                                        commitSnippetRename(snippetId: snippetId, newTitle: newTitle, isMaster: false)
                                    },
                                    onCommitFolderRename: { newName in
                                        commitFolderRename(folderId: folder.id, newName: newName, isMaster: false)
                                    }
                                )
                                .id("folder-\(folder.id)")
                                .onDrag {
                                    self.draggingFolder = folder
                                    self.draggingFolderIsMaster = false
                                    self.expandedPersonalFolderIds.removeAll()
                                    return NSItemProvider(object: folder.id as NSString)
                                }
                                .onDrop(of: [.text], delegate: FolderDropDelegate(
                                    folder: folder,
                                    folders: $personalFolders,
                                    draggingFolder: $draggingFolder,
                                    onSave: onSave
                                ))
                            }
                            
                            if personalFolders.isEmpty {
                                Text("個別スニペットがありません")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(.tertiaryLabelColor))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                        }
                        
                        Rectangle()
                            .fill(Color(.separatorColor))
                            .frame(height: 2)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                    }
                    
                    // MARK: - マスタセクション
                    SectionHeader(
                        title: "マスタ",
                        count: masterFolders.count,
                        isExpanded: isMasterSectionExpanded,
                        onToggle: { isMasterSectionExpanded.toggle() }
                    )
                    .onDrop(of: [.text], delegate: SectionDropDelegate(
                        isMasterSection: true,
                        draggingSnippet: $draggingSnippet,
                        draggingSnippetSourceFolder: $draggingSnippetSourceFolder,
                        draggingSnippetIsMaster: $draggingSnippetIsMaster,
                        draggingFolder: $draggingFolder,
                        draggingFolderIsMaster: $draggingFolderIsMaster,
                        onPromoteSnippet: onPromoteSnippet,
                        onDemoteSnippet: onDemoteSnippet,
                        onPromoteFolder: onPromoteFolder,
                        onDemoteFolder: onDemoteFolder
                    ))
                    
                    if isMasterSectionExpanded {
                        ForEach(masterFolders) { folder in
                            FolderRow(
                                folder: folder,
                                isExpanded: expandedMasterFolderIds.contains(folder.id),
                                isFocused: focusedItemId == "folder-\(folder.id)",
                                focusedItemId: focusedItemId,
                                selectedSnippetId: $selectedSnippetId,
                                editingSnippetId: $editingSnippetId,
                                editingFolderId: $editingFolderId,
                                isShowingMaster: true,
                                isAdmin: isAdmin,
                                isReadOnly: isReadOnly,
                                draggingSnippet: $draggingSnippet,
                                onToggle: {
                                        toggleMasterFolder(folder.id)
                                        focusedItemId = "folder-\(folder.id)"
                                        isShowingMaster = true
                                    },
                                onSelectSnippet: { snippet in
                                    editingSnippetId = nil
                                    editingFolderId = nil
                                    isShowingMaster = true
                                    selectedFolderId = folder.id
                                    selectedSnippetId = snippet.id
                                },
                                onDeleteFolder: {
                                    deleteAlertMessage = "マスタ「\(folder.name)」フォルダを削除しますか？\n（スニペット\(folder.snippets.count)件も削除されます）"
                                    pendingDeleteAction = { deleteMasterFolder(folder) }
                                    showDeleteAlert = true
                                },
                                onDeleteSnippet: { snippet in
                                    deleteAlertMessage = "マスタ「\(snippet.title)」を削除しますか？"
                                    pendingDeleteAction = { deleteMasterSnippet(snippet, from: folder) }
                                    showDeleteAlert = true
                                },
                                onMoveSnippet: { from, to in
                                    moveMasterSnippet(in: folder, from: from, to: to)
                                },
                                onRenameFolder: {
                                    editingFolderId = folder.id
                                },
                                onRenameSnippet: { snippet in
                                    editingSnippetId = snippet.id
                                },
                                onAddSnippet: {
                                    addSnippetInline(to: folder, isMaster: true)
                                },
                                onStartDragSnippet: { snippet in
                                    draggingSnippetSourceFolder = folder
                                    draggingSnippetIsMaster = true
                                },
                                onPromoteFolder: { },
                                onDemoteFolder: { onDemoteFolder?(folder) },
                                onPromoteSnippet: { _ in },
                                onDemoteSnippet: { snippet in onDemoteSnippet?(snippet, folder.name) },
                                onAddFolder: { addFolder(isMaster: true) },
                                    onDropSnippetToFolder: { snippet in
                                        moveMasterSnippetBetweenFolders(snippet, toFolder: folder)
                                    },
                                    draggingSnippetIsMaster: draggingSnippetIsMaster,
                                    onCommitSnippetRename: { snippetId, newTitle in
                                        commitSnippetRename(snippetId: snippetId, newTitle: newTitle, isMaster: true)
                                    },
                                onCommitFolderRename: { newName in
                                    commitFolderRename(folderId: folder.id, newName: newName, isMaster: true)
                                }
                            )
                            .id("folder-\(folder.id)")
                            .onDrag {
                                guard !isReadOnly else { return NSItemProvider() }
                                self.draggingFolder = folder
                                self.draggingFolderIsMaster = true
                                return NSItemProvider(object: folder.id as NSString)
                            }
                            .onDrop(of: [.text], delegate: FolderDropDelegate(
                                folder: folder,
                                folders: $masterFolders,
                                draggingFolder: $draggingFolder,
                                onSave: onSave
                            ))
                        }
                        
                        if masterFolders.isEmpty {
                            Text("マスタスニペットがありません")
                                .font(.system(size: 11))
                                .foregroundColor(Color(.tertiaryLabelColor))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .background(Color(.controlBackgroundColor))
            .onTapGesture {
                // NSTextFieldのファーストレスポンダーを先に解放してからstateをクリア
                NSApp.keyWindow?.makeFirstResponder(nil)
                if editingFolderId != nil { editingFolderId = nil }
                if editingSnippetId != nil { editingSnippetId = nil }
            }
            .onChange(of: selectedSnippetId) { _, newValue in
                if let id = newValue {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
            .onChange(of: focusedItemId) { _, newValue in
                if let id = newValue {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
            .background(SidebarKeyboardMonitor { event in
                return handleKeyboardEvent(event)
            })
            }
            
            Divider()
            
            HStack {
                Text("\(masterFolders.count + personalFolders.count) フォルダ")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.secondaryLabelColor))
                Spacer()
            }
            .padding(8)
            .background(Color(.windowBackgroundColor))
        }
        .background(Color(.windowBackgroundColor))
        .alert("削除確認", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) {
                pendingDeleteAction?()
                pendingDeleteAction = nil
            }
            Button("キャンセル", role: .cancel) {
                pendingDeleteAction = nil
            }
        } message: {
            Text(deleteAlertMessage)
        }
        
        .onAppear {
            if let firstMaster = masterFolders.first {
                expandedMasterFolderIds.insert(firstMaster.id)
            }
            if let firstPersonal = personalFolders.first {
                expandedPersonalFolderIds.insert(firstPersonal.id)
            }
            buildFlatList()
            if !flatItems.isEmpty {
                let firstItem = flatItems[0]
                focusedItemId = firstItem.getID()
                applyFocusSelection(firstItem)
            }
            isMonitoringKeyboard = true
        }
    }
    
    // MARK: - Toggle
    
    private func toggleMasterFolder(_ folderId: String) {
        if expandedMasterFolderIds.contains(folderId) {
            expandedMasterFolderIds.remove(folderId)
        } else {
            expandedMasterFolderIds.insert(folderId)
        }
    }
    
    private func togglePersonalFolder(_ folderId: String) {
        if expandedPersonalFolderIds.contains(folderId) {
            expandedPersonalFolderIds.remove(folderId)
        } else {
            expandedPersonalFolderIds.insert(folderId)
        }
    }
    
    // MARK: - Folder Actions
    
    private func addFolder(isMaster: Bool = false) {
        if isMaster && isAdmin {
            let newFolder = SnippetFolder(name: "新規フォルダ", order: masterFolders.count)
            masterFolders.append(newFolder)
            selectedFolderId = newFolder.id
            isShowingMaster = true
            expandedMasterFolderIds.insert(newFolder.id)
            editingFolderId = newFolder.id
        } else {
            let newFolder = SnippetFolder(name: "新規フォルダ", order: personalFolders.count)
            personalFolders.append(newFolder)
            selectedFolderId = newFolder.id
            isShowingMaster = false
            expandedPersonalFolderIds.insert(newFolder.id)
            editingFolderId = newFolder.id
        }
        onSave()
    }
    
    private func deleteFolder(_ folder: SnippetFolder) {
        PersonalSyncService.shared.markAsDeleted(id: folder.id)
        folder.snippets.forEach { PersonalSyncService.shared.markAsDeleted(id: $0.id) }
        personalFolders.removeAll { $0.id == folder.id }
        expandedPersonalFolderIds.remove(folder.id)
        if selectedFolderId == folder.id {
            selectedFolderId = personalFolders.first?.id
            selectedSnippetId = personalFolders.first?.snippets.first?.id
            isShowingMaster = false
        }
        onSave()
    }
    
    private func deleteMasterFolder(_ folder: SnippetFolder) {
        guard isAdmin else { return }
        masterFolders.removeAll { $0.id == folder.id }
        expandedMasterFolderIds.remove(folder.id)
        if selectedFolderId == folder.id {
            selectedFolderId = masterFolders.first?.id
            selectedSnippetId = masterFolders.first?.snippets.first?.id
        }
        onSave()
    }
    
    private func deleteSnippet(_ snippet: Snippet, from folder: SnippetFolder) {
        guard let folderIndex = personalFolders.firstIndex(where: { $0.id == folder.id }) else { return }
        PersonalSyncService.shared.markAsDeleted(id: snippet.id)
        personalFolders[folderIndex].snippets.removeAll { $0.id == snippet.id }
        if selectedSnippetId == snippet.id {
            selectedSnippetId = personalFolders[folderIndex].snippets.first?.id
        }
        onSave()
    }
    
    private func deleteMasterSnippet(_ snippet: Snippet, from folder: SnippetFolder) {
        guard isAdmin else { return }
        guard let folderIndex = masterFolders.firstIndex(where: { $0.id == folder.id }) else { return }
        masterFolders[folderIndex].snippets.removeAll { $0.id == snippet.id }
        if selectedSnippetId == snippet.id {
            selectedSnippetId = masterFolders[folderIndex].snippets.first?.id
        }
        onSave()
    }
    
    // MARK: - Rename
    
    private func commitFolderRename(folderId: String, newName: String, isMaster: Bool) {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            // 空のままコミットされたら新規作成フォルダを削除
            personalFolders.removeAll { $0.id == folderId }
            masterFolders.removeAll { $0.id == folderId }
            editingFolderId = nil
            return
        }
        if isMaster {
            if let index = masterFolders.firstIndex(where: { $0.id == folderId }) {
                guard masterFolders[index].name != trimmedName else { editingFolderId = nil; return }
                masterFolders[index].name = trimmedName
            }
        } else {
            if let index = personalFolders.firstIndex(where: { $0.id == folderId }) {
                guard personalFolders[index].name != trimmedName else { editingFolderId = nil; return }
                personalFolders[index].name = trimmedName
            }
        }
        onSave()
        editingFolderId = nil
    }
    
    // MARK: - Add Snippet Inline
    
    private func addSnippetInline(to folder: SnippetFolder, isMaster: Bool) {
        let newSnippet = Snippet(
            title: "新規スニペット",
            content: "",
            folder: folder.name,
            type: isMaster ? .master : .personal,
            order: folder.snippets.count
        )
        if isMaster {
            if let index = masterFolders.firstIndex(where: { $0.id == folder.id }) {
                masterFolders[index].snippets.append(newSnippet)
                expandedMasterFolderIds.insert(folder.id)
                selectedSnippetId = newSnippet.id
                selectedFolderId = folder.id
                isShowingMaster = true
                editingSnippetId = newSnippet.id
            }
        } else {
            if let index = personalFolders.firstIndex(where: { $0.id == folder.id }) {
                personalFolders[index].snippets.append(newSnippet)
                expandedPersonalFolderIds.insert(folder.id)
                selectedSnippetId = newSnippet.id
                selectedFolderId = folder.id
                isShowingMaster = false
                editingSnippetId = newSnippet.id
            }
        }
    }
    
    private func commitSnippetRename(snippetId: String, newTitle: String, isMaster: Bool) {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { editingSnippetId = nil; return }
        if isMaster {
            for folderIndex in masterFolders.indices {
                if let snippetIndex = masterFolders[folderIndex].snippets.firstIndex(where: { $0.id == snippetId }) {
                    guard masterFolders[folderIndex].snippets[snippetIndex].title != trimmedTitle else { editingSnippetId = nil; return }
                    var folder = masterFolders[folderIndex]
                    folder.snippets[snippetIndex].title = trimmedTitle
                    masterFolders[folderIndex] = folder
                    break
                }
            }
        } else {
            for folderIndex in personalFolders.indices {
                if let snippetIndex = personalFolders[folderIndex].snippets.firstIndex(where: { $0.id == snippetId }) {
                    guard personalFolders[folderIndex].snippets[snippetIndex].title != trimmedTitle else { editingSnippetId = nil; return }
                    var folder = personalFolders[folderIndex]
                    folder.snippets[snippetIndex].title = trimmedTitle
                    personalFolders[folderIndex] = folder
                    break
                }
            }
        }
        onSave()
        editingSnippetId = nil
    }
    
    // MARK: - Move Snippets
    
    private func moveMasterSnippet(in folder: SnippetFolder, from: IndexSet, to: Int) {
        guard let folderIndex = masterFolders.firstIndex(where: { $0.id == folder.id }) else { return }
        masterFolders[folderIndex].snippets.move(fromOffsets: from, toOffset: to)
        onSave()
    }
    
    private func movePersonalSnippet(in folder: SnippetFolder, from: IndexSet, to: Int) {
        guard let folderIndex = personalFolders.firstIndex(where: { $0.id == folder.id }) else { return }
        personalFolders[folderIndex].snippets.move(fromOffsets: from, toOffset: to)
        onSave()
    }
    
    private func movePersonalSnippetBetweenFolders(_ snippet: Snippet, toFolder targetFolder: SnippetFolder) {
        // 移動元フォルダから削除
        for i in personalFolders.indices {
            if let idx = personalFolders[i].snippets.firstIndex(where: { $0.id == snippet.id }) {
                personalFolders[i].snippets.remove(at: idx)
                break
            }
        }
        // 移動先フォルダに追加
        if let targetIndex = personalFolders.firstIndex(where: { $0.id == targetFolder.id }) {
            var movedSnippet = snippet
            movedSnippet.folder = targetFolder.name
            personalFolders[targetIndex].snippets.append(movedSnippet)
        }
        onSave()
    }

    private func moveMasterSnippetBetweenFolders(_ snippet: Snippet, toFolder targetFolder: SnippetFolder) {
        for i in masterFolders.indices {
            if let idx = masterFolders[i].snippets.firstIndex(where: { $0.id == snippet.id }) {
                masterFolders[i].snippets.remove(at: idx)
                break
            }
        }
        if let targetIndex = masterFolders.firstIndex(where: { $0.id == targetFolder.id }) {
            var movedSnippet = snippet
            movedSnippet.folder = targetFolder.name
            masterFolders[targetIndex].snippets.append(movedSnippet)
        }
        onSave()
    }

    // MARK: - Keyboard Navigation
    
    private func buildFlatList() {
        var items: [SidebarItem] = []
        if !isReadOnly && isPersonalSectionExpanded {
            for folder in personalFolders {
                items.append(.folder(id: folder.id, name: folder.name, isMaster: false))
                if expandedPersonalFolderIds.contains(folder.id) {
                    for snippet in folder.snippets {
                        items.append(.snippet(id: snippet.id, title: snippet.title, folderId: folder.id, isMaster: false))
                    }
                }
            }
        }
        
        if isMasterSectionExpanded {
            for folder in masterFolders {
                items.append(.folder(id: folder.id, name: folder.name, isMaster: true))
                if expandedMasterFolderIds.contains(folder.id) {
                    for snippet in folder.snippets {
                        items.append(.snippet(id: snippet.id, title: snippet.title, folderId: folder.id, isMaster: true))
                    }
                }
            }
        }
        
        flatItems = items
    }
    
    private func navigateUp() {
        buildFlatList()
        guard !flatItems.isEmpty else { return }
        
        if let currentId = focusedItemId,
           let currentIndex = flatItems.firstIndex(where: { $0.getID() == currentId }),
           currentIndex > 0 {
            let prevItem = flatItems[currentIndex - 1]
            focusedItemId = prevItem.getID()
            applyFocusSelection(prevItem)
        } else {
            let firstItem = flatItems[0]
            focusedItemId = firstItem.getID()
            applyFocusSelection(firstItem)
        }
    }
    
    private func navigateDown() {
        buildFlatList()
        guard !flatItems.isEmpty else { return }
        
        if let currentId = focusedItemId,
           let currentIndex = flatItems.firstIndex(where: { $0.getID() == currentId }),
           currentIndex < flatItems.count - 1 {
            let nextItem = flatItems[currentIndex + 1]
            focusedItemId = nextItem.getID()
            applyFocusSelection(nextItem)
        } else {
            let firstItem = flatItems[0]
            focusedItemId = firstItem.getID()
            applyFocusSelection(firstItem)
        }
    }
    
    private func handleEnter() {
        guard let currentId = focusedItemId else { return }
        
        if let index = flatItems.firstIndex(where: { $0.getID() == currentId }) {
            let item = flatItems[index]
            switch item {
            case .folder(let id, _, let isMaster):
                if isMaster {
                    toggleMasterFolder(id)
                } else {
                    togglePersonalFolder(id)
                }
            case .snippet(let id, _, let folderId, _):
                // スニペット選択時は何もしない（↑↓で既に選択済み）
                break
            }
        }
    }
    
    private func applyFocusSelection(_ item: SidebarItem) {
        switch item {
        case .snippet(let id, _, let folderId, let isMaster):
            selectedSnippetId = id
            selectedFolderId = folderId
            isShowingMaster = isMaster
        case .folder:
            // フォルダはコンテンツパネル選択対象外
            break
        }
    }
    
    private func handleKeyboardEvent(_ event: NSEvent) -> Bool {
        // PopupWindow が表示中なら FolderSidebar のキーナビをスキップ
        if PopupWindowController.shared.isPopupVisible {
            return false
        }

        guard let eventWindow = event.window, eventWindow.isKeyWindow else {
            return false
        }
        
        // テキストフィールド（InlineTextField含む）が編集中ならスキップ
        if let firstResponder = event.window?.firstResponder,
           firstResponder is NSTextView {
            return false
        }
        
        if editingSnippetId != nil || editingFolderId != nil {
            return false
        }
        
        switch event.keyCode {
        case 126:  // ↑
            navigateUp()
            return true
        case 125:  // ↓
            navigateDown()
            return true
        case 36:   // Enter
            handleEnter()
            return true
        case 53:   // Escape
            return false
        default:
            return false
        }
    }
}

// MARK: - SidebarItem Extension

extension SidebarItem {
    func getID() -> String {
        switch self {
        case .folder(let id, _, _):
            return "folder-\(id)"
        case .snippet(let id, _, _, _):
            return "snippet-\(id)"
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let count: Int
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(.secondaryLabelColor))
                .frame(width: 12)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.secondaryLabelColor))
            Spacer()
            Text("\(count)")
                .font(.system(size: 10))
                .foregroundColor(Color(.tertiaryLabelColor))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.separatorColor).opacity(0.5))
                .cornerRadius(4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}

// MARK: - Section Drop Delegate

struct SectionDropDelegate: DropDelegate {
    let isMasterSection: Bool
    @Binding var draggingSnippet: Snippet?
    @Binding var draggingSnippetSourceFolder: SnippetFolder?
    @Binding var draggingSnippetIsMaster: Bool
    @Binding var draggingFolder: SnippetFolder?
    @Binding var draggingFolderIsMaster: Bool
    var onPromoteSnippet: ((Snippet, String) -> Void)?
    var onDemoteSnippet: ((Snippet, String) -> Void)?
    var onPromoteFolder: ((SnippetFolder) -> Void)?
    var onDemoteFolder: ((SnippetFolder) -> Void)?
    
    func performDrop(info: DropInfo) -> Bool {
        if let snippet = draggingSnippet, let folder = draggingSnippetSourceFolder {
            if isMasterSection && !draggingSnippetIsMaster {
                onPromoteSnippet?(snippet, folder.name)
            } else if !isMasterSection && draggingSnippetIsMaster {
                onDemoteSnippet?(snippet, folder.name)
            }
        }
        if let folder = draggingFolder {
            if isMasterSection && !draggingFolderIsMaster {
                onPromoteFolder?(folder)
            } else if !isMasterSection && draggingFolderIsMaster {
                onDemoteFolder?(folder)
            }
        }
        draggingSnippet = nil
        draggingSnippetSourceFolder = nil
        draggingFolder = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {}
    func validateDrop(info: DropInfo) -> Bool { draggingSnippet != nil || draggingFolder != nil }
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
}

// MARK: - Folder Drop Delegate

struct FolderDropDelegate: DropDelegate {
    let folder: SnippetFolder
    @Binding var folders: [SnippetFolder]
    @Binding var draggingFolder: SnippetFolder?
    let onSave: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggingFolder = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let dragging = draggingFolder,
              dragging.id != folder.id,
              let fromIndex = folders.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            folders.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
        onSave()
    }
}

// MARK: - Folder Header Drop Delegate

struct FolderHeaderDropDelegate: DropDelegate {
    let targetFolder: SnippetFolder
    let targetIsMaster: Bool
    @Binding var draggingSnippet: Snippet?
    let draggingSnippetIsMaster: Bool
    let isAdmin: Bool
    var onDrop: (Snippet) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        guard let snippet = draggingSnippet else { return false }
        // 同セクション間のみ許可
        if targetIsMaster != draggingSnippetIsMaster { return false }
        // マスタ間移動は管理者のみ
        if targetIsMaster && !isAdmin { return false }
        // 同フォルダへのドロップは無効
        if snippet.folder == targetFolder.name { return false }
        return true
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let snippet = draggingSnippet else { return false }
        onDrop(snippet)
        draggingSnippet = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func dropEntered(info: DropInfo) {}
}

// MARK: - Folder Row

struct FolderRow: View {
    let folder: SnippetFolder
    let isExpanded: Bool
    let isFocused: Bool
    let focusedItemId: String?
    @Binding var selectedSnippetId: String?
    @Binding var editingSnippetId: String?
    @Binding var editingFolderId: String?
    let isShowingMaster: Bool
    let isAdmin: Bool
    var isReadOnly: Bool = false
    @Binding var draggingSnippet: Snippet?
    let onToggle: () -> Void
    let onSelectSnippet: (Snippet) -> Void
    let onDeleteFolder: () -> Void
    let onDeleteSnippet: (Snippet) -> Void
    let onMoveSnippet: (IndexSet, Int) -> Void
    let onRenameFolder: () -> Void
    let onRenameSnippet: (Snippet) -> Void
    let onAddSnippet: () -> Void
    let onStartDragSnippet: (Snippet) -> Void
    let onPromoteFolder: () -> Void
    let onDemoteFolder: () -> Void
    let onPromoteSnippet: (Snippet) -> Void
    let onDemoteSnippet: (Snippet) -> Void
    let onAddFolder: () -> Void
    let onDropSnippetToFolder: ((Snippet) -> Void)?
    var draggingSnippetIsMaster: Bool = false
    let onCommitSnippetRename: ((String, String) -> Void)?
    let onCommitFolderRename: ((String) -> Void)?
    
    @State private var editingFolderName: String = ""
    
    private var isEditingFolder: Bool { editingFolderId == folder.id }
    private var canEdit: Bool { !isReadOnly && (!isShowingMaster || isAdmin) }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Color.clear.frame(width: 8)
                
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabelColor))
                    .frame(width: 12)
                Image(systemName: "folder.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                
                if isEditingFolder {
                    InlineTextField(
                        text: $editingFolderName,
                        fontSize: 13,
                        onCommit: { onCommitFolderRename?(editingFolderName) }
                    )
                    .frame(height: 22)
                    .onAppear { editingFolderName = folder.name }
                } else {
                    Text(folder.name)
                        .font(.system(size: 13))
                        .foregroundColor(Color(.labelColor))
                        .lineLimit(1)
                }
                
                Spacer()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isEditingFolder { onToggle() }
                    }
                
                if canEdit && !isEditingFolder {
                    EllipsisMenuButton(items: folderMenuItems())
                        .frame(width: 20, height: 20)
                }
                
                Text("\(folder.snippets.count)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabelColor))
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isFocused ? Color.accentColor.opacity(0.3) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
            .onDrop(of: [.text], delegate: FolderHeaderDropDelegate(
                targetFolder: folder,
                targetIsMaster: isShowingMaster,
                draggingSnippet: $draggingSnippet,
                draggingSnippetIsMaster: draggingSnippetIsMaster,
                isAdmin: isAdmin,
                onDrop: { snippet in onDropSnippetToFolder?(snippet) }
            ))
            .onTapGesture(count: 2) {
                if canEdit { onRenameFolder() }
            }
            .onTapGesture(count: 1) {
                onToggle()
            }
            .contextMenu {
                if canEdit {
                    Button { onAddSnippet() } label: { Label("新規スニペット", systemImage: "doc.badge.plus") }
                    Button { onAddFolder() } label: { Label("新規フォルダ", systemImage: "folder.badge.plus") }
                    Button { onRenameFolder() } label: { Label("名前を変更", systemImage: "pencil") }
                    if isAdmin {
                        Divider()
                        if isShowingMaster {
                            Button { onDemoteFolder() } label: { Label("個別に降格", systemImage: "arrow.down.circle") }
                        } else {
                            Button { onPromoteFolder() } label: { Label("マスタに昇格", systemImage: "arrow.up.circle") }
                        }
                    }
                    Divider()
                    Button(role: .destructive) { onDeleteFolder() } label: { Label("削除", systemImage: "trash") }
                }
            }
            
            if isExpanded {
                ForEach(Array(folder.snippets.enumerated()), id: \.element.id) { index, snippet in
                    SnippetRow(
                        snippet: snippet,
                        isSelected: selectedSnippetId == snippet.id,
                        isFocused: focusedItemId == "snippet-\(snippet.id)",
                        isEditing: editingSnippetId == snippet.id,
                        isShowingMaster: isShowingMaster,
                        isAdmin: isAdmin,
                        isReadOnly: isReadOnly,
                        onSelect: { onSelectSnippet(snippet) },
                        onDelete: { onDeleteSnippet(snippet) },
                        onRename: { onRenameSnippet(snippet) },
                        onAddSnippet: onAddSnippet,
                        onPromoteSnippet: { onPromoteSnippet(snippet) },
                        onDemoteSnippet: { onDemoteSnippet(snippet) },
                        onCommitRename: { newTitle in
                            onCommitSnippetRename?(snippet.id, newTitle)
                        }
                    )
                    .onDrag {
                        guard canEdit else { return NSItemProvider() }
                        self.draggingSnippet = snippet
                        onStartDragSnippet(snippet)
                        return NSItemProvider(object: snippet.id as NSString)
                    }
                    .id(snippet.id)
                    .onDrop(of: [.text], delegate: SnippetDropDelegate(
                        snippet: snippet,
                        snippets: folder.snippets,
                        draggingSnippet: $draggingSnippet,
                        onMove: onMoveSnippet
                    ))
                }
            }
        }
        .contentShape(Rectangle())
    }
    
    private func folderMenuItems() -> [MenuItemDef] {
        var items: [MenuItemDef] = [
            MenuItemDef(title: "新規スニペット", image: "doc.badge.plus", handler: { onAddSnippet() }, isDestructive: false),
            MenuItemDef(title: "新規フォルダ", image: "folder.badge.plus", handler: { onAddFolder() }, isDestructive: false),
            MenuItemDef(title: "名前を変更", image: "pencil", handler: { onRenameFolder() }, isDestructive: false),
        ]
        if isAdmin {
            items.append(MenuItemDef(title: "-", image: "", handler: {}, isDestructive: false))
            if isShowingMaster {
                items.append(MenuItemDef(title: "個別に降格", image: "arrow.down.circle", handler: { onDemoteFolder() }, isDestructive: false))
            } else {
                items.append(MenuItemDef(title: "マスタに昇格", image: "arrow.up.circle", handler: { onPromoteFolder() }, isDestructive: false))
            }
        }
        items.append(MenuItemDef(title: "-", image: "", handler: {}, isDestructive: false))
        items.append(MenuItemDef(title: "削除", image: "trash", handler: { onDeleteFolder() }, isDestructive: true))
        return items
    }
}

// MARK: - Snippet Drop Delegate

struct SnippetDropDelegate: DropDelegate {
    let snippet: Snippet
    let snippets: [Snippet]
    @Binding var draggingSnippet: Snippet?
    let onMove: (IndexSet, Int) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggingSnippet = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let dragging = draggingSnippet,
              dragging.id != snippet.id,
              let fromIndex = snippets.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        onMove(IndexSet(integer: fromIndex), toIndex > fromIndex ? toIndex + 1 : toIndex)
    }
}

// MARK: - Snippet Row

struct SnippetRow: View {
    let snippet: Snippet
    let isSelected: Bool
    let isFocused: Bool
    let isEditing: Bool
    let isShowingMaster: Bool
    let isAdmin: Bool
    var isReadOnly: Bool = false
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    let onAddSnippet: () -> Void
    let onPromoteSnippet: () -> Void
    let onDemoteSnippet: () -> Void
    let onCommitRename: ((String) -> Void)?
    
    @State private var editingTitle: String = ""
    
    private var canEdit: Bool { !isReadOnly && (!isShowingMaster || isAdmin) }
    
    var body: some View {
        HStack(spacing: 6) {
            Color.clear.frame(width: 28)
            
            Image(systemName: "doc.text")
                .foregroundColor(Color(.secondaryLabelColor))
                .font(.system(size: 12))
            
            if isEditing {
                InlineTextField(
                    text: $editingTitle,
                    fontSize: 12,
                    onCommit: { onCommitRename?(editingTitle) }
                )
                .frame(height: 20)
                .onAppear { editingTitle = snippet.title }
            } else {
                Text(snippet.title)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.labelColor))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if canEdit && !isEditing {
                EllipsisMenuButton(items: snippetMenuItems(), onBeforeShow: { onSelect() })
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            isFocused
                ? Color.accentColor.opacity(0.3)
                : (isSelected || isEditing
                    ? Color.accentColor.opacity(0.2)
                    : Color.clear)
        )
        .border(
            isFocused ? Color.accentColor : Color.clear,
            width: 1
        )
        .cornerRadius(4)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if !isEditing && canEdit { onRename() }
        }
        .onTapGesture(count: 1) {
            if !isEditing { onSelect() }
        }
        .contextMenu {
            if canEdit {
                Button { onAddSnippet() } label: { Label("新規スニペット", systemImage: "doc.badge.plus") }
                Button { onRename() } label: { Label("名前を変更", systemImage: "pencil") }
                if isAdmin {
                    Divider()
                    if isShowingMaster {
                        Button { onDemoteSnippet() } label: { Label("個別に降格", systemImage: "arrow.down.circle") }
                    } else {
                        Button { onPromoteSnippet() } label: { Label("マスタに昇格", systemImage: "arrow.up.circle") }
                    }
                }
                Divider()
                Button(role: .destructive) { onDelete() } label: { Label("削除", systemImage: "trash") }
            }
        }
    }
    
    private func snippetMenuItems() -> [MenuItemDef] {
        var items: [MenuItemDef] = [
            MenuItemDef(title: "新規スニペット", image: "doc.badge.plus", handler: { onAddSnippet() }, isDestructive: false),
            MenuItemDef(title: "名前を変更", image: "pencil", handler: { onRename() }, isDestructive: false),
        ]
        if isAdmin {
            items.append(MenuItemDef(title: "-", image: "", handler: {}, isDestructive: false))
            if isShowingMaster {
                items.append(MenuItemDef(title: "個別に降格", image: "arrow.down.circle", handler: { onDemoteSnippet() }, isDestructive: false))
            } else {
                items.append(MenuItemDef(title: "マスタに昇格", image: "arrow.up.circle", handler: { onPromoteSnippet() }, isDestructive: false))
            }
        }
        items.append(MenuItemDef(title: "-", image: "", handler: {}, isDestructive: false))
        items.append(MenuItemDef(title: "削除", image: "trash", handler: { onDelete() }, isDestructive: true))
        return items
    }
}

// MARK: - Add Folder Sheet

struct AddFolderSheet: View {
    @Binding var folderName: String
    var onAdd: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("新しいフォルダ")
                .font(.headline)
                .foregroundColor(Color(.labelColor))
            TextField("フォルダ名", text: $folderName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)
            HStack {
                Button("キャンセル", action: onCancel)
                    .keyboardShortcut(.escape)
                Button("追加", action: onAdd)
                    .keyboardShortcut(.return)
                    .disabled(folderName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
        .background(Color(.windowBackgroundColor))
    }
}
