//
//  SyncService.swift
//  SnipeeMac
//

import Foundation

class SyncService {
    static let shared = SyncService()
    
    private init() {}
    
    // MARK: - Sync Master Snippets
    
    func syncMasterSnippets(completion: @escaping (Result<SyncResult, Error>) -> Void) {
        // 1. Get logged in user email
        guard let email = GoogleAuthService.shared.userEmail else {
            completion(.failure(SyncError.notLoggedIn))
            return
        }
        
        // 2. Fetch member info from Sheets
        GoogleSheetsService.shared.fetchMemberInfo(email: email) { [weak self] result in
            switch result {
            case .success(let member):
                // Save member info
                self?.saveMemberInfo(member)
                
                // 3. Fetch department XML file ID
                self?.fetchAndDownloadXML(department: member.department, member: member, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchAndDownloadXML(department: String, member: MemberInfo, completion: @escaping (Result<SyncResult, Error>) -> Void) {
            GoogleSheetsService.shared.fetchDepartmentFileId(department: department) { [weak self] result in
            switch result {
            case .success(let fileId):
                // 4. Download XML from Drive
                self?.downloadAndParseXML(fileId: fileId, member: member, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func downloadAndParseXML(fileId: String, member: MemberInfo, completion: @escaping (Result<SyncResult, Error>) -> Void) {
            GoogleDriveService.shared.downloadXMLFile(fileId: fileId) { result in
                switch result {
                case .success(let data):
                    // 5. Parse XML
                    let parser = XMLParserHelper()
                    let folders = parser.parse(data: data)
                    
                    // 6. Save as master snippets
                    StorageService.shared.saveMasterSnippets(folders)
                    
                    // Update last sync date
                    var settings = StorageService.shared.getSettings()
                    settings.lastSyncDate = Date()
                    StorageService.shared.saveSettings(settings)
                    
                    let syncResult = SyncResult(
                        folderCount: folders.count,
                        snippetCount: folders.reduce(0) { $0 + $1.snippets.count },
                        syncDate: Date(),
                        memberName: member.name,
                        memberDepartment: member.department,
                        memberRole: member.role
                    )
                    
                    DispatchQueue.main.async {
                        completion(.success(syncResult))
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                }
            }
        }
    }
    
    private func saveMemberInfo(_ member: MemberInfo) {
        UserDefaults.standard.set(member.name, forKey: "userName")
        UserDefaults.standard.set(member.department, forKey: "userDepartment")
        UserDefaults.standard.set(member.role, forKey: "userRole")
    }
    
    // MARK: - Upload Master Snippets
    
    func uploadMasterSnippets(folders: [SnippetFolder], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let department = UserDefaults.standard.string(forKey: "userDepartment") else {
            completion(.failure(SyncError.notLoggedIn))
            return
        }

        GoogleSheetsService.shared.fetchDepartmentFileId(department: department) { result in
            switch result {
            case .success(let fileId):
                let xmlString = XMLParserHelper.export(folders: folders)
                guard let xmlData = xmlString.data(using: .utf8) else {
                    completion(.failure(SyncError.syncFailed))
                    return
                }
                
                GoogleDriveService.shared.uploadXMLFile(fileId: fileId, xmlData: xmlData) { uploadResult in
                    switch uploadResult {
                    case .success:
                        StorageService.shared.saveMasterSnippets(folders)
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Refresh Member Info Only
        
    func refreshMemberInfo() {
        guard let email = GoogleAuthService.shared.userEmail else { return }
        
        GoogleSheetsService.shared.fetchMemberInfo(email: email) { [weak self] result in
            if case .success(let member) = result {
                self?.saveMemberInfo(member)
            }
        }
    }
    
    func refreshMemberInfo(completion: @escaping () -> Void) {
        guard let email = GoogleAuthService.shared.userEmail else {
            completion()
            return
        }
        
        GoogleSheetsService.shared.fetchMemberInfo(email: email) { [weak self] result in
            if case .success(let member) = result {
                self?.saveMemberInfo(member)
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    
    // MARK: - Get Cached Member Info
    
    func getCachedMemberInfo() -> (name: String?, department: String?, role: String?) {
        return (
            name: UserDefaults.standard.string(forKey: "userName"),
            department: UserDefaults.standard.string(forKey: "userDepartment"),
            role: UserDefaults.standard.string(forKey: "userRole")
        )
    }
}

// MARK: - Models
struct SyncResult {
    let folderCount: Int
    let snippetCount: Int
    let syncDate: Date
    let memberName: String?
    let memberDepartment: String?
    let memberRole: String?
}

// MARK: - Errors

enum SyncError: Error, LocalizedError {
    case notLoggedIn
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .notLoggedIn: return "ログインしてください"
        case .syncFailed: return "同期に失敗しました"
        }
    }
}
