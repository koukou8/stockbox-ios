import Foundation
import SwiftData

// MARK: - バックアップの JSON スキーマ

/// エクスポート / インポートで受け渡す JSON のルート。
///
/// Category / Item / PurchaseLog を**フラットな 3 配列 + 外部キー**で持つ。
/// ネストではなくフラットにしているのは、
/// (a) 正典のデータモデル（3 テーブル）とそのまま対応させるため、
/// (b) 万一カテゴリの無いアイテムがあっても取りこぼさないため。
///
/// `format` / `version` を必ず含め、将来スキーマを変えたときに
/// 読み込み側が判定できるようにしておく。
struct LOBackup: Codable {
    /// このファイルが LastOne のバックアップであることの識別子。
    static let formatIdentifier = "jp.co.gimic.lastone.backup"
    /// 現行のスキーマバージョン。
    static let currentVersion = 1

    var format: String = LOBackup.formatIdentifier
    var version: Int = LOBackup.currentVersion
    var exportedAt: Date
    var categories: [LOBackupCategory]
    var items: [LOBackupItem]
    var purchaseLogs: [LOBackupPurchaseLog]
}

struct LOBackupCategory: Codable {
    var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date
}

struct LOBackupItem: Codable {
    var id: UUID
    var categoryID: UUID?
    var name: String
    /// `TrackingMode` の raw value。将来 case が増えてもそのまま往復できるよう String で持つ。
    var trackingMode: String
    var stockCount: Int?
    var threshold: Int
    /// `StockStatus` の raw value。
    var status: String
    var lastPurchasedAt: Date?
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
}

struct LOBackupPurchaseLog: Codable {
    var id: UUID
    var itemID: UUID?
    var purchasedAt: Date
    var quantity: Int
}

// MARK: - エラー

enum DataTransferError: LocalizedError {
    /// LastOne のバックアップとして解釈できない。
    case unsupportedFormat
    /// このアプリより新しいスキーマ。
    case unsupportedVersion(Int)
    /// 読み込み / 書き出しの失敗。
    case io(any Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat: return "The file is not a LastOne backup."
        case .unsupportedVersion(let version): return "Unsupported backup version \(version)."
        case .io(let error): return error.localizedDescription
        }
    }
}

/// インポート結果のサマリ（完了ダイアログに出す件数）。
struct DataImportSummary: Equatable {
    var categories: Int
    var items: Int
    var purchaseLogs: Int
}

// MARK: - サービス

/// データのエクスポート / インポート（JSON）。
///
/// - エクスポート: 全 Category / Item / PurchaseLog を JSON にして一時ファイルへ書き出し、
///   共有シートで渡せる URL を返す。
/// - インポート: 「全置換」。既存の 3 モデルを全削除してからファイルの内容を作り直す。
///   壊れた JSON や別アプリのファイルではクラッシュせず `DataTransferError` を投げる。
@MainActor
enum DataTransferService {

    // MARK: - エンコーダ / デコーダ

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - エクスポート

