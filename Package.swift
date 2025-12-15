// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "sqlite-data",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v7),
  ],
  products: [
    .library(
      name: "SQLiteData",
      targets: ["SQLiteData"]
    ),
    .library(
      name: "SQLiteDataTestSupport",
      targets: ["SQLiteDataTestSupport"]
    ),
  ],
  traits: [
    .trait(
      name: "SQLiteDataCustomDump",
      description: "Introduce SQLiteData conformances to the swift-tagged package."
    ),
    .trait(
      name: "SQLiteDataDependencies",
      description: "Introduce SQLiteData conformances to the swift-tagged package."
    ),
    .trait(
      name: "SQLiteDataIssueReporting",
      description: "Introduce SQLiteData conformances to the swift-tagged package."
    ),
    .trait(
      name: "SQLiteDataPerception",
      description: "Introduce SQLiteData conformances to the swift-tagged package.",
      enabledTraits: ["SQLiteDataIssueReporting"]
    ),
    .trait(
      name: "SQLiteDataSnapshotTesting",
      description: "Introduce SQLiteData conformances to the swift-tagged package.",
    ),
    .trait(
      name: "SQLiteDataTagged",
      description: "Introduce SQLiteData conformances to the swift-tagged package."
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
    .package(url: "https://github.com/groue/GRDB.swift", from: "7.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.0"),
    .package(url: "https://github.com/pointfreeco/swift-perception", "1.4.1"..<"3.0.0"),
    .package(
      url: "https://github.com/bok-/swift-sharing-with-traits",
      from: "2.7.4+traits",
      traits: [
        .trait(name: "SharingCustomDump", condition: .when(traits: ["SQLiteDataCustomDump"])),
        .trait(name: "SharingDependencies", condition: .when(traits: ["SQLiteDataDependencies"])),
        .trait(
          name: "SharingIssueReporting", condition: .when(traits: ["SQLiteDataIssueReporting"])),
        .trait(name: "SharingPerception", condition: .when(traits: ["SQLiteDataPerception"])),
      ]
    ),
    .package(
      url: "https://github.com/bok-/swift-snapshot-testing-with-traits",
      from: "1.18.7+traits",
      traits: [
        .trait(
          name: "SnapshotTestingCustomDump", condition: .when(traits: ["SQLiteDataCustomDump"]))
      ]
    ),
    .package(
      url: "https://github.com/bok-/swift-structured-queries-with-traits",
      from: "0.24.0",
      traits: [
        .trait(name: "StructuredQueriesTagged", condition: .when(traits: ["SQLiteDataTagged"])),
        .trait(
          name: "StructuredQueriesCustomDump", condition: .when(traits: ["SQLiteDataCustomDump"])),
        .trait(
          name: "StructuredQueriesDependencies",
          condition: .when(traits: ["SQLiteDataDependencies"])),
        .trait(
          name: "StructuredQueriesSnapshotTesting",
          condition: .when(traits: ["SQLiteDataSnapshotTesting"])),
        .trait(
          name: "StructuredQueriesIssueReporting",
          condition: .when(traits: ["SQLiteDataIssueReporting"])),
      ]
    ),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.5.0"),
  ],
  targets: [
    .target(
      name: "SQLiteData",
      dependencies: [
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(
          name: "Dependencies", package: "swift-dependencies",
          condition: .when(traits: ["SQLiteDataDependencies"])),
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(
          name: "IssueReporting", package: "xctest-dynamic-overlay",
          condition: .when(traits: ["SQLiteDataIssueReporting"])),
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(
          name: "PerceptionCore", package: "swift-perception",
          condition: .when(traits: ["SQLiteDataPerception"])),
        .product(name: "Sharing", package: "swift-sharing-with-traits"),
        .product(name: "StructuredQueriesSQLite", package: "swift-structured-queries-with-traits"),
        .product(
          name: "Tagged", package: "swift-tagged", condition: .when(traits: ["SQLiteDataTagged"])),
      ]
    ),
    .target(
      name: "SQLiteDataTestSupport",
      dependencies: [
        "SQLiteData",
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(
          name: "CustomDump", package: "swift-custom-dump",
          condition: .when(traits: ["SQLiteDataCustomDump"])),
        .product(
          name: "InlineSnapshotTesting", package: "swift-snapshot-testing-with-traits",
          condition: .when(traits: ["SQLiteDataSnapshotTesting"])),
        .product(
          name: "StructuredQueriesTestSupport", package: "swift-structured-queries-with-traits",
          condition: .when(traits: ["SQLiteDataSnapshotTesting"])),
      ]
    ),
    .testTarget(
      name: "SQLiteDataTests",
      dependencies: [
        "SQLiteData",
        "SQLiteDataTestSupport",
        .product(
          name: "DependenciesTestSupport", package: "swift-dependencies",
          condition: .when(traits: ["SQLiteDataDependencies"])),
        .product(
          name: "InlineSnapshotTesting", package: "swift-snapshot-testing-with-traits",
          condition: .when(traits: ["SQLiteDataSnapshotTesting"])),
        .product(
          name: "SnapshotTestingCustomDump", package: "swift-snapshot-testing-with-traits",
          condition: .when(traits: ["SQLiteDataCustomDump"])),
        .product(name: "StructuredQueries", package: "swift-structured-queries-with-traits"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("MemberImportVisibility")
  // .unsafeFlags([
  //   "-Xfrontend",
  //   "-warn-long-function-bodies=50",
  //   "-Xfrontend",
  //   "-warn-long-expression-type-checking=50",
  // ])
]

for index in package.targets.indices {
  package.targets[index].swiftSettings = swiftSettings
}

#if !os(Windows)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
