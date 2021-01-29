import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AdvanceAudioPlayerTests.allTests),
    ]
}
#endif
