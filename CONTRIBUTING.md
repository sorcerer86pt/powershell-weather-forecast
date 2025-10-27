# Contributing to PowerShell Weather Forecast

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## 🚀 Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/powershell-weather-forecast.git`
3. Create a branch: `git checkout -b feat/my-new-feature`
4. Make your changes
5. Test your changes on different platforms if possible
6. Commit using conventional commits (see below)
7. Push and create a Pull Request

## 📝 Commit Message Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automatic semantic versioning and changelog generation.

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: A new feature (triggers **MINOR** version bump, e.g., 1.0.0 → 1.1.0)
- **fix**: A bug fix (triggers **PATCH** version bump, e.g., 1.0.0 → 1.0.1)
- **docs**: Documentation only changes (triggers **PATCH** version bump)
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring (neither fixes a bug nor adds a feature)
- **perf**: Performance improvements (triggers **PATCH** version bump)
- **test**: Adding or updating tests
- **build**: Changes to build system or dependencies
- **ci**: Changes to CI/CD configuration
- **chore**: Other changes that don't modify src files (no version bump)

### Breaking Changes

To trigger a **MAJOR** version bump (e.g., 1.0.0 → 2.0.0), add `BREAKING CHANGE:` in the footer or append `!` after the type:

```
feat!: change command line parameter names

BREAKING CHANGE: -Temperature parameter renamed to -Units
```

### Examples

#### Minor Version Bump (New Feature)
```
feat: add support for hourly weather forecast

Added new parameter -Hourly to display hourly forecast
instead of daily forecast.
```

#### Patch Version Bump (Bug Fix)
```
fix: correct temperature conversion for Fahrenheit

The conversion formula was incorrect, causing temperatures
to be displayed 2 degrees higher than actual.
```

#### Patch Version Bump (Documentation)
```
docs: update installation instructions for Arch Linux
```

#### No Version Bump
```
chore: update .gitignore
```

#### Major Version Bump (Breaking Change)
```
feat!: redesign API response structure

BREAKING CHANGE: The weather data structure has been
completely redesigned. All consumers need to update
their code to use the new structure.
```

## 🌍 Adding New Languages

To add a new language translation:

1. Copy `locales/en.json` to `locales/[language-code].json`
2. Translate all weather descriptions
3. Update the language metadata
4. Test the new locale: `pwsh ./WeatherForecast.ps1 -LocaleOverride "[language-code]"`
5. Create a PR with commit message: `feat: add [Language] translation`

See `locales/README.md` for more details.

## ✅ Testing

Before submitting a PR, please test your changes:

### Cross-Platform Testing

If possible, test on:
- ✅ Windows (PowerShell 5.1 and 7+)
- ✅ Linux (PowerShell 7+)
- ✅ macOS (PowerShell 7+)

### Feature Testing

Test the following scenarios:
- City name lookup
- Auto-detection (if applicable to your platform)
- Different temperature units (Celsius/Fahrenheit)
- Different locales
- Error handling (invalid city names, network issues)

## 📋 Pull Request Process

1. **Update Documentation**: If you're adding a feature, update the README.md
2. **Follow Commit Convention**: Use conventional commits for automatic versioning
3. **Test Your Changes**: Ensure your changes work on multiple platforms
4. **Fill PR Template**: Complete the pull request template
5. **Be Responsive**: Respond to review comments promptly

## 🔄 Automatic Versioning

When your PR is merged to `main`:

1. GitHub Actions analyzes your commit messages
2. Determines version bump based on conventional commits:
   - `fix:` → patch version (1.0.0 → 1.0.1)
   - `feat:` → minor version (1.0.0 → 1.1.0)
   - `BREAKING CHANGE:` → major version (1.0.0 → 2.0.0)
3. Automatically creates a GitHub release with changelog
4. Updates CHANGELOG.md

## 📜 Code Style

- Use clear, descriptive variable names
- Add comments for complex logic
- Follow PowerShell best practices
- Use proper error handling with try/catch blocks
- Keep functions focused and modular

## 🐛 Reporting Bugs

When reporting bugs, please include:

- Operating System and version
- PowerShell version (`$PSVersionTable`)
- Complete error message
- Steps to reproduce
- Expected vs actual behavior

## 💡 Suggesting Features

Feature requests are welcome! Please:

- Check if the feature already exists or has been requested
- Describe the use case clearly
- Explain why this would be useful to others
- Consider if it fits the project's scope

## 📧 Questions?

If you have questions, feel free to:
- Open an issue for discussion
- Check existing issues and pull requests
- Review the documentation

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🎉

