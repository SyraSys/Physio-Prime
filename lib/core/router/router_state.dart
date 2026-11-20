/// Router state management for initial app startup and splash screen sequence.
/// Tracks whether the initial app loading/splash sequence has completed.
/// When false, cold-start navigations redirect to the branded loading page.
bool _isAppInitialized = false;

/// Returns true if the app has completed its initial splash/loading sequence.
bool get isAppInitialized => _isAppInitialized;

/// Marks the app as initialized, allowing normal navigation without splash redirection.
void markAppInitialized() {
  _isAppInitialized = true;
}

/// Resets initialization state (useful for tests or re-authentication).
void resetAppInitialization() {
  _isAppInitialized = false;
}
