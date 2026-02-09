//
//  PersonalSyncService.swift
//  SnipeeIOS
//

import Foundation

class PersonalSyncService {
    static let shared = PersonalSyncService()
    
    private let driveService = GoogleDriveService.shared
    private let storageService = StorageService.shared
    
    private let syncFolderName = "Snipee_データ"
    private let syncFileName = "personal_snippets.json"
    
    private var syncFolderId: String?
    private var syncFileId: String?
    
    private let deviceId: String
    
    private init() {
        if let savedDeviceId = UserDefaults.standard.string(forKey: "sync_device_id") {
            deviceId = savedDeviceId
        } else {
            deviceId = "ios-\(UUID().uuidString.prefix(8))"
            UserDefaults.standard.set(deviceId, forKey: "sync_device_id")
        }
    }
    
    // MARK: - Public Methods
    
    func syncPersonalSnippets(completion: @escaping (Result<Void, Error>) -> Void) {
        print("📱 [PersonalSync] iOS版 - ダウンロードのみモード")
        
        ensureSyncFile { [weak self] result in
            switch result {
            case .success(let fileId):
                self?.syncFileId = fileId
                self?.downloadAndApply(completion: completion)
            case .failure(let error):
                print("❌ [PersonalSync] ensureSyncFile失敗: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    private func downloadAndApply(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let fileId = syncFileId else {
            completion(.failure(PersonalSyncError.noSyncFile))
            return
        }
        
        downloadSyncData(fileId: fileId) { [weak self] result in
            switch result {
            case .success(let remoteData):
                if let remoteData = remoteData {
                    print("📥 [PersonalSync] ダウンロード成功: \(remoteData.folders.count) フォルダ")
                    self?.storageService.savePersonalSnippetsFromCloud(remoteData.folders)
                } else {
                    print("📥 [PersonalSync] リモートデータなし")
                }
                completion(.success(()))
            case .failure(let error):
                print("❌ [PersonalSync] ダウンロード失敗: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func downloadPersonalData(completion: @escaping (Result<SyncData?, Error>) -> Void) {
        ensureSyncFile { [weak self] result in
            switch result {
            case .success(let fileId):
                self?.downloadSyncData(fileId: fileId, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func uploadPersonalDataNow(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let fileId = syncFileId else {
            syncPersonalSnippets(completion: completion)
            return
        }
        
        let localFolders = storageService.getPersonalSnippets()
        let syncData = SyncData(
            version: 1,
            lastModified: ISO8601DateFormatter().string(from: Date()),
            deviceId: deviceId,
            folders: localFolders,
            deleted: getLocalDeletedItems()
        )
        
        uploadSyncData(fileId: fileId, data: syncData, completion: completion)
    }
    
    // MARK: - Private Methods
    
    private func ensureSyncFile(completion: @escaping (Result<String, Error>) -> Void) {
        if let fileId = syncFileId {
            completion(.success(fileId))
            return
        }
        
        driveService.findFile(name: syncFolderName, parentId: nil) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let folder):
                if let folder = folder {
                    print("📱 [PersonalSync] フォルダ発見: \(folder.id)")
                    self.syncFolderId = folder.id
                    self.ensureFileInFolder(folderId: folder.id, completion: completion)
                } else {
                    print("📱 [PersonalSync] フォルダなし、作成開始")
                    self.createSyncFolder(completion: completion)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func createSyncFolder(completion: @escaping (Result<String, Error>) -> Void) {
        driveService.findOrCreateFolder(name: syncFolderName) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let folderId):
                print("📱 [PersonalSync] フォルダ作成成功: \(folderId)")
                self.syncFolderId = folderId
                self.ensureFileInFolder(folderId: folderId, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func ensureFileInFolder(folderId: String, completion: @escaping (Result<String, Error>) -> Void) {
        driveService.findFile(name: syncFileName, parentId: folderId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let file):
                if let file = file {
                    print("📱 [PersonalSync] ファイル発見: \(file.id)")
                    self.syncFileId = file.id
                    completion(.success(file.id))
                } else {
                    print("📱 [PersonalSync] ファイルなし、作成開始")
                    self.createSyncFile(folderId: folderId, completion: completion)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func createSyncFile(folderId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let localFolders = storageService.getPersonalSnippets()
        let syncData = SyncData(
            version: 1,
            lastModified: ISO8601DateFormatter().string(from: Date()),
            deviceId: deviceId,
            folders: localFolders,
            deleted: []
        )
        
        guard let jsonData = try? JSONEncoder().encode(syncData) else {
            completion(.failure(PersonalSyncError.encodingFailed))
            return
        }
        
        driveService.createFile(
            name: syncFileName,
            content: jsonData,
            parentId: folderId,
            mimeType: "application/json"
        ) { [weak self] result in
            switch result {
            case .success(let file):
                print("✅ [PersonalSync] ファイル作成成功: \(file.id)")
                self?.syncFileId = file.id
                completion(.success(file.id))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func performSync(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let fileId = syncFileId else {
            completion(.failure(PersonalSyncError.noSyncFile))
            return
        }
        
        downloadSyncData(fileId: fileId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let remoteData):
                let localFolders = self.storageService.getPersonalSnippets()
                let localData = SyncData(
                    version: 1,
                    lastModified: ISO8601DateFormatter().string(from: Date()),
                    deviceId: self.deviceId,
                    folders: localFolders,
                    deleted: self.getLocalDeletedItems()
                )
                
                let mergedData: SyncData
                if let remoteData = remoteData {
                    mergedData = self.mergeData(local: localData, remote: remoteData)
                } else {
                    mergedData = localData
                }
                
                self.storageService.savePersonalSnippets(mergedData.folders)
                self.saveLocalDeletedItems(mergedData.deleted)
                
                self.uploadSyncData(fileId: fileId, data: mergedData, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func downloadSyncData(fileId: String, completion: @escaping (Result<SyncData?, Error>) -> Void) {
        driveService.downloadJSONFile(fileId: fileId) { result in
            switch result {
            case .success(let data):
                do {
                    let syncData = try JSONDecoder().decode(SyncData.self, from: data)
                    completion(.success(syncData))
                } catch {
                    print("❌ [PersonalSync] デコードエラー: \(error)")
                    completion(.success(nil))
                }
            case .failure(let error):
                if case DriveError.fileNotFound = error {
                    completion(.success(nil))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func uploadSyncData(fileId: String, data: SyncData, completion: @escaping (Result<Void, Error>) -> Void) {
        var uploadData = data
        uploadData.lastModified = ISO8601DateFormatter().string(from: Date())
        uploadData.deviceId = deviceId
        
        guard let jsonData = try? JSONEncoder().encode(uploadData) else {
            completion(.failure(PersonalSyncError.encodingFailed))
            return
        }
        
        driveService.uploadJSONFile(fileId: fileId, jsonData: jsonData) { result in
            switch result {
            case .success:
                print("✅ [PersonalSync] アップロード成功")
                UserDefaults.standard.set(Date(), forKey: "lastPersonalSyncDate")
                completion(.success(()))
            case .failure(let error):
                print("❌ [PersonalSync] アップロード失敗: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Merge Logic
    
    func mergeData(local: SyncData, remote: SyncData) -> SyncData {
        var mergedFolders: [SnippetFolder] = []
        var mergedDeleted: [DeletedItem] = []
        
        let allDeleted = Set((local.deleted + remote.deleted).map { $0.id })
        mergedDeleted = (local.deleted + remote.deleted).reduce(into: [DeletedItem]()) { result, item in
            if !result.contains(where: { $0.id == item.id }) {
                result.append(item)
            }
        }
        
        let thirtyDaysAgo = ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
        mergedDeleted = mergedDeleted.filter { $0.deletedAt > thirtyDaysAgo }
        
        let localFolderDict = Dictionary(uniqueKeysWithValues: local.folders.map { ($0.id, $0) })
        let remoteFolderDict = Dictionary(uniqueKeysWithValues: remote.folders.map { ($0.id, $0) })
        let allFolderIds = Set(localFolderDict.keys).union(Set(remoteFolderDict.keys))
        
        for folderId in allFolderIds {
            if allDeleted.contains(folderId) { continue }
            
            let localFolder = localFolderDict[folderId]
            let remoteFolder = remoteFolderDict[folderId]
            
            if let local = localFolder, let remote = remoteFolder {
                let mergedFolder = mergeFolders(local: local, remote: remote, allDeleted: allDeleted)
                mergedFolders.append(mergedFolder)
            } else if let local = localFolder {
                let filteredSnippets = local.snippets.filter { !allDeleted.contains($0.id) }
                var folder = local
                folder.snippets = filteredSnippets
                mergedFolders.append(folder)
            } else if let remote = remoteFolder {
                let filteredSnippets = remote.snippets.filter { !allDeleted.contains($0.id) }
                var folder = remote
                folder.snippets = filteredSnippets
                mergedFolders.append(folder)
            }
        }
        
        mergedFolders.sort { $0.order < $1.order }
        
        return SyncData(
            version: 1,
            lastModified: ISO8601DateFormatter().string(from: Date()),
            deviceId: local.deviceId,
            folders: mergedFolders,
            deleted: mergedDeleted
        )
    }
    
    private func mergeFolders(local: SnippetFolder, remote: SnippetFolder, allDeleted: Set<String>) -> SnippetFolder {
        let useLocalMeta = (local.updatedAt ?? "") >= (remote.updatedAt ?? "")
        
        var mergedSnippets: [Snippet] = []
        let localSnippetDict = Dictionary(uniqueKeysWithValues: local.snippets.map { ($0.id, $0) })
        let remoteSnippetDict = Dictionary(uniqueKeysWithValues: remote.snippets.map { ($0.id, $0) })
        let allSnippetIds = Set(localSnippetDict.keys).union(Set(remoteSnippetDict.keys))
        
        for snippetId in allSnippetIds {
            if allDeleted.contains(snippetId) { continue }
            
            let localSnippet = localSnippetDict[snippetId]
            let remoteSnippet = remoteSnippetDict[snippetId]
            
            if let local = localSnippet, let remote = remoteSnippet {
                mergedSnippets.append((local.updatedAt ?? "") >= (remote.updatedAt ?? "") ? local : remote)
            } else if let local = localSnippet {
                mergedSnippets.append(local)
            } else if let remote = remoteSnippet {
                mergedSnippets.append(remote)
            }
        }
        
        mergedSnippets.sort { $0.order < $1.order }
        
        return SnippetFolder(
            id: local.id,
            name: useLocalMeta ? local.name : remote.name,
            snippets: mergedSnippets,
            order: useLocalMeta ? local.order : remote.order,
            updatedAt: useLocalMeta ? local.updatedAt : remote.updatedAt
        )
    }
    
    // MARK: - Deleted Items Management
    
    private let deletedItemsKey = "sync_deleted_items"
    
    private func getLocalDeletedItems() -> [DeletedItem] {
        guard let data = UserDefaults.standard.data(forKey: deletedItemsKey),
              let items = try? JSONDecoder().decode([DeletedItem].self, from: data) else {
            return []
        }
        return items
    }
    
    private func saveLocalDeletedItems(_ items: [DeletedItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: deletedItemsKey)
    }
    
    func markAsDeleted(id: String) {
        var items = getLocalDeletedItems()
        if !items.contains(where: { $0.id == id }) {
            items.append(DeletedItem(id: id, deletedAt: ISO8601DateFormatter().string(from: Date())))
            saveLocalDeletedItems(items)
        }
    }
}

// MARK: - Sync Models

struct SyncData: Codable {
    var version: Int
    var lastModified: String
    var deviceId: String
    var folders: [SnippetFolder]
    var deleted: [DeletedItem]
}

struct DeletedItem: Codable {
    let id: String
    let deletedAt: String
}

// MARK: - Sync Errors

enum PersonalSyncError: Error, LocalizedError {
    case noSyncFile
    case encodingFailed
    case decodingFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noSyncFile: return "同期ファイルがありません"
        case .encodingFailed: return "データのエンコードに失敗しました"
        case .decodingFailed: return "データのデコードに失敗しました"
        case .networkError: return "ネットワークエラーが発生しました"
        }
    }
}
