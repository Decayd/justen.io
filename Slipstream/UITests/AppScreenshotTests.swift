import XCTest

/// Walks through the main screens with the illustrative season and saves screenshots.
/// Set SNAPSHOT_DIR (TEST_RUNNER_SNAPSHOT_DIR with xcodebuild) to choose the output folder.
final class AppScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments += ["-SlipstreamSampleData"]
    }

    func testCaptureMainScreens() throws {
        for style in ["dark", "light"] {
            app.launchArguments = ["-SlipstreamSampleData", "-SlipstreamColorScheme", style]
            app.launch()

            XCTAssertTrue(app.tabBars.buttons["Paddock"].waitForExistence(timeout: 10))
            save("paddock-\(style)")
            app.swipeUp()
            save("paddock-scrolled-\(style)")

            app.tabBars.buttons["Standings"].tap()
            save("standings-\(style)")

            let firstDriver = app.scrollViews.buttons.firstMatch
            if firstDriver.waitForExistence(timeout: 5) {
                firstDriver.tap()
                save("driver-\(style)")
                app.swipeUp()
                save("driver-scrolled-\(style)")
            }

            app.tabBars.buttons["Calendar"].tap()
            save("calendar-\(style)")

            app.tabBars.buttons["Widgets"].tap()
            save("studio-\(style)")

            let template = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Next Race")).firstMatch
            if template.waitForExistence(timeout: 5) {
                template.tap()
                save("editor-\(style)")
                let segment = app.segmentedControls.buttons["Large"]
                if segment.waitForExistence(timeout: 3) {
                    segment.tap()
                    save("editor-large-\(style)")
                }
            }
            app.terminate()
        }
    }

    private func save(_ name: String) {
        Thread.sleep(forTimeInterval: 0.8)
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        guard let path = ProcessInfo.processInfo.environment["SNAPSHOT_DIR"] else { return }
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? screenshot.pngRepresentation.write(to: directory.appendingPathComponent("app-\(name).png"))
    }
}
