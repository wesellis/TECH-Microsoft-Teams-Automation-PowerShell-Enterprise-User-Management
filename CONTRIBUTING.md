# Contributing to Microsoft Teams Automation Bot

Thank you for your interest in contributing to the Microsoft Teams Automation Bot project! This document provides guidelines and information for contributors.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and professional environment for all contributors.

## How to Contribute

### Reporting Issues

Before creating an issue, please:
1. Check if the issue has already been reported
2. Provide clear and detailed information about the problem
3. Include PowerShell version and Microsoft Graph module versions
4. Provide steps to reproduce the issue

### Suggesting Enhancements

We welcome suggestions for improvements! Please:
1. Check if the enhancement has already been suggested
2. Provide a clear description of the proposed feature
3. Explain why this enhancement would be useful
4. Consider the impact on existing functionality

### Pull Requests

1. **Fork the repository** and create your feature branch from `main`
2. **Write clear, descriptive commit messages**
3. **Test your changes** thoroughly
4. **Update documentation** as needed
5. **Follow PowerShell best practices**
6. **Ensure your code is properly commented**

## Development Guidelines

### PowerShell Standards
- Use approved PowerShell verbs
- Include comprehensive help documentation
- Implement proper error handling
- Use meaningful variable names
- Follow PowerShell formatting conventions

### Code Style
- Use 4-space indentation
- Keep lines under 120 characters when possible
- Use consistent naming conventions
- Add comments for complex logic

### Testing
- Test with different Teams configurations
- Verify functionality with various user permissions
- Test error handling scenarios
- Ensure scripts work with different tenant configurations

## Development Setup

### Prerequisites
- PowerShell 5.1 or later
- Microsoft Graph PowerShell SDK
- Azure AD app registration with Teams permissions
- Microsoft Teams admin access for testing

### Local Development
1. Fork and clone the repository
2. Set up Azure AD app registration
3. Configure authentication credentials
4. Test your changes thoroughly

## Submission Guidelines

### Commit Messages
Use clear, descriptive commit messages:
```
Add script for bulk Teams channel creation

- Implement bulk channel creation from CSV
- Add error handling for duplicate channels
- Update documentation with usage examples
```

### Pull Request Process
1. Update documentation if needed
2. Ensure code follows style guidelines
3. Test thoroughly before submitting
4. Provide clear description of changes

## Script Categories

### User Management
Scripts for adding, removing, and managing Teams users

### Channel Management
Scripts for creating, updating, and deleting Teams channels

### Meeting Management
Scripts for scheduling and managing Teams meetings

### Message Management
Scripts for sending and managing Teams messages

### Reporting
Scripts for generating Teams usage and activity reports

## Recognition

Contributors will be acknowledged in the project documentation and release notes.

## Questions?

If you have questions about contributing, please:
- Open an issue with the "question" label
- Contact Wesley Ellis at wes@wesellis.com

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing to Microsoft Teams Automation Bot!