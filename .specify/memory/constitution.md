<!--
============================================================================
SYNC IMPACT REPORT - Constitution v1.0.0
============================================================================
Version Change: Initial Creation → 1.0.0
Rationale: First constitution establishment for Flutter AI project

Modified Principles: N/A (initial creation)
Added Sections:
  - Core Principles (6 principles for Flutter/AI development)
  - Technical Standards (Flutter-specific requirements)
  - Quality Assurance (Testing and quality gates)
  - Governance (Amendment and compliance procedures)

Templates Status:
  ✅ .specify/templates/plan-template.md - Reviewed, compatible
  ✅ .specify/templates/spec-template.md - Reviewed, compatible
  ✅ .specify/templates/tasks-template.md - Reviewed, compatible
  ✅ .specify/templates/checklist-template.md - Compatible
  ✅ .specify/templates/agent-file-template.md - Compatible

Follow-up TODOs: None - all placeholders filled

Project Context:
  - Flutter SDK 3.5.4+
  - Mobile application (iOS/Android)
  - AI integration focus
  - Material Design 3
============================================================================
-->

# AI Flutter Constitution

## Core Principles

### I. Widget Composition & Reusability

Flutter development MUST follow composition over inheritance patterns. All UI components MUST be built as reusable, composable widgets with clear, single responsibilities.

**Requirements:**
- Break complex screens into small, focused widget components
- Each widget MUST have a single, well-defined purpose
- Custom widgets MUST be stateless unless state management is explicitly required
- Widget trees MUST remain readable and maintainable (max 3-4 nesting levels recommended)
- Shared widgets MUST be extracted to `lib/widgets/` or feature-specific directories

**Rationale:** Flutter's declarative UI paradigm thrives on composition. Small, focused widgets improve testability, reusability, and hot reload performance while reducing cognitive load.

---

### II. State Management Clarity

State management MUST be explicit, predictable, and appropriate for scope. Local state uses `setState`, shared state uses declared state management solution (Provider/Riverpod/Bloc).

**Requirements:**
- Widget-local state MUST use `setState` or `StatefulWidget`
- Cross-widget state MUST use a consistent state management pattern (to be defined per feature)
- Global app state MUST be managed through a single source of truth
- State mutations MUST be traceable and debuggable
- Avoid mixing state management approaches within a single feature

**Rationale:** Predictable state flow prevents bugs, improves maintainability, and makes debugging straightforward. Consistency across the codebase reduces cognitive overhead.

---

### III. Test-Driven Development (NON-NEGOTIABLE)

Testing is mandatory before implementation. Widget tests MUST be written and MUST fail before implementing the UI. Integration tests MUST cover critical user journeys.

**Requirements:**
- Widget tests MUST be written FIRST for all custom widgets
- Tests MUST fail initially (Red-Green-Refactor cycle)
- User approval of failing tests before implementation
- Critical user flows MUST have integration tests
- All business logic MUST have unit tests
- Aim for >80% code coverage on feature logic

**Rationale:** TDD ensures requirements are clear, reduces regressions, and produces maintainable code. Flutter's excellent testing tools make this practice efficient and reliable.

---

### IV. Performance-First Mobile Development

Flutter apps MUST maintain 60fps (16ms per frame) on target devices. Performance MUST be measured, not assumed.

**Requirements:**
- Use Flutter DevTools Performance view to profile builds and renders
- Avoid expensive operations in `build()` methods
- Use `const` constructors wherever possible
- Implement `ListView.builder` for long lists (never `ListView` with all children)
- Images MUST be properly sized and cached
- Heavy computations MUST use `compute()` for isolate-based threading
- Widget rebuilds MUST be minimized using proper keys and selective rebuilding

**Rationale:** Mobile users expect smooth, responsive experiences. Janky animations and slow interactions drive user abandonment. Performance is a feature, not an optimization.

---

### V. AI Integration Patterns

AI features MUST be implemented with user experience, error handling, and offline considerations as first-class concerns.

**Requirements:**
- AI API calls MUST be asynchronous with proper loading states
- Network failures MUST be handled gracefully with user-friendly messages
- AI responses MUST be streamed when possible for perceived performance
- User MUST be able to cancel long-running AI operations
- AI features MUST degrade gracefully when offline (cached responses, offline mode, or clear messaging)
- AI model responses MUST be validated and sanitized
- Rate limiting and quota management MUST be implemented

