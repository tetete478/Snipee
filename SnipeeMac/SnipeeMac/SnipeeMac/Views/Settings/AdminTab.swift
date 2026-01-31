//
//  AdminTab.swift
//  SnipeeMac
//

import SwiftUI
import UniformTypeIdentifiers

struct AdminTab: View {
    @State private var isAdmin = false
    @State private var isSuperAdmin = false
    @State private var userDepartment = ""
    @State private var selectedExportFolders: Set<String> = []
    @State private var folders: [SnippetFolder] = []
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var uploadSuccess = false
    
    // 監視ダッシュボード用
    @State private var allUsers: [UserStatus] = []
    @State private var isLoadingUsers = false
    @State private var selectedTab = 0
    
    // 全部署マスタ閲覧用
    @State private var allDepartments: [DepartmentInfo] = []
    @State private var selectedDepartment: DepartmentInfo?
    @State private var departmentSnippets: [SnippetFolder] = []
    @State private var isLoadingDepartment = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isSuperAdmin {
                // 最高管理者: タブ切り替え
                Picker("", selection: $selectedTab) {
                    Text("ユーザー監視").tag(0)
                    Text("部署マスタ").tag(1)
                    Text("管理ツール").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 16)
                
                switch selectedTab {
                case 0:
                    userMonitoringView
                case 1:
                    departmentMasterView
                case 2:
                    adminToolsView
                default:
                    EmptyView()
                }
            } else if isAdmin {
                // 管理者: 部署マスタと管理ツールのみ
                Picker("", selection: $selectedTab) {
                    Text("部署マスタ").tag(1)
                    Text("管理ツール").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 16)
                
                switch selectedTab {
                case 1:
                    departmentMasterView
                case 2:
                    adminToolsView
                default:
                    EmptyView()
                }
            } else {
                // 一般ユーザー
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("管理者権限が必要です")
                        .font(.headline)
                    
                    Text("この機能を使用するには、管理者としてログインしてください")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - User Monitoring View (Super Admin Only)
    
    private var userMonitoringView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ユーザー監視")
                    .font(.headline)
                Spacer()
                Button(action: loadAllUsers) {
                    HStack(spacing: 4) {
                        if isLoadingUsers {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Image(systemName: "arrow.clockwise")
                        Text("更新")
                    }
                }
                .disabled(isLoadingUsers)
            }
            
            // サマリー
            HStack(spacing: 16) {
                summaryCard(title: "総ユーザー", value: "\(allUsers.count)", color: .blue)
                summaryCard(title: "旧バージョン", value: "\(allUsers.filter { $0.isOutdated }.count)", color: .orange)
                summaryCard(title: "7日以上未使用", value: "\(allUsers.filter { $0.isInactive }.count)", color: .red)
            }
            
            // ユーザーリスト
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(allUsers) { user in
                        userRow(user: user)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
    
    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func userRow(user: UserStatus) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .fontWeight(.medium)
                Text(user.department)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    if user.isOutdated {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    Text(user.version.isEmpty ? "-" : "v\(user.version)")
                        .font(.caption)
                        .foregroundColor(user.isOutdated ? .orange : .primary)
                }
                
                Text(user.lastActive.isEmpty ? "未使用" : user.lastActive)
                    .font(.caption)
                    .foregroundColor(user.isInactive ? .red : .secondary)
            }
            
            Text(user.snippetCount.isEmpty ? "-" : "\(user.snippetCount)件")
                .font(.caption)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    // MARK: - Department Master View (Admin+)
    
    private var departmentMasterView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("部署マスタ閲覧")
                .font(.headline)
            
            HStack {
                Picker("部署を選択", selection: $selectedDepartment) {
                    Text("選択してください").tag(nil as DepartmentInfo?)
                    ForEach(allDepartments, id: \.name) { dept in
                        Text(dept.name).tag(dept as DepartmentInfo?)
                    }
                }
                .frame(width: 200)
                
                Button(action: loadDepartmentSnippets) {
                    HStack {
                        if isLoadingDepartment {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Text("読み込み")
                    }
                }
                .disabled(selectedDepartment == nil || isLoadingDepartment)
            }
            
            if !departmentSnippets.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(departmentSnippets, id: \.id) { folder in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(folder.name)
                                    .fontWeight(.medium)
                                Text("\(folder.snippets.count)件のスニペット")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(maxHeight: 250)
            }
        }
    }
    
    // MARK: - Admin Tools View
    
    private var adminToolsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Upload Section
            VStack(alignment: .leading, spacing: 8) {
                Text("マスタXMLアップロード")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("現在のマスタスニペットをDriveにアップロードします")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button(action: uploadMasterXML) {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "icloud.and.arrow.up")
                            }
                            Text(isUploading ? "アップロード中..." : "マスタをアップロード")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(isUploading || userDepartment.isEmpty)
                    
