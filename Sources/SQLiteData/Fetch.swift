import Sharing

#if canImport(Combine)
  import Combine
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

/// A property that can query for data in a SQLite database.
///
/// It takes a ``FetchKeyRequest`` that describes how to fetch data from a database:
///
/// ```swift
/// @Fetch(Items()) var items = Items.Value()
/// ```
///
/// See <doc:Fetching> for more information.
@dynamicMemberLookup
@propertyWrapper
#if !canImport(PerceptionCore)
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
#endif
public struct Fetch<Value: Sendable>: Sendable {
    enum State {
        case sharedReader(SharedReader<Value>)
        case sharedReaderFactory((DatabaseReader?) -> SharedReader<Value>)
    }

    private let state: _ManagedCriticalState<State>

    /// The underlying shared reader powering the property wrapper.
  ///
  /// Shared readers come from the [Sharing](https://github.com/pointfreeco/swift-sharing) package,
  /// a general solution to observing and persisting changes to external data sources.
    public var sharedReader: SharedReader<Value> {
        state.withCriticalRegion { state in
            switch state {
            case let .sharedReader(sharedReader):
                return sharedReader
            case let .sharedReaderFactory(factory):
                let sharedReader = factory(nil)             // Rely solely on @Dependeny and the @TaskLocal
                state = .sharedReader(sharedReader)
                return sharedReader
            }
        }
    }
  /// Data associated with the underlying query.
  public var wrappedValue: Value {
    sharedReader.wrappedValue
  }

#if canImport(SwiftUI)
@Environment(\.defaultDatabase) private var defaultDatabase
#endif

/// Returns the provided database, or falls through to the globally available database using the following:
///
/// 1. @Environment(\.defaultDatabase), if set.
/// 2. @Dependency(\.defaultDatabase), if compiled with the `SQLiteDataDependencies` trait
/// 3. The `Database.defaultDatabase` @TaskLocal.
///
private func databaseOrDefault(_ reader: (any DatabaseReader)?) -> (any DatabaseReader)? {
    #if canImport(SwiftUI)
    reader ?? defaultDatabase
    #else
    reader
    #endif
}

  /// Returns this property wrapper.
  ///
  /// Useful if you want to access various property wrapper state, like ``loadError``,
  /// ``isLoading``, and ``publisher``.
  public var projectedValue: Self {
    get { self }
    nonmutating set { sharedReader.projectedValue = newValue.sharedReader.projectedValue }
  }

  /// Returns a ``sharedReader`` for the given key path.
  ///
  /// You do not invoke this subscript directly. Instead, Swift calls it for you when chaining into
  /// a member of the underlying data type.
  public subscript<Member>(dynamicMember keyPath: KeyPath<Value, Member>) -> SharedReader<Member> {
    sharedReader[dynamicMember: keyPath]
  }

  /// An error encountered during the most recent attempt to load data.
  public var loadError: (any Error)? {
    sharedReader.loadError
  }

  /// Whether or not data is loading from the database.
  public var isLoading: Bool {
    sharedReader.isLoading
  }

  /// Reloads data from the database.
  public func load() async throws {
    try await sharedReader.load()
  }

  #if canImport(Combine)
    /// A publisher that emits events when the database observes changes to the query.
    public var publisher: some Publisher<Value, Never> {
      sharedReader.publisher
    }
  #endif

  /// Initializes this property with an initial value.
  ///
  /// - Parameter wrappedValue: A default value to associate with this property.
  @_disfavoredOverload
  public init(wrappedValue: sending Value) {
      state = .init(.sharedReader(SharedReader(value: wrappedValue)))
  }

  /// Initializes this property with a request associated with the wrapped value.
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to associate with this property.
  ///   - request: A request describing the data to fetch.
  ///   - database: The database to read from. A value of `nil` will use the default database
  ///     (`@Dependency(\.defaultDatabase)`).
  public init(
    wrappedValue: Value,
    _ request: some FetchKeyRequest<Value>,
    database: (any DatabaseReader)? = nil
  ) {
      state = .init(.sharedReaderFactory {
          SharedReader(wrappedValue: wrappedValue, .fetch(request, database: database ?? $0))
      })
  }

