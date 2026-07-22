# Framework Integrations

This directory contains framework-specific integration guides for protovalidate.

## Available Integrations

| Framework | Language | File |
|-----------|----------|------|
| Go-Kratos | Go | [kratos.md](kratos.md) |

## Adding New Integrations

To add a new framework integration:

1. Create a new markdown file named after the framework (e.g., `go-zero.md`, `spring.md`)
2. Include the following sections:
   - Installation
   - Middleware/Interceptor implementation
   - Configuration
   - Usage examples
   - Troubleshooting

### Integration Template

```markdown
# [Framework Name] Integration

## Installation

[Package installation commands]

## Middleware Implementation

[Code example for validation middleware]

## Configuration

[Framework-specific configuration]

## Usage Example

[Complete working example]

## Troubleshooting

[Common issues and solutions]
```

## Supported Languages

Protovalidate has official runtime libraries for:

- **Go**: [protovalidate-go](https://github.com/bufbuild/protovalidate-go)
- **Java**: [protovalidate-java](https://github.com/bufbuild/protovalidate-java)
- **Python**: [protovalidate-python](https://github.com/bufbuild/protovalidate-python)
- **C++**: [protovalidate-cc](https://github.com/bufbuild/protovalidate-cc)
- **TypeScript/JavaScript**: [protovalidate-es](https://github.com/bufbuild/protovalidate-es)
