import Foundation

let fileManager = FileManager.default
let projectPath = "/Users/mario.garza/VsCode Projects/Softwaretakt/softwaretakt-backup-20250627-101831/softwaretakt-ios-app"

let filesToDelete = [
    "\(projectPath)/Sources/Softwaretakt/App/SoftwaretaktApp.swift.backup.swift",
    "\(projectPath)/TestMain.swift"
]

for file in filesToDelete {
    if fileManager.fileExists(atPath: file) {
        do {
            try fileManager.removeItem(atPath: file)
            print("✅ Deleted: \(file)")
        } catch {
            print("❌ Failed to delete \(file): \(error)")
        }
    } else {
        print("ℹ️ File not found: \(file)")
    }
}