    /// 現在の全データを JSON にシリアライズする。
    static func makeBackup(context: ModelContext, now: Date = Date()) throws -> Data {
        do {
            let categories = try context.fetch(
                FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder, order: .forward)])
            )
            let items = try context.fetch(
                FetchDescriptor<Item>(sortBy: [SortDescriptor(\.sortOrder, order: .forward)])
            )
            let logs = try context.fetch(
                FetchDescriptor<PurchaseLog>(sortBy: [SortDescriptor(\.purchasedAt, order: .forward)])
            )

            let backup = LOBackup(
                exportedAt: now,
                categories: categories.map {
                    LOBackupCategory(
                        id: $0.id,
                        name: $0.name,
                        sortOrder: $0.sortOrder,
                        createdAt: $0.createdAt
                    )
                },
                items: items.map {
                    LOBackupItem(
                        id: $0.id,
                        categoryID: $0.category?.id,
                        name: $0.name,
                        trackingMode: $0.trackingModeRaw,
                        stockCount: $0.stockCount,
                        threshold: $0.threshold,
                        status: $0.statusRaw,
                        lastPurchasedAt: $0.lastPurchasedAt,
                        sortOrder: $0.sortOrder,
                        createdAt: $0.createdAt,
                        updatedAt: $0.updatedAt
                    )
                },
                purchaseLogs: logs.map {
                    LOBackupPurchaseLog(
                        id: $0.id,
                        itemID: $0.item?.id,
                        purchasedAt: $0.purchasedAt,
                        quantity: $0.quantity
                    )
                }
            )
            return try encoder.encode(backup)
        } catch {
            throw DataTransferError.io(error)
        }
    }

    /// 共有シートに渡すための一時ファイルを書き出し、その URL を返す。
    static func writeBackupFile(context: ModelContext, now: Date = Date()) throws -> URL {
        let data = try makeBackup(context: context, now: now)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(backupFileName(now), conformingTo: .json)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw DataTransferError.io(error)
        }
        return url
    }

    /// バックアップのファイル名。UI 文言ではなくファイル名なのでローカライズしない。
    static func backupFileName(_ now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return "LastOne-Backup-\(formatter.string(from: now))"
    }

    // MARK: - インポート

    /// JSON を検証して読み込む（この時点ではまだ DB を触らない）。
    static func decodeBackup(from data: Data) throws -> LOBackup {
        let backup: LOBackup
        do {
            backup = try decoder.decode(LOBackup.self, from: data)
        } catch {
            throw DataTransferError.unsupportedFormat
        }
        guard backup.format == LOBackup.formatIdentifier else {
            throw DataTransferError.unsupportedFormat
        }
        guard backup.version <= LOBackup.currentVersion else {
            throw DataTransferError.unsupportedVersion(backup.version)
        }
        return backup
    }

    /// セキュリティスコープ付き URL（ファイル選択の結果）を読み込む。
    static func loadBackup(from url: URL) throws -> LOBackup {
        let needsScope = url.startAccessingSecurityScopedResource()
        defer { if needsScope { url.stopAccessingSecurityScopedResource() } }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DataTransferError.io(error)
        }
        return try decodeBackup(from: data)
    }

    /// バックアップの内容で既存データを**全置換**する。
    @discardableResult
    static func replaceAll(with backup: LOBackup, context: ModelContext) throws -> DataImportSummary {
        do {
            try deleteAll(in: context)

            var categoriesByID: [UUID: Category] = [:]
            for source in backup.categories.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                let category = Category(
                    id: source.id,
                    name: source.name,
                    sortOrder: source.sortOrder,
                    createdAt: source.createdAt
                )
                context.insert(category)
                categoriesByID[source.id] = category
            }

            var itemsByID: [UUID: Item] = [:]
            for source in backup.items {
                let item = Item(
                    id: source.id,
                    name: source.name,
                    category: source.categoryID.flatMap { categoriesByID[$0] },
                    trackingMode: TrackingMode(rawValue: source.trackingMode) ?? .binary,
                    stockCount: source.stockCount,
                    threshold: source.threshold,
                    status: StockStatus(rawValue: source.status) ?? .inStock,
                    lastPurchasedAt: source.lastPurchasedAt,
                    sortOrder: source.sortOrder,
                    createdAt: source.createdAt,
                    updatedAt: source.updatedAt
                )
                // 未知の raw value でも欠落させずそのまま戻す（enum は将来拡張予定のため）。
                item.trackingModeRaw = source.trackingMode
                item.statusRaw = source.status
                context.insert(item)
                itemsByID[source.id] = item
            }

            for source in backup.purchaseLogs {
                let log = PurchaseLog(
                    id: source.id,
                    purchasedAt: source.purchasedAt,
                    quantity: source.quantity,
                    item: source.itemID.flatMap { itemsByID[$0] }
                )
                context.insert(log)
            }

            try context.save()

            return DataImportSummary(
                categories: backup.categories.count,
                items: backup.items.count,
                purchaseLogs: backup.purchaseLogs.count
            )
        } catch let error as DataTransferError {
            throw error
        } catch {
            throw DataTransferError.io(error)
        }
    }

    /// 3 モデルを全削除する。カテゴリの cascade だけに頼らず、
    /// カテゴリの無いアイテム / アイテムの無い履歴も確実に消す。
    private static func deleteAll(in context: ModelContext) throws {
        for log in try context.fetch(FetchDescriptor<PurchaseLog>()) {
            context.delete(log)
        }
        for item in try context.fetch(FetchDescriptor<Item>()) {
            context.delete(item)
        }
        for category in try context.fetch(FetchDescriptor<Category>()) {
            context.delete(category)
        }
        try context.save()
    }
}