  /// Replaces the wrapped value with data from the given request.
  ///
  /// - Parameters:
  ///   - request: A request describing the data to fetch.
  ///   - database: The database to read from. A value of `nil` will use the default database
  ///     (`@Dependency(\.defaultDatabase)`).
  public func load(
    _ request: some FetchKeyRequest<Value>,
    database: (any DatabaseReader)? = nil
  ) async throws {
    try await sharedReader.load(.fetch(request, database: databaseOrDefault(database)))
  }
}

#if !canImport(PerceptionCore)
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
#endif
extension Fetch {
  /// Initializes this property with a request associated with the wrapped value.
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to associate with this property.
  ///   - request: A request describing the data to fetch.
  ///   - database: The database to read from. A value of `nil` will use the default database
  ///     (`@Dependency(\.defaultDatabase)`).
  ///   - scheduler: The scheduler to observe from. By default, database observation is performed
  ///     asynchronously on the main queue.
  public init(
    wrappedValue: Value,
    _ request: some FetchKeyRequest<Value>,
    database: (any DatabaseReader)? = nil,
    scheduler: some ValueObservationScheduler & Hashable
  ) {
      state = .init(.sharedReaderFactory {
          SharedReader(
            wrappedValue: wrappedValue,
            .fetch(request, database: database ?? $0, scheduler: scheduler)
          )
      })
  }

  /// Replaces the wrapped value with data from the given request.
  ///
  /// - Parameters:
  ///   - request: A request describing the data to fetch.
  ///   - database: The database to read from. A value of `nil` will use the default database
  ///     (`@Dependency(\.defaultDatabase)`).
  ///   - scheduler: The scheduler to observe from. By default, database observation is performed
  ///     asynchronously on the main queue.
  public func load(
    _ request: some FetchKeyRequest<Value>,
    database: (any DatabaseReader)? = nil,
    scheduler: some ValueObservationScheduler & Hashable
  ) async throws {
    try await sharedReader.load(.fetch(request, database: databaseOrDefault(database), scheduler: scheduler))
  }
}

#if !canImport(PerceptionCore)
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
#endif
extension Fetch: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(reflecting: wrappedValue)
  }
}

#if !canImport(PerceptionCore)
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
#endif
extension Fetch: Equatable where Value: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.sharedReader == rhs.sharedReader
  }
}

#if canImport(SwiftUI)
#if !canImport(PerceptionCore)
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
#endif
  extension Fetch: DynamicProperty {
    public func update() {
        state.withCriticalRegion { state in
            if case .sharedReaderFactory(let factory) = state {
                state = .sharedReader(factory(defaultDatabase))
            }
        }
      sharedReader.update()
    }

    /// Initializes this property with a request associated with the wrapped value.
    ///
    /// - Parameters:
    ///   - wrappedValue: A default value to associate with this property.
    ///   - request: A request describing the data to fetch.
    ///   - database: The database to read from. A value of `nil` will use the default database
    ///     (`@Dependency(\.defaultDatabase)`).
    ///   - animation: The animation to use for user interface changes that result from changes to
    ///     the fetched results.
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    public init(
      wrappedValue: Value,
      _ request: some FetchKeyRequest<Value>,
      database: (any DatabaseReader)? = nil,
      animation: Animation
    ) {
        state = .init(.sharedReaderFactory {
            SharedReader(
                wrappedValue: wrappedValue,
                .fetch(request, database: database ?? $0, animation: animation)
            )
        })
    }

    /// Replaces the wrapped value with data from the given request.
    ///
    /// - Parameters:
    ///   - request: A request describing the data to fetch.
    ///   - database: The database to read from. A value of `nil` will use the default database
    ///     (`@Dependency(\.defaultDatabase)`).
    ///   - animation: The animation to use for user interface changes that result from changes to
    ///     the fetched results.
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    public func load(
      _ request: some FetchKeyRequest<Value>,
      database: (any DatabaseReader)? = nil,
      animation: Animation
    ) async throws {
      try await sharedReader.load(.fetch(request, database: databaseOrDefault(database), animation: animation))
    }
  }
#endif
