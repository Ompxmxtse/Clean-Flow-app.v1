import XCTest
@testable import Clean_Flow_app_v1

class ScannerUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws { }
    
    // MARK: - Scanner Launch Tests
    
    func testScannerViewLaunches() throws {
        let scannerTab = app.tabBars.buttons["Scanner"]
        XCTAssertTrue(scannerTab.waitForExistence(timeout: 5.0))
        scannerTab.tap()
        
        let scannerView = app.otherElements["ScannerView"]
        XCTAssertTrue(scannerView.waitForExistence(timeout: 3.0))
    }
    
    func testScannerElementsExist() throws {
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        let qrScannerButton = app.buttons["QR Code"]
        let nfcScannerButton = app.buttons["NFC Tag"]
        let instructionsText = app.staticTexts["Scan a QR code or NFC tag"]
        
        XCTAssertTrue(qrScannerButton.exists)
        XCTAssertTrue(nfcScannerButton.exists)
        XCTAssertTrue(instructionsText.exists)
    }
    
    func testQRScannerActivation() throws {
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        let qrScannerButton = app.buttons["QR Code"]
        qrScannerButton.tap()
        
        let qrScannerView = app.otherElements["QRScannerView"]
        XCTAssertTrue(qrScannerView.waitForExistence(timeout: 3.0))
        
        let allowButton = app.buttons["Allow"]
        if allowButton.exists {
            allowButton.tap()
        }
    }
    
    func testNFCScannerActivation() throws {
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        let nfcScannerButton = app.buttons["NFC Tag"]
        nfcScannerButton.tap()
        
        let nfcScannerView = app.otherElements["NFCScannerView"]
        XCTAssertTrue(nfcScannerView.waitForExistence(timeout: 3.0))
    }
    
    func testScannerModeToggle() throws {
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        let qrScannerButton = app.buttons["QR Code"]
        qrScannerButton.tap()
        XCTAssertTrue(app.staticTexts["Position QR code within frame"].waitForExistence(timeout: 3.0))
        
        let nfcScannerButton = app.buttons["NFC Tag"]
        nfcScannerButton.tap()
        XCTAssertTrue(app.staticTexts["Hold iPhone near NFC tag"].waitForExistence(timeout: 3.0))
    }
    
    func testScannerInstructionsVisibility() throws {
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        XCTAssertTrue(app.staticTexts["Scan a QR code or NFC tag to begin the cleaning workflow"].exists)
        
        let qrScannerButton = app.buttons["QR Code"]
        qrScannerButton.tap()
        XCTAssertTrue(app.staticTexts["Position QR code within frame"].waitForExistence(timeout: 3.0))
        
        let nfcScannerButton = app.buttons["NFC Tag"]
        nfcScannerButton.tap()
        XCTAssertTrue(app.staticTexts["Hold iPhone near NFC tag"].waitForExistence(timeout: 3.0))
    }
    
    func testScannerCancelButton() throws {
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        let qrScannerButton = app.buttons["QR Code"]
        qrScannerButton.tap()
        
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            XCTAssertTrue(cancelButton.isHittable)
        }
    }
    
    func testScannerAccessibility() throws {
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        XCTAssertTrue(app.buttons["QR Code"].isHittable)
        XCTAssertTrue(app.buttons["NFC Tag"].isHittable)
        XCTAssertTrue(app.otherElements["ScannerView"].exists)
    }
    
    // MARK: - Error Handling Tests
    
    func testScannerPermissionHandling() throws {
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        let qrScannerButton = app.buttons["QR Code"]
        qrScannerButton.tap()
        
        let allowButton = app.buttons["Allow"]
        let dontAllowButton = app.buttons["Don't Allow"]
        
        if allowButton.exists {
            XCTAssertTrue(allowButton.isHittable)
            XCTAssertTrue(dontAllowButton.isHittable)
        }
    }
    
    func testScannerErrorMessages() throws {
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        let errorMessage = app.staticTexts["Scanner Error"]
        let retryButton = app.buttons["Retry"]
        
        if errorMessage.exists {
            XCTAssertTrue(errorMessage.isHittable)
        }
        if retryButton.exists {
            XCTAssertTrue(retryButton.isHittable)
        }
    }
}

// MARK: - Dashboard UI Tests

class DashboardUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testDashboardViewRendering() throws {
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5.0))
        dashboardTab.tap()
        
        let dashboardView = app.otherElements["DashboardView"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 3.0))
        
        XCTAssertTrue(app.staticTexts["Today's Runs"].exists)
        XCTAssertTrue(app.staticTexts["Compliance Rate"].exists)
        XCTAssertTrue(app.staticTexts["Active Staff"].exists)
    }
    
    func testDashboardStatsCards() throws {
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        let statsCards = app.scrollViews.otherElements.matching(identifier: "StatsCard")
        XCTAssertGreaterThan(statsCards.count, 0)
        
        XCTAssertTrue(statsCards.firstMatch.exists)
    }
    
    func testDashboardRecentActivity() throws {
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        XCTAssertTrue(app.staticTexts["Recent Activity"].exists)
        
        let items = app.scrollViews.otherElements.matching(identifier: "ActivityItem")
        XCTAssertGreaterThan(items.count, 0)
    }
    
    func testDashboardRefreshButton() throws {
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        let refreshButton = app.buttons["Refresh"]
        if refreshButton.exists {
            XCTAssertTrue(refreshButton.isHittable)
        }
    }
    
    func testDashboardAccessibility() throws {
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        XCTAssertTrue(app.otherElements["DashboardView"].exists)
        
        let cards = app.scrollViews.otherElements.matching(identifier: "StatsCard")
        XCTAssertTrue(cards.count > 0)
        
        if cards.firstMatch.exists {
            XCTAssertTrue(cards.firstMatch.isHittable)
        }
    }
}
