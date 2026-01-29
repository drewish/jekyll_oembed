# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2025-01-XX

### Added
- Unit tests for core functionality
- Integration tests for Liquid template registration
- Comprehensive error handling tests for network failures
- Rake tasks for running tests

### Changed
- **BREAKING**: Updated minimum Ruby version requirement to >= 2.7.0
- Updated Jekyll dependency to ~> 4.0 for better compatibility
- Improved parameter parsing using modern Ruby syntax (`Array#to_h` instead of `Hash[*array]`)
- Fixed deprecated `File.exists?` method (now uses `File.exist?`)
- Improved file reading using `File.read` instead of `File.new(...).read`
- Enhanced gemspec with proper license and better description

### Fixed
- Ruby 3.2 compatibility issues
- Parameter parsing edge cases with `split('=', 2)` to handle values containing '='
- Deprecated method warnings
- Network error handling: Now catches all `SocketError` types (DNS failures, connection timeouts, network unreachable) to gracefully handle offline scenarios

### Technical Details
- Replaced `Hash[*params.map{|val| val.split('=')}.flatten]` with `params.map { |val| val.split('=', 2) }.to_h`
- Fixed `File.exists?` → `File.exist?`
- Improved error handling: rescue block now catches `SocketError` (parent class) instead of just `Socket::ResolutionError` to handle all network-related socket errors
- Added 8 comprehensive error handling tests covering network failures, OEmbed errors, caching behavior, and warning messages

## [0.0.1] - Original Release

### Added
- Basic oEmbed functionality for Jekyll
- Support for YouTube, Vimeo, and other oEmbed providers
- Caching mechanism for oEmbed responses
- Liquid tag registration