                    Spacer()
                }
                
                if let error = uploadError {
                    Text("エラー: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if uploadSuccess {
                    Text("✅ アップロード完了")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            // Export Section
            VStack(alignment: .leading, spacing: 8) {
                Text("XMLエクスポート")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if folders.isEmpty {
                    Text("スニペットがありません")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(folders, id: \.id) { folder in
                        Toggle(folder.name, isOn: Binding(
                            get: { selectedExportFolders.contains(folder.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedExportFolders.insert(folder.id)
                                } else {
                                    selectedExportFolders.remove(folder.id)
                                }
                            }
                        ))
                    }
                }
                
                Button(action: exportXML) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("エクスポート")
                    }
                }
                .disabled(selectedExportFolders.isEmpty)
            }
            
            Divider()
            
            // Import Section
            VStack(alignment: .leading, spacing: 8) {
                Text("XMLインポート")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Button(action: importXML) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("ファイルを選択")
                    }
                }
            }
            
            Divider()
            
            // Spreadsheet Link
            VStack(alignment: .leading, spacing: 8) {
                Text("メンバー管理")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Link("📊 スプレッドシートを開く", destination: URL(string: "https://docs.google.com/spreadsheets/d/1IIl0mE96JZwTj-M742DVmVgBLIH27iAzT0lzrpu7qbM")!)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        let cached = SyncService.shared.getCachedMemberInfo()
        if let role = cached.role {
            isAdmin = (role == "管理者" || role == "最高管理者")
            isSuperAdmin = (role == "最高管理者")
        }
        if let dept = cached.department {
            userDepartment = dept
        }
        folders = StorageService.shared.getPersonalSnippets() + StorageService.shared.getMasterSnippets()
        
        // 管理者以上なら部署一覧を取得
        if isAdmin {
            loadAllDepartments()
        }
        
        // 最高管理者ならユーザー一覧も取得
        if isSuperAdmin {
            loadAllUsers()
        }
    }
    
    private func loadAllUsers() {
        isLoadingUsers = true
        GoogleSheetsService.shared.fetchAllMembers { result in
            isLoadingUsers = false
            switch result {
            case .success(let users):
                allUsers = users
            case .failure(let error):
                print("Failed to load users: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadAllDepartments() {
        GoogleSheetsService.shared.fetchAllDepartments { result in
            switch result {
            case .success(let departments):
                allDepartments = departments
            case .failure(let error):
                print("Failed to load departments: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadDepartmentSnippets() {
        guard let dept = selectedDepartment else { return }
        isLoadingDepartment = true
        departmentSnippets = []
        
        GoogleDriveService.shared.downloadXMLFile(fileId: dept.fileId) { result in
            isLoadingDepartment = false
            switch result {
            case .success(let data):
                let parser = XMLParserHelper()
                departmentSnippets = parser.parse(data: data)
            case .failure(let error):
                print("Failed to load department snippets: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Actions
    
    private func uploadMasterXML() {
        isUploading = true
        uploadError = nil
        uploadSuccess = false
        
        GoogleSheetsService.shared.fetchDepartmentFileId(department: userDepartment) { result in
            switch result {
            case .success(let fileId):
                let masterFolders = StorageService.shared.getMasterSnippets()
                let xmlString = XMLParserHelper.export(folders: masterFolders)
                guard let xmlData = xmlString.data(using: .utf8) else {
                    isUploading = false
                    uploadError = "XML変換に失敗しました"
                    return
                }
                
                GoogleDriveService.shared.uploadXMLFile(fileId: fileId, xmlData: xmlData) { uploadResult in
                    isUploading = false
                    switch uploadResult {
                    case .success:
                        uploadSuccess = true
                    case .failure(let error):
                        uploadError = error.localizedDescription
                    }
                }
                
            case .failure(let error):
                isUploading = false
                uploadError = error.localizedDescription
            }
        }
    }
    
    private func exportXML() {
        let selectedFolders = folders.filter { selectedExportFolders.contains($0.id) }
        let xml = XMLParserHelper.export(folders: selectedFolders)
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.xml]
        savePanel.nameFieldStringValue = "snippets.xml"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? xml.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func importXML() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.xml]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                if let data = try? Data(contentsOf: url) {
                    let parser = XMLParserHelper()
                    let importedFolders = parser.parse(data: data)
                    
                    var currentFolders = StorageService.shared.getPersonalSnippets()
                    currentFolders.append(contentsOf: importedFolders)
                    StorageService.shared.savePersonalSnippets(currentFolders)
                    
                    loadData()
                }
            }
        }
    }
}
