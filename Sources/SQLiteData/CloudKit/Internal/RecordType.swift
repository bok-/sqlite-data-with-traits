#if canImport(CustomDump)
  import CustomDump
#endif

@Table("sqlitedata_icloud_recordTypes")
package struct RecordType: Hashable {
  @Column(primaryKey: true)
  package let tableName: String
  package let schema: String
  @Column(as: Set<TableInfo>.JSONRepresentation.self)
  package let tableInfo: Set<TableInfo>
}

extension RecordType {
  package var customDumpMirror: Mirror {
    Mirror(
      self,
      children: [
        ("tableName", tableName as Any),
        ("schema", schema),
        ("tableInfo", tableInfo.sorted(by: { $0.name < $1.name })),
      ],
      displayStyle: .struct
    )
  }
}

#if canImport(CustomDump)
  extension RecordType: CustomDumpReflectable {}
#endif
