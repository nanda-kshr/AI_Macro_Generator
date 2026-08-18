# AI Macro Generator - Agent Guidelines

Operational guidelines for AI agents working in this repository.

---

## 1. Knowledge Base (Google OKF)

Domain knowledge, architecture, and workflow specifications are structured following the **[Google Open Knowledge Format (OKF)](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)** and stored in the [`knowledge/`](knowledge/index.md) directory.

> **Before making architectural changes or implementing new domain features, consult the OKF knowledge bundle in [`knowledge/`](knowledge/index.md).**

- [`knowledge/index.md`](knowledge/index.md): Knowledge catalog index
- [`knowledge/architecture.md`](knowledge/architecture.md): System design and component layers
- [`knowledge/workflow_execution.md`](knowledge/workflow_execution.md): Pipeline stages and validation model

When adding or updating domain documentation, maintain OKF compliance (Markdown files with YAML frontmatter containing `type`, `title`, `description`, `tags`, etc.).

---

## 2. Core Agent Rules

1. **Keep Explanations Concise**: Answer directly without fluff.
2. **Follow Existing Code Patterns**: Maintain clean, idiomatic Flutter/Dart architecture.
3. **Avoid Code Duplication**: Reuse existing classes, services, and widgets.
4. **Strict Scope Control**: Implement only what was requested.
5. **Clarify Ambiguities**: Ask the user directly when details are missing.

---

## 3. Project Commands

- **Dependencies**: `flutter pub get`
- **Run**: `flutter run`
- **Test**: `flutter test`
- **Analyze**: `flutter analyze`
- **Format**: `dart format .`
