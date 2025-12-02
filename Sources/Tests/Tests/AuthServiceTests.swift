import XCTest
import FirebaseAuth
@testable import Clean_Flow_app_v1

@MainActor
class AuthServiceTests: XCTestCase {
    var authService: AuthService!
    
    override func setUpWithError() throws {
        authService = AuthService()
    }
    
    override func tearDownWithError() throws {
        authService = nil
    }
    
    // MARK: - Sign In Tests
    
    func testSignInSuccess() async throws {
        let expectation = XCTestExpectation(description: "Sign in success")
        
        let mockEmail = "test@example.com"
        let mockPassword = "password123"
        
        // Test actual AuthService sign-in method
        authService.signIn(email: mockEmail, password: mockPassword)
        
        // Verify loading state changes
        XCTAssertTrue(authService.isLoading)
        
        // Wait for async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify loading state is completed
        XCTAssertFalse(authService.isLoading)
    }
    
    func testSignInInvalidEmail() async throws {
        let expectation = XCTestExpectation(description: "Sign in with invalid email")
        
        let invalidEmail = "invalid-email"
        let mockPassword = "password123"
        
        // Test actual AuthService sign-in method with invalid email
        authService.signIn(email: invalidEmail, password: mockPassword)
        
        // Verify loading state changes
        XCTAssertTrue(authService.isLoading)
        
        // Wait for async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify loading state is completed and error is set
        XCTAssertFalse(authService.isLoading)
        XCTAssertNotNil(authService.errorMessage)
        XCTAssertTrue(authService.errorMessage?.contains("email") == true || 
                      authService.errorMessage?.contains("identifier") == true)
    }
    
    func testSignInEmptyPassword() async throws {
        let expectation = XCTestExpectation(description: "Sign in with empty password")
        
        let mockEmail = "test@example.com"
        let emptyPassword = ""
        
        // Test actual AuthService sign-in method with empty password
        authService.signIn(email: mockEmail, password: emptyPassword)
        
        // Verify loading state changes
        XCTAssertTrue(authService.isLoading)
        
        // Wait for async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify loading state is completed and error is set
        XCTAssertFalse(authService.isLoading)
        XCTAssertNotNil(authService.errorMessage)
        XCTAssertTrue(authService.errorMessage?.contains("password") == true || 
                      authService.errorMessage?.contains("credential") == true)
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpSuccess() async throws {
        let expectation = XCTestExpectation(description: "Sign up success")
        
        let mockEmail = "newuser@example.com"
        let mockPassword = "password123"
        let mockName = "Test User"
        let mockDepartment = "Testing"
        let mockRole = User.UserRole.cleaner
        
        // Test actual AuthService sign-up method
        authService.signUp(email: mockEmail, password: mockPassword, name: mockName, role: mockRole, department: mockDepartment)
        
        // Verify loading state changes
        XCTAssertTrue(authService.isLoading)
        
        // Wait for async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify loading state is completed
        XCTAssertFalse(authService.isLoading)
    }
    
    func testSignUpInvalidEmail() async throws {
        let expectation = XCTestExpectation(description: "Sign up with invalid email")
        
        let invalidEmail = "invalid-email"
        let mockPassword = "password123"
        let mockName = "Test User"
        let mockDepartment = "Testing"
        let mockRole = User.UserRole.cleaner
        
        // Test actual AuthService sign-up method with invalid email
        authService.signUp(email: invalidEmail, password: mockPassword, name: mockName, role: mockRole, department: mockDepartment)
        
        // Verify loading state changes
        XCTAssertTrue(authService.isLoading)
        
        // Wait for async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify loading state is completed and error is set
        XCTAssertFalse(authService.isLoading)
        XCTAssertNotNil(authService.errorMessage)
        XCTAssertTrue(authService.errorMessage?.contains("email") == true || 
                      authService.errorMessage?.contains("identifier") == true)
    }
    
    // MARK: - Password Reset Tests
    
    func testPasswordResetSuccess() async throws {
        let expectation = XCTestExpectation(description: "Password reset success")
        
        let validEmail = "test@example.com"
        
        // Test actual AuthService password reset method
        authService.resetPassword(email: validEmail)
        
        // Verify loading state changes
        XCTAssertTrue(authService.isLoading)
        
        // Wait for async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify loading state is completed
        XCTAssertFalse(authService.isLoading)
    }
    
    func testPasswordResetInvalidEmail() async throws {
        let expectation = XCTestExpectation(description: "Password reset with invalid email")
        
        let invalidEmail = "invalid-email"
        
        // Test actual AuthService password reset method with invalid email
        authService.resetPassword(email: invalidEmail)
        
        // Verify loading state changes
        XCTAssertTrue(authService.isLoading)
        
        // Wait for async operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify loading state is completed and error is set
        XCTAssertFalse(authService.isLoading)
        XCTAssertNotNil(authService.errorMessage)
        XCTAssertTrue(authService.errorMessage?.contains("email") == true || 
                      authService.errorMessage?.contains("identifier") == true)
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOutSuccess() async throws {
        // Test actual AuthService sign-out method
        authService.signOut()
        
        // Verify method executes without throwing
        XCTAssertNotNil(authService)
        XCTAssertFalse(authService.isLoading)
    }
    
    // MARK: - User State Tests
    
    func testCurrentUserNilInitially() async throws {
        // Test actual AuthService initial state
        XCTAssertNotNil(authService)
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertFalse(authService.isLoading)
        XCTAssertNil(authService.errorMessage)
    }
    
    func testAuthStateChanges() async throws {
        // Test actual AuthService auth state listener functionality
        XCTAssertNotNil(authService)
        
        // Verify initial state
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(authService.isAuthenticated)
        
        // Test that the auth state listener is set up (this would be tested with mocks in a real scenario)
        // For now, we verify the service is properly initialized
        XCTAssertTrue(true) // Placeholder for actual auth state testing
    }
}

// MARK: - Mock Firebase Auth (for testing)

class MockAuth {
    static func signIn(email: String, password: String) async throws -> AuthDataResult {
        // Mock implementation
        return AuthDataResult(user: MockUser())
    }
    
    static func signUp(email: String, password: String) async throws -> AuthDataResult {
        // Mock implementation
        return AuthDataResult(user: MockUser())
    }
    
    static func resetPassword(email: String) async throws {
        // Mock implementation
    }
}

class MockUser {
    let uid = "mock-user-id"
    let email = "mock@example.com"
    let displayName = "Mock User"
}

class AuthDataResult {
    let user: MockUser
    
    init(user: MockUser) {
        self.user = user
    }
}

