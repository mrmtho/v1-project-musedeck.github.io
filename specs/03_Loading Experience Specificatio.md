# Studio Loading Experience Specification

## Objective

Replace the default blank white screen shown while Flutter CanvasKit/Web initializes with a branded Studio loading experience.

The loading screen should immediately communicate:

* Music
* Creativity
* AI
* Premium quality

The experience should feel alive and intentional rather than a technical loading state.

---

# Concept

Create a custom loading indicator based on an audio waveform.

The waveform begins as an empty outline and gradually fills with Studio brand color.

The fill animation should resemble neural network activity flowing through the waveform.

Think:

* Audio waveform
* Neural signal propagation
* AI activation
* Energy flowing through music

The animation should communicate:

"Studio is powering up."

---

# User Experience

## Initial State

Immediately on page load:

* Display Studio background color.
* Display centered Studio logo.
* Display waveform beneath logo.
* No white screen should ever be visible.

---

## Animation Sequence

### Phase 1: Outline

Waveform appears as:

* Thin outline
* Low opacity
* Brand-neutral color

State:

Empty.

---

### Phase 2: Neural Activation

Small glowing particles begin moving through the waveform path.

Behavior:

* Travel left → right
* Occasionally branch
* Slight randomization
* Smooth motion

Visual inspiration:

* Neural network firing
* Synapses activating
* Data flowing

---

### Phase 3: Progressive Fill

As particles travel:

The waveform gradually fills.

Fill should:

* Grow from left to right
* Follow waveform shape
* Use Studio accent color

Not a traditional progress bar.

Should feel organic.

Like energy accumulating inside the waveform.

---

### Phase 4: Pulse

When fully filled:

Waveform performs:

* Gentle pulse
* Slight glow
* Breathing effect

This state loops until Flutter finishes initialization.

---

### Phase 5: Transition

When application is ready:

* Fade loading screen out
* Fade application in

Duration:

300–600ms

Avoid sudden disappearance.

---

# Visual Design

## Waveform Style

Modern music-platform aesthetic.

Reference inspiration:

* Professional DAW interfaces
* Audio visualizers
* Neural network diagrams

Shape characteristics:

* Symmetrical
* Clean
* Recognizable as audio waveform

Example shape:

▁▂▃▅▇█▇▅▃▂▁

More refined and vector-based.

---

## Colors

Use Studio brand palette.

Suggested behavior:

Background:

* Dark charcoal / black

Wave Outline:

* Low-opacity gray

Fill:

* Primary Studio yellow

Neural Activity:

* Bright yellow
* Slight glow

Optional:

* Subtle secondary accent color

---

# Animation Details

## Neural Nodes

Create small moving particles.

Properties:

* Circular
* Soft glow
* Multiple concurrent particles

Behavior:

* Move along waveform path
* Vary speed slightly
* Create sense of intelligence

---

## Fill Effect

The waveform should not simply scale.

Instead:

* Reveal color progressively
* Follow waveform geometry
* Appear energized

Preferred techniques:

* Animated gradient mask
* Path clipping
* Custom painter reveal

---

## Pulse State

After 100% fill:

Loop:

* Glow intensity increases
* Glow intensity decreases

Duration:

~1.5 seconds

Repeat indefinitely.

---

# Flutter Implementation Requirements

## Technology

Implement entirely in Flutter.

Preferred approaches:

### CustomPainter

Use:

* CustomPaint
* Path
* PathMetrics

To draw waveform.

---

### AnimationController

Use:

* SingleTickerProviderStateMixin
* AnimationController

For:

* Fill progression
* Neural movement
* Pulse effect

---

### Shader / Gradient Support

Use animated gradients where possible.

Goal:

Premium visual quality.

---

### Performance

Must remain lightweight.

Target:

* 60fps
* Mobile friendly
* Web friendly

Avoid:

* Heavy particle systems
* Excessive repainting

---

# Flutter Web Integration

## Critical Requirement

The loader must appear before Flutter finishes loading.

Implementation should be placed inside:

index.html

Not inside the Flutter widget tree initially.

Reason:

Flutter widgets cannot render until Flutter has loaded.

Current issue:

Users see blank white page.

Goal:

Users see Studio branding instantly.

---

## Recommended Architecture

index.html

Contains:

* Fullscreen loading overlay
* HTML/CSS waveform container

When Flutter initializes:

* Remove loading overlay
* Hand control to Flutter app

Optional:

Recreate identical loader in Flutter so visual language remains consistent throughout the product.

---

# Enhancement Ideas (Optional)

## Dynamic Messages

Rotate subtle messages:

* Initializing Studio...
* Connecting Creative Workspace...
* Preparing Your Catalog...
* Warming Up The Mix Console...
* Syncing Creative Intelligence...

---

## AI Signature Moment

Occasionally:

Neural particles connect with thin lines.

Creates a brief neural network effect.

Reinforces AI-first identity.

---

## Audio-Reactive Illusion

Even without actual audio:

Waveform can subtly fluctuate.

Very small movement.

Makes it feel alive.

---

# Success Criteria

The loading experience should feel like:

* An AI music platform
* A premium creative tool
* A modern operating system for artists

It should eliminate the perception of waiting and instead create the feeling that Studio is intelligently preparing the creator's workspace.