**Rationale:** AI features introduce uncertainty (latency, failures, costs). Robust patterns ensure reliable user experiences and prevent production issues.

---

### VI. Platform-Aware Development

Flutter apps MUST respect platform conventions while maintaining cross-platform code reuse. Platform-specific features MUST be isolated and clearly documented.

**Requirements:**
- Use Material Design for Android, Cupertino widgets for iOS where appropriate
- Platform-specific code MUST be isolated using `Platform.isIOS`/`Platform.isAndroid` or platform channels
- Navigation patterns MUST follow platform conventions (Material/Cupertino)
- Handle platform permissions explicitly with proper error states
- Test on BOTH iOS and Android before marking features complete
- Platform-specific configurations MUST be documented in feature specs

**Rationale:** Users expect platform-native experiences. Flutter enables code reuse without sacrificing platform conventions when approached thoughtfully.

---

## Technical Standards

### Flutter & Dart Requirements

- **Flutter SDK**: 3.5.4+ (stable channel)
- **Dart Language**: Leveraging null safety, latest language features
- **Linting**: `flutter_lints` package enforced, analysis_options.yaml configured
- **Formatting**: `dart format` with 80-character line limit
- **Dependencies**: Minimize external packages; justify each addition in specs
- **Asset Management**: All assets in `assets/` directory, properly declared in pubspec.yaml

### Code Organization

```
lib/
├── main.dart                 # App entry point
├── app/                      # App-level configuration
│   ├── routes.dart
│   └── theme.dart
├── core/                     # Shared utilities, extensions, constants
├── features/                 # Feature modules (self-contained)
│   └── [feature_name]/
│       ├── models/
│       ├── services/
│       ├── widgets/
│       └── screens/
└── widgets/                  # Shared widgets across features

test/
├── widget_test/              # Widget tests
├── integration_test/         # Integration tests
└── unit_test/                # Unit tests for models/services
```

### Documentation Requirements

- Public APIs MUST have dartdoc comments
- Complex logic MUST have inline comments explaining "why," not "what"
- README.md MUST document setup, dependencies, and running instructions
- Feature specs MUST be maintained in `.specify/specs/[feature]/`

---

## Quality Assurance

### Testing Gates

Before any feature is considered complete:

1. ✅ All widget tests pass
2. ✅ All integration tests for user journeys pass
3. ✅ Manual testing on iOS simulator/device
4. ✅ Manual testing on Android emulator/device
5. ✅ Performance profiling shows no janky frames in critical paths
6. ✅ Accessibility: Screen reader navigation works (TalkBack/VoiceOver)
7. ✅ Code review completed and approved

### Definition of Done

A feature is "Done" when:
- Spec requirements met and verified
- Tests written (and passed) per Test-First principle
- Code reviewed and merged to main branch
- Tested on both platforms (iOS & Android)
- Performance benchmarks met (60fps maintained)
- Documentation updated (code comments + feature docs)
- No known bugs or regressions introduced

---

## Governance

### Constitutional Authority

This constitution supersedes all other development practices and guidelines. When conflicts arise, this document is the authoritative source.

### Amendment Process

1. **Proposal**: Document proposed change with rationale
2. **Review**: Team discussion and approval required
3. **Version Bump**: Follow semantic versioning (MAJOR.MINOR.PATCH)
   - **MAJOR**: Removing or fundamentally changing core principles
   - **MINOR**: Adding new principles or expanding requirements
   - **PATCH**: Clarifications, wording improvements, typo fixes
4. **Migration**: Update all dependent templates and documentation
5. **Commit**: Record change with version update and sync report

### Compliance

- All feature specs MUST include a "Constitution Check" section verifying alignment
- Code reviews MUST verify constitutional compliance
- Violations MUST be justified in writing (see Complexity Tracking in plan template)
- Team members are empowered to flag violations and request clarification

### Runtime Guidance

For day-to-day development guidance beyond constitutional principles, refer to:
- Flutter official documentation: https://docs.flutter.dev/
- Dart language guide: https://dart.dev/guides
- Material Design 3: https://m3.material.io/
- Feature-specific quickstart guides in `.specify/specs/[feature]/quickstart.md`

---

**Version**: 1.0.0 | **Ratified**: 2025-12-03 | **Last Amended**: 2025-12-03
