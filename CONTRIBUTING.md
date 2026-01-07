# Contributing to Adaptive Cloud Health Dashboard

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## 🤝 How to Contribute

### Reporting Issues

- Use the GitHub issue tracker
- Provide clear description of the issue
- Include steps to reproduce
- Specify your environment (Azure Local version, AKS Arc version, etc.)

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit with clear messages (`git commit -m 'feat: Add amazing feature'`)
6. Push to your branch (`git push origin feature/AmazingFeature`)
7. Open a Pull Request

## 📝 Commit Message Convention

We follow the Conventional Commits specification:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

Example: `feat: Add capacity forecasting query`

## 🧪 Testing Guidelines

- Test workbooks in Azure Portal
- Validate KQL queries return expected results
- Test across multiple subscription scenarios
- Verify parameterization works correctly

## 📋 Pull Request Checklist

- [ ] Code follows project style guidelines
- [ ] Documentation is updated
- [ ] Queries are parameterized (no hardcoded values)
- [ ] Workbooks tested in Azure Portal
- [ ] README updated if needed
- [ ] Changes are backward compatible

## 🎯 Development Setup

See [docs/setup/DEVELOPMENT.md](./docs/setup/DEVELOPMENT.md) for detailed development environment setup.

## 📞 Questions?

Open an issue for questions or reach out to the maintainers.
