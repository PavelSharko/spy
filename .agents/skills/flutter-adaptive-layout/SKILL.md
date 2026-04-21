---
name: flutter-adaptive-layout
description: Create and refactor Flutter UI code to follow fluid adaptive layout and responsive framework principles. Use this skill whenever the user asks to build or refactor a Flutter screen, widget, or layout. Ensures the UI scales perfectly across mobile and tablet sizes using layout factors instead of hardcoded sizes.
---

# Flutter Adaptive Layout & Responsive UI Skill

This skill enforces best practices for creating responsive and fluid Flutter UIs based on industrial standards and >5k stars GitHub repositories. 

## Core Principles

1. **Never use hardcoded pixel sizes.** All dimensions (width, height, padding, margins) must be calculated using factors of the screen size or constrained dynamically.
2. **Fluid Adaptive Layout:** The UI must comfortably breathe across small screens (Android SE) and large screens (tablets/iPad). 
3. **Safe Areas:** The root element of a screen must always be wrapped in `SafeArea`.
4. **Context Extensions:** Use the `ContextExtensions` (e.g. `context.screenHeight`, `context.screenWidth`, `context.topPadding5`) to write clean and concise dimension calculations.

## Required Extensions

Always ensure `lib/utils/context_extensions.dart` is imported when building layouts. 
Example usage: `SizedBox(height: context.topPadding5)` or `padding: EdgeInsets.symmetric(horizontal: context.horizontalMargin)`.

## UI Architecture Rules

### 1. Tablet & Large Screen Control
- **Max Width Constraints**: UI elements must not stretch to 100% width on an iPad. Wrap the main content (columns, lists, texts) in a `Center(child: ConstrainedBox(maxWidth: 800, child: ...))` to preserve symmetry and mobile-like elegance.

### 2. Standardized Top Padding
- **Universal SafeArea Header**: After the `SafeArea`, always apply a uniform relative top padding. Do NOT use `SizedBox(height: 30)`. Use `SizedBox(height: context.topPadding5)` or similar factors.

### 3. Overflow Prevention
- **Text Scaling**: Always protect `Text` widgets from overflowing. Use `FittedBox(fit: BoxFit.scaleDown)`, `Flexible`, or `Expanded` where the size can narrow.
- **Scrollable Dynamic Areas**: The dynamic central parts of screens should be wrapped in `Expanded(child: SingleChildScrollView(...))` or use flexible `Spacer`s so that bottom action buttons are always pushed to the safe bottom zone.

### 4. Banned Practices
- **No Hardcoded Positions**: NEVER use `Transform.translate(offset: Offset(0, 100))` or `Positioned` with fixed large pixels to center items. Use `Spacer()`, `Expanded`, and `MainAxisAlignment.center` for organic spatial distribution.
- **No Fixed Aspect Ratios**: Avoid `childAspectRatio: 2.2` in `GridView`. Screens have different aspect ratios. Calculate ratios dynamically using `LayoutBuilder`, or use `Wrap` and `Flexible`.

### 5. Ad Banner Placeholders
- **Banner Logic**: Respect conditional banner logic `if (!subscribe_payed) BannerWidget()`. Banners must always be pinned to the bottom of the screen (under all action buttons) and never overlap with scrolling content.

## Generating Pages from Scratch

When asked to create a new page based on business requirements:
1. Understand the goal and read necessary project data models.
2. Draft the UI using `SafeArea`, `Center(child: ConstrainedBox(maxWidth: 600))`, and `ContextExtensions`.
3. Build the content organically with `Expanded`, `SingleChildScrollView`, and factor-based padding.
4. Ensure all action buttons are protected at the bottom.
5. If there's a conditional ad banner (`subscribe_payed`), place it strictly at the bottom.
