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
    func testTVShowSeasonAndEpisodeSelectionIfLoaded() throws {
        let app = launchSampleTV(resetAuth: true)
        signInWithDemoAccount(in: app)

        guard selectTVShowsTabIfPresent(in: app) else { return }

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
        guard heroDetails.hasFocus else {
            XCTFail("TV show hero details button should receive focus")
            return
        }
        XCUIRemote.shared.press(.select)
        verifyTVDetailsSeasonsAndEpisodes(in: app)
    }

    @MainActor
    private func selectTVShowsTabIfPresent(in app: XCUIApplication) -> Bool {
        let moviesButton = app.buttons["Movies"]
        let tvShowsButton = app.buttons["TV Shows"]
        guard tvShowsButton.waitForExistence(timeout: 10) else { return false }

        if !moviesButton.hasFocus && !tvShowsButton.hasFocus {
            _ = moveFocus(to: moviesButton, direction: .down, maxSteps: 4)
        }
        if !tvShowsButton.hasFocus {
            _ = moveFocus(to: tvShowsButton, direction: .right, maxSteps: 4)
        }
        XCTAssertTrue(tvShowsButton.hasFocus, "TV Shows segment should receive focus")
        XCUIRemote.shared.press(.select)
        return true
    }

    @MainActor
    private func verifyTVDetailsSeasonsAndEpisodes(in app: XCUIApplication) {
        let seasonButton = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "details.seasonButton.")
        ).firstMatch
        XCTAssertTrue(seasonButton.waitForExistence(timeout: 10), "TV details should show season buttons")

        let episodeCard = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "details.episodeCard.")
        ).firstMatch
        XCTAssertTrue(episodeCard.waitForExistence(timeout: 10), "TV details should show episode cards")

        attachScreenshot(named: "06-tv-details-episodes", in: app)

        let season2Button = app.buttons["details.seasonButton.2"]
        if season2Button.waitForExistence(timeout: 3),
           moveFocus(to: season2Button, direction: .down, maxSteps: 4) ||
           moveFocus(to: season2Button, direction: .right, maxSteps: 4) {
            XCUIRemote.shared.press(.select)
            let season2Episode = app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "details.episodeCard.2.")
            ).firstMatch
            XCTAssertTrue(
                season2Episode.waitForExistence(timeout: 8),
                "Selecting Season 2 should load Season 2 episodes"
            )
            _ = moveFocus(to: season2Episode, direction: .down, maxSteps: 4)
        } else {
            _ = moveFocus(to: episodeCard, direction: .down, maxSteps: 6)
        }
        attachScreenshot(named: "07-tv-episodes-focused", in: app)
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
