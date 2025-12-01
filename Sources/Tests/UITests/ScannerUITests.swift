import XCTest
@testable import CleanFlowApp

class ScannerUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
    }
    
    // MARK: - Scanner Launch Tests
    
    func testScannerViewLaunches() throws {
        // Navigate to scanner
        let scannerTab = app.tabBars.buttons["Scanner"]
        XCTAssertTrue(scannerTab.waitForExistence(timeout: 5.0))
        scannerTab.tap()
        
        // Verify scanner view elements
        let scannerView = app.otherElements["ScannerView"]
        XCTAssertTrue(scannerView.waitForExistence(timeout: 3.0))
    }
    
    func testScannerElementsExist() throws {
        // Navigate to scanner
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        // Check for key scanner elements
        let qrScannerButton = app.buttons["QR Code"]
        let nfcScannerButton = app.buttons["NFC Tag"]
        let instructionsText = app.staticTexts["Scan a QR code or NFC tag"]
        
        XCTAssertTrue(qrScannerButton.exists)
        XCTAssertTrue(nfcScannerButton.exists)
        XCTAssertTrue(instructionsText.exists)
    }
    
    func testQRScannerActivation() throws {
        // Navigate to scanner
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        // Tap QR scanner button
        let qrScannerButton = app.buttons["QR Code"]
        qrScannerButton.tap()
        
        // Verify QR scanner view appears
        let qrScannerView = app.otherElements["QRScannerView"]
        XCTAssertTrue(qrScannerView.waitForExistence(timeout: 3.0))
        
        // Check for camera permission dialog (may appear)
        let allowButton = app.buttons["Allow"]
        if allowButton.exists {
            allowButton.tap()
        }
    }
    
    func testNFCScannerActivation() throws {
        // Navigate to scanner
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        // Tap NFC scanner button
        let nfcScannerButton = app.buttons["NFC Tag"]
        nfcScannerButton.tap()
        
        // Verify NFC scanner view appears
        let nfcScannerView = app.otherElements["NFCScannerView"]
        XCTAssertTrue(nfcScannerView.waitForExistence(timeout: 3.0))
    }
    
    func testScannerModeToggle() throws {
        // Navigate to scanner
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        // Test QR mode
        let qrScannerButton = app.buttons["QR Code"]
        qrScannerButton.tap()
        
        let qrInstructions = app.staticTexts["Position QR code within frame"]
        XCTAssertTrue(qrInstructions.waitForExistence(timeout: 3.0))
        
        // Switch to NFC mode
        let nfcScannerButton = app.buttons["NFC Tag"]
        nfcScannerButton.tap()
        
        let nfcInstructions = app.staticTexts["Hold iPhone near NFC tag"]
        XCTAssertTrue(nfcInstructions.waitForExistence(timeout: 3.0))
    }
    
    func testScannerInstructionsVisibility() throws {
        // Navigate to scanner
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        // Check for instruction elements
        let mainInstructions = app.staticTexts["Scan a QR code or NFC tag to begin the cleaning workflow"]
        let qrInstructions = app.staticTexts["Position QR code within frame"]
        let nfcInstructions = app.staticTexts["Hold iPhone near NFC tag"]
        
        XCTAssertTrue(mainInstructions.exists)
        
        // Test QR mode instructions
        let qrScannerButton = app.buttons["QR Code"]
        qrScannerButton.tap()
        XCTAssertTrue(qrInstructions.waitForExistence(timeout: 3.0))
        
        // Test NFC mode instructions
        let nfcScannerButton = app.buttons["NFC Tag"]
        nfcScannerButton.tap()
        XCTAssertTrue(nfcInstructions.waitForExistence(timeout: 3.0))
    }
    
    func testScannerCancelButton() throws {
        // Navigate to scanner
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        // Start QR scanner
        let qrScannerButton = app.buttons["QR Code"]
        qrScannerButton.tap()
        
        // Look for cancel button
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            XCTAssertTrue(cancelButton.isHittable)
        }
    }
    
    func testScannerAccessibility() throws {
        // Navigate to scanner
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        // Test accessibility labels
        let qrScannerButton = app.buttons["QR Code"]
        let nfcScannerButton = app.buttons["NFC Tag"]
        
        XCTAssertTrue(qrScannerButton.isHittable)
        XCTAssertTrue(nfcScannerButton.isHittable)
        
        // Test VoiceOver support
        let scannerView = app.otherElements["ScannerView"]
        XCTAssertTrue(scannerView.exists)
    }
    
    // MARK: - Scanner Error Handling Tests
    
    func testScannerPermissionHandling() throws {
        // Navigate to scanner
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        // Start QR scanner
        let qrScannerButton = app.buttons["QR Code"]
        qrScannerButton.tap()
        
        // Check for permission dialog
        let allowButton = app.buttons["Allow"]
        let dontAllowButton = app.buttons["Don't Allow"]
        
        // Handle permission dialog if it appears
        if allowButton.exists {
            XCTAssertTrue(allowButton.isHittable)
            XCTAssertTrue(dontAllowButton.isHittable)
        }
    }
    
    func testScannerErrorMessages() throws {
        // Navigate to scanner
        let scannerTab = app.tabBars.buttons["Scanner"]
        scannerTab.tap()
        
        // Check for error message elements
        let errorMessage = app.staticTexts["Scanner Error"]
        let retryButton = app.buttons["Retry"]
        
        // These may not exist initially, but should be available when errors occur
        // Test their existence when they do appear
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
        // Navigate to dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5.0))
        dashboardTab.tap()
        
        // Verify dashboard elements
        let dashboardView = app.otherElements["DashboardView"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 3.0))
        
        // Check for key dashboard components
        let todayRunsCard = app.staticTexts["Today's Runs"]
        let complianceRateCard = app.staticTexts["Compliance Rate"]
        let activeStaffCard = app.staticTexts["Active Staff"]
        
        XCTAssertTrue(todayRunsCard.exists)
        XCTAssertTrue(complianceRateCard.exists)
        XCTAssertTrue(activeStaffCard.exists)
    }
    
    func testDashboardStatsCards() throws {
        // Navigate to dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5.0))
        dashboardTab.tap()
        
        // Check for stats cards
        let statsCards = app.scrollViews.otherElements.matching(identifier: "StatsCard")
        XCTAssertGreaterThan(statsCards.count, 0)
        
        // Verify card content
        let firstCard = statsCards.firstMatch
        XCTAssertTrue(firstCard.exists)
    }
    
    func testDashboardRecentActivity() throws {
        // Navigate to dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5.0))
        dashboardTab.tap()
        
        // Check for recent activity section
        let recentActivity = app.staticTexts["Recent Activity"]
        let activityList = app.scrollViews.otherElements.matching(identifier: "ActivityItem")
        
        XCTAssertTrue(recentActivity.exists)
        XCTAssertGreaterThanOrEqual(activityList.count, 0)
    }
    
    func testDashboardRefreshButton() throws {
        // Navigate to dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5.0))
        dashboardTab.tap()
        
        // Look for refresh button
        let refreshButton = app.buttons.matching(identifier: "Refresh").firstMatch
        if refreshButton.exists {
            XCTAssertTrue(refreshButton.isHittable)
        }
    }
    
    func testDashboardAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5.0))
        dashboardTab.tap()
        
        // Test accessibility elements
        let dashboardView = app.otherElements["DashboardView"]
        let statsCards = app.scrollViews.otherElements.matching(identifier: "StatsCard")
        
        XCTAssertTrue(dashboardView.exists)
        XCTAssertTrue(statsCards.count > 0)
        
        // Test VoiceOver support
        let firstCard = statsCards.firstMatch
        if firstCard.exists {
            XCTAssertTrue(firstCard.isHittable)
        }
    }
        if firstCard.exists {
            XCTAssertTrue(firstCard.isHittable)
        }
    }
        if firstCard.exists {
            XCTAssertTrue(firstCard.isHittable)
        }
    }
}
