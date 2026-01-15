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
        KeychainHelper.shared.save(member.name, for: "userName")
        KeychainHelper.shared.save(member.department, for: "userDepartment")
        KeychainHelper.shared.save(member.role, for: "userRole")
    }
    
    // MARK: - Get Cached Member Info
    
    func getCachedMemberInfo() -> (name: String?, department: String?, role: String?) {
        return (
            name: KeychainHelper.shared.get("userName"),
            department: KeychainHelper.shared.get("userDepartment"),
            role: KeychainHelper.shared.get("userRole")
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
