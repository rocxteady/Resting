# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`  
**Created**: [DATE]  
**Status**: Draft  
**Input**: User description: "$ARGUMENTS"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently - e.g., "Can be fully tested by [specific action] and delivers [specific value]"]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

<!--
  ACTION REQUIRED: Replace these prompts with feature-specific edge cases.
-->

- What happens when the request is cancelled, retried, or overlaps with another
  async operation?
- How does the feature behave on unsupported Apple platform versions or when an
  API requires availability gating?
- What is the fallback behavior for malformed responses, empty bodies, or
  decoding failures?
- If user-facing text changes, how does English default localization behave when
  another locale is missing a translation?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST [specific capability, e.g., "build a GET request with
  headers and query items"]
- **FR-002**: System MUST [specific capability, e.g., "decode responses into a
  `Decodable` model"]  
- **FR-003**: Users MUST be able to [key interaction, e.g., "configure request
  body, headers, and HTTP method"]
- **FR-004**: System MUST [behavior, e.g., "surface deterministic error values
  for transport, status-code, and decoding failures"]
- **FR-005**: Any changed public API MUST include Swift documentation comments
  and preserve a simple call surface unless a documented requirement forces
  added complexity

*Example of marking unclear requirements:*

- **FR-006**: System MUST authenticate users via [NEEDS CLARIFICATION: auth method not specified - email/password, SSO, OAuth?]
- **FR-007**: System MUST retain user data for [NEEDS CLARIFICATION: retention period not specified]

## Compatibility & API Impact *(mandatory)*

- **Public API Impact**: [List any public types, methods, parameters, or
  breaking changes. State "None" if the change is internal only.]
- **Platform Impact**: [State affected Apple platforms, minimum OS changes, and
  any availability-gated behavior.]
- **Concurrency Impact**: [State any async/await, actor isolation, `Sendable`,
  cancellation, or threading implications.]
- **Localization Impact**: [State whether English resources change and whether
  additional locales must be updated.]

### Key Entities *(include if feature involves data)*

- **[Entity 1]**: [What it represents, key attributes without implementation]
- **[Entity 2]**: [What it represents, relationships to other entities]

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: [Measurable metric, e.g., "Users can complete account creation in under 2 minutes"]
- **SC-002**: [Measurable metric, e.g., "System handles 1000 concurrent users without degradation"]
- **SC-003**: [User satisfaction metric, e.g., "90% of users successfully complete primary task on first attempt"]
- **SC-004**: [Business metric, e.g., "Reduce support tickets related to [X] by 50%"]

## Assumptions

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right assumptions based on reasonable defaults
  chosen when the feature description did not specify certain details.
-->

- [Assumption about target users, e.g., "Library consumers are integrating from
  Apple-platform apps or services with URLSession available"]
- [Assumption about scope boundaries, e.g., "The feature extends the existing
  SPM library rather than creating a new target"]
- [Assumption about data/environment, e.g., "Tests use mocks or fixtures rather
  than live network services"]
- [Assumption about documentation/localization, e.g., "English documentation and
  default localized strings are updated in the same change"]
