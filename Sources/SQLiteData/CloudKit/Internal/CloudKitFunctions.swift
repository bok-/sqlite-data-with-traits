#if canImport(CloudKit)
  import CloudKit
#if canImport(Dependencies)
import Dependencies
#endif
  import Foundation

  @DatabaseFunction("sqlitedata_icloud_currentTime")
  func currentTime() -> Int64 {
      #if canImport(Dependencies)
    @Dependency(\.currentTime.now) var now
      #else
      let now = CurrentTimeGenerator.liveValue.now
      #endif
    return now
  }

  @DatabaseFunction(
    "sqlitedata_icloud_hasPermission",
    as: ((CKShare?.SystemFieldsRepresentation) -> Bool).self,
    isDeterministic: true
  )
  func hasPermission(_ share: CKShare?) -> Bool {
    guard let share else { return true }
    return share.publicPermission == .readWrite
      || share.currentUserParticipant?.permission == .readWrite
  }

  @DatabaseFunction("sqlitedata_icloud_syncEngineIsSynchronizingChanges")
  func syncEngineIsSynchronizingChanges() -> Bool {
    _isSynchronizingChanges
  }
#endif
