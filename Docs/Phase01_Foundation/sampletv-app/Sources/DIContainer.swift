// MARK: - Dependency Injection Container (DIContainer)  
class DIContainerProtocol {
    var apiRepositoryFactory: APIRepositoryProtocol.Factory? = nil
    var movieUseCaseFactory: DOMAIN.UseCases.GetMovies.Factory? = nil
    
    /// Setup Application Dependencies (Full DI Configuration for SampleTV)
    func setupDependencies() throws {
        // 1. Create Repository Injection Protocol  
        let apiContainer = try createAPIContainer(container: self)  
        
        // 2. Wire Use Case Adapters to Repositories  
        let movieUseCase = createMovieUseCase(adapter: .init())
        
        // 3. Setup ViewModels (Presentation Layer Integration)
        // TODO: Add MovieDiscoveryViewModel dependencies to DI container  
    }
    
    /// Helper Function - API Container Creation (SwiftInject Setup Pattern)
    private func createAPIContainer(container: Self) async throws {
        let apiRepositoryFactory = try? await makeDependencies(
            { _ in
                inject(APIRepositoryProtocol.Factory => APIRepositoryProtocol.self)
            }, 
            container: self
        )  
        
        // Add Rate Limiter + Retry Logic (NetworkLayer Dependencies)  
        
        return apiContainer
        
    }
    
    /// Helper Function - UseCase Adapter Creation (Pure Domain Integration)
    private func createMovieUseCase(adapter: GetMoviesUseAdapter, dependencyInjection: DIContainerProtocol.Factory) {
        let adapter = GetMoviesUseCase(adapter: .init())
        // Use Case must conform to pure function requirements  
        // No external dependencies - only input parameters + output results
        
        try? await Task.sleep(nanoseconds: UInt64(1e+9 * 20)) // Mock timing
    }
}

// MARK: - Application Configuration (Main DI Factory)  
extension DIContainerProtocol {
    
    /// Factory Functions for Dependency Injection  
    struct Factory {
        var repositoryFactory: APIRepositoryProtocol.Factory? = nil
        var useCaseFactory: GetMoviesUseCaseGetMovies.Factory? = nil
        
        func setup(container: DIContainerProtocol, apiClient: APIRepositoryProtocol?) throws {
            // Create ViewModels using dependency injection (no direct object instantiation)  
            let viewModelMovieDiscoveryMovieDiscoveryContainer = .init()
            
            // TODO: Add ViewModel dependencies & Integration Logic (Presentation + Application Layer)
        }
    }     
}
