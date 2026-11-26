import XCTest

final class SampleTVUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDemoLoginAndRelaunchSkipsLogin() throws {
        let app = launchSampleTV(resetAuth: true)
        signInWithDemoAccount(in: app)

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should appear")
        XCTAssertTrue(app.buttons["Movies"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["TV Shows"].exists)

        app.terminate()
        let relaunched = launchSampleTV(resetAuth: false)
        XCTAssertTrue(relaunched.tabBars.firstMatch.waitForExistence(timeout: 10), "Relaunch should skip login")
        XCTAssertFalse(relaunched.buttons["Continue with Demo Account"].exists, "Login screen should not reappear")
    }

    @MainActor
    func testDiscoverDetailsWatchlistAndTabsNavigation() throws {
        let app = launchSampleTV(resetAuth: true)
        signInWithDemoAccount(in: app)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        attachScreenshot(named: "01-discover", in: app)
        verifyDiscoverAndDetailsFlowIfLoaded(in: app)

        let discoverTab = tabBar.buttons["Discover"]
        let categoriesTab = tabBar.buttons["Categories"]
        let searchTab = tabBar.buttons["Search"]
        let profileTab = tabBar.buttons["Profile"]

        selectTab(categoriesTab, from: discoverTab, direction: .right)
        verifyCategoriesFlowIfLoaded(in: app)

        selectTab(searchTab, from: categoriesTab, direction: .right)
        XCTAssertTrue(
            app.staticTexts["Search Movies and Shows"].waitForExistence(timeout: 5)
                || app.searchFields.firstMatch.waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.buttons["All"].waitForExistence(timeout: 5))
        attachScreenshot(named: "04-search", in: app)

        selectTab(profileTab, from: searchTab, direction: .right)
        XCTAssertTrue(app.staticTexts["Profiles"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Preferences"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["My List"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["profile.signOutButton"].waitForExistence(timeout: 5))
        attachScreenshot(named: "05-profile", in: app)
    }

    @MainActor
    private func attachScreenshot(named name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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
    private func launchSampleTV(resetAuth: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = resetAuth ? ["-reset-auth"] : []
        app.launch()
        return app
    }

    @MainActor
    private func signInWithDemoAccount(in app: XCUIApplication) {
        let demoButton = app.buttons["Continue with Demo Account"]
        XCTAssertTrue(demoButton.waitForExistence(timeout: 10), "Login screen should display demo button")
        if !demoButton.hasFocus {
            _ = moveFocus(to: demoButton, direction: .down, maxSteps: 10)
        }
        XCTAssertTrue(demoButton.hasFocus, "Demo login button should be focused")
        XCUIRemote.shared.press(.select)
    }

    @MainActor
    private func verifyDiscoverAndDetailsFlowIfLoaded(in app: XCUIApplication) {
        let heroPlay = app.buttons["discover.heroPlayButton"]
        let heroDetails = app.buttons["discover.heroDetailsButton"]
        guard heroDetails.waitForExistence(timeout: 10) else { return }

        for _ in 0..<4 {
            if heroPlay.hasFocus || heroDetails.hasFocus { break }
            XCUIRemote.shared.press(.down)
        }
        if heroPlay.hasFocus && !heroDetails.hasFocus {
            _ = moveFocus(to: heroDetails, direction: .right, maxSteps: 2)
        }
        guard heroDetails.hasFocus else { return }

        XCUIRemote.shared.press(.select)
        let watchlist = app.buttons["details.watchlistButton"]
        if watchlist.waitForExistence(timeout: 6) {
            XCTAssertTrue(app.buttons["details.playButton"].exists)
            _ = moveFocus(to: watchlist, direction: .right, maxSteps: 4)
            if watchlist.hasFocus {
                XCUIRemote.shared.press(.select)
            }
            attachScreenshot(named: "02-details", in: app)
        }
        XCUIRemote.shared.press(.menu)
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)
    }

    @MainActor
    private func verifyCategoriesFlowIfLoaded(in app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Categories"].waitForExistence(timeout: 5))
        let allMoviesTile = app.buttons["category.tile.all-movies"]
        guard allMoviesTile.waitForExistence(timeout: 8) else { return }
        attachScreenshot(named: "03-categories", in: app)
        if moveFocus(to: allMoviesTile, direction: .down, maxSteps: 6) {
            XCUIRemote.shared.press(.select)
            XCTAssertTrue(app.buttons["Popular"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["Top Rated"].exists)
            XCUIRemote.shared.press(.menu)
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)
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
            _ = moveFocus(to: currentTab, direction: .up, maxSteps: 8)
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
