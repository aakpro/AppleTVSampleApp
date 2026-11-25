import XCTest

final class SampleTVUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDemoLoginAndTabNavigation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-reset-auth"]
        app.launch()

        let demoButton = app.buttons["Continue with Demo Account"]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 10), "Login screen should display demo sign-in button")

        XCTAssertTrue(
            moveFocus(to: demoButton, direction: .down, maxSteps: 10),
            "Demo login button should be reachable via Siri Remote focus"
        )
        XCUIRemote.shared.press(.select)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after demo login")

        let discoverTab = tabBar.buttons["Discover"]
        let categoriesTab = tabBar.buttons["Categories"]
        let searchTab = tabBar.buttons["Search"]
        let profileTab = tabBar.buttons["Profile"]

        XCTAssertTrue(discoverTab.exists, "Discover tab should exist")
        XCTAssertTrue(categoriesTab.exists, "Categories tab should exist")
        XCTAssertTrue(searchTab.exists, "Search tab should exist")
        XCTAssertTrue(profileTab.exists, "Profile tab should exist")

        selectTab(categoriesTab, from: discoverTab, direction: .right)
        XCTAssertTrue(
            app.navigationBars["Categories"].waitForExistence(timeout: 5)
                || app.staticTexts["Categories"].waitForExistence(timeout: 5),
            "Categories screen should be visible"
        )

        selectTab(searchTab, from: categoriesTab, direction: .right)
        XCTAssertTrue(
            app.staticTexts["Search Movies and Shows"].waitForExistence(timeout: 5)
                || app.searchFields.firstMatch.waitForExistence(timeout: 5),
            "Search screen should be visible"
        )

        selectTab(profileTab, from: searchTab, direction: .right)
        XCTAssertTrue(
            app.staticTexts["Profiles"].waitForExistence(timeout: 5),
            "Profile screen should show Profiles section"
        )
        XCTAssertTrue(
            app.staticTexts["My List"].waitForExistence(timeout: 5),
            "Profile screen should show My List section"
        )

        selectTab(discoverTab, from: profileTab, direction: .left)
        XCTAssertTrue(
            app.buttons["Movies"].waitForExistence(timeout: 5)
                && app.buttons["TV Shows"].exists,
            "Should navigate back to Discover tab"
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["-reset-auth"]
            app.launch()
        }
    }

    @MainActor
    private func moveFocus(to element: XCUIElement, direction: XCUIRemote.Button, maxSteps: Int = 8) -> Bool {
        if element.hasFocus {
            return true
        }
        for _ in 0..<maxSteps {
            XCUIRemote.shared.press(direction)
            if element.hasFocus {
                return true
            }
        }
        return element.hasFocus
    }

    @MainActor
    private func selectTab(_ targetTab: XCUIElement, from currentTab: XCUIElement, direction: XCUIRemote.Button) {
        if !currentTab.hasFocus {
            _ = moveFocus(to: currentTab, direction: .up, maxSteps: 6)
        }
        if !targetTab.hasFocus {
            XCTAssertTrue(
                moveFocus(to: targetTab, direction: direction, maxSteps: 6),
                "Expected \(targetTab.label) tab to receive focus"
            )
        }
        XCUIRemote.shared.press(.select)
    }
}
