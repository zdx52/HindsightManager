import Foundation
import Security

// MARK: - Keychain 助手 — 安全存储 API Key

enum KeychainHelper {
    static let service = "com.zdx52.HindsightManager"
    
    // MARK: - 兼容旧接口（固定 service）
    
    /// 保存 API Key 到 Keychain
    @discardableResult
    static func save(key: String, value: String) -> Bool {
        save(service: service, account: key, value: value)
    }
    
    /// 从 Keychain 读取 API Key
    static func read(key: String) -> String? {
        read(service: service, account: key)
    }
    
    /// 从 Keychain 删除 API Key
    @discardableResult
    static func delete(key: String) -> Bool {
        delete(service: service, account: key)
    }
    
    // MARK: - 通用接口（自定义 service + account）
    
    /// 保存值到 Keychain
    @discardableResult
    static func save(service: String, account: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // 先删除旧值
        delete(service: service, account: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 从 Keychain 读取值
    static func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// 从 Keychain 删除值
    @discardableResult
    static func delete(service: String, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
