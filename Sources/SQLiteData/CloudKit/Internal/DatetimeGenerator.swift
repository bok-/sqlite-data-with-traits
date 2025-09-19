import Foundation

#if canImport(Dependencies)
  import Dependencies
#endif

package struct CurrentTimeGenerator: Sendable {
  private var generate: @Sendable () -> Int64
  package var now: Int64 {
    get { self.generate() }
    set { self.generate = { newValue } }
  }
  package func callAsFunction() -> Int64 {
    self.generate()
  }
  package static var liveValue: CurrentTimeGenerator {
    Self { Int64(clock_gettime_nsec_np(CLOCK_REALTIME)) }
  }
  package static var testValue: CurrentTimeGenerator {
    Self { Int64(clock_gettime_nsec_np(CLOCK_REALTIME)) }
  }
}

#if canImport(Dependencies)
  extension CurrentTimeGenerator: DependencyKey {}

  extension DependencyValues {
    package var currentTime: CurrentTimeGenerator {
      get { self[CurrentTimeGenerator.self] }
      set { self[CurrentTimeGenerator.self] = newValue }
    }
  }
#endif
