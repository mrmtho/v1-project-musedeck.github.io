# Studio Dashboard IA & Navigation Redesign Specification

## Objective

Redesign the Studio dashboard to support a larger and growing feature set by introducing a clear workflow-based information architecture.

The dashboard should be organized around two categories of work:

### 1. Project Work

Activities that are tied to a specific creative project.

* Create
* Produce
* Release

### 2. Continuous Work

Activities that continue indefinitely regardless of project status.

* Messages
* Calendar
* Team
* Earnings
* Catalog
* Industry

The goal is to make Studio feel like a complete operating system for music creators while maintaining simplicity and scalability.

---

# Global Layout

## Top Navigation Bar

### Left

* Studio Logo

### Center / Main Navigation

Two visual groups of tabs:

#### PROJECT

Create | Produce | Release

Visual treatment:

* Yellow underline beneath active tab
* Group label beneath tabs:

  * PROJECT

#### CONTINUOUS

Messages | Calendar | Team | Earnings | Catalog | Industry

Visual treatment:

* Same tab styling
* Group label beneath tabs:

  * CONTINUOUS

### Right

Existing profile/account controls remain unchanged.

---

# Contextual Left Sidebar

The left sidebar becomes dynamic.

The contents of the sidebar should change based on the selected top-level tab.

Example:

When user selects Create:

Sidebar shows Create-specific tools.

When user selects Produce:

Sidebar shows Produce-specific tools.

When user selects Earnings:

Sidebar shows Earnings-specific tools.

This keeps the interface clean while allowing significant future expansion.

---

# CREATE TAB

Purpose:

Song ideation, songwriting, planning and creative development.

The Create workspace becomes the home of the Song Sandbox.

## Sidebar Structure

### Song Sandbox

Contains:

* Voice Notes
* Lyrics
* Chords
* Mood Board
* Tasks
* Notes

### AI Ideas

New section.

Purpose:

Store and organize ideas generated from connected AI tools.

Examples:

* AI lyric ideas
* AI song concepts
* AI melody suggestions
* AI arrangement suggestions

Design Requirement:

Future-ready integration framework for third-party AI music tools.

Do not hardcode to any single provider.

### Score & Lead Sheet Editor

New section.

Purpose:

Allow users to write and edit:

* Musical notation
* Lead sheets
* Chord charts

Desired experience:

Comparable to embedded notation software.

Reference inspiration:

* Delius
* MuseScore
* Sibelius

Future Requirement:

Support export/import of common notation formats.

---

# PRODUCE TAB

Purpose:

Transform ideas into finished recordings.

Existing mixer and arrangement functionality moves here.

## Layout

### Left Panel: Source Selection

New panel.

Users choose what material they want to produce.

Sources:

#### Song Sandbox

Pull ideas from Create.

#### Vault

Unproduced ideas and archived material.

Examples:

* Old demos
* Unfinished songs
* Archived sketches

#### Released Catalog

Previously released songs.

Use cases:

* Remixes
* Remasters
* Alternate versions
* Acoustic versions

#### Additional Sources

Leave architecture open for future additions.

Examples:

* External uploads
* Collaborator submissions
* Sample libraries

---

### Main Workspace

Contains existing:

* Arrangement Timeline
* Mixer Console
* Production Workspace

Maintain current functionality.

---

# RELEASE TAB

Purpose:

Guide creators through a professional release process.

Primary feature:

Release Readiness Checklist.

## Sidebar

### Release Checklist

Comprehensive checklist system.

Users can mark items complete.

Examples:

#### Legal

* Split sheet signed
* Contributor agreements completed
* Sample clearances completed

#### Distribution

* Metadata completed
* ISRC assigned
* Distributor selected

#### Marketing

* Cover artwork approved
* Press photos ready
* Bio updated

#### Content

* Video reels created
* Teaser clips exported
* Behind-the-scenes content prepared

#### Launch

* Release date scheduled
* Pre-save campaign active
* Announcement posts prepared

#### Post Release

* Analytics review
* Royalty tracking enabled
* Content repurposing plan

Design Requirement:

Checklist architecture must support custom templates in future versions.

---

# MESSAGES TAB

Purpose:

Creator communications hub.

Features:

* Direct messages
* Collaboration conversations
* Team communication
* Notifications

Future-ready for:

* Artist-to-artist messaging
* Manager communication
* Label communication

---

# CALENDAR TAB

Purpose:

Scheduling and planning.

Use existing calendar functionality.

Future support:

* Releases
* Sessions
* Meetings
* Content schedules
* Touring events

---

# TEAM TAB

Purpose:

Relationship and team management.

Entities:

* Band members
* Managers
* Assistants
* Producers
* Engineers
* Songwriters
* Publicists
* Labels

Potential future functionality:

* Permissions
* Roles
* Shared workspaces
* Task assignment

---

# EARNINGS TAB

Purpose:

Financial operating system for creators.

Target:

Self-managed artists and music professionals.

## Sidebar

### Income

Track:

* Streaming revenue
* Performance income
* Merchandise
* Licensing
* Publishing

### Expenses

Track:

* Studio costs
* Marketing spend
* Equipment
* Travel
* Contractors

### Financial Overview

Provide:

* Net earnings
* Monthly summaries
* Cashflow overview
* Revenue trends

Future roadmap:

* Royalty reconciliation
* Tax preparation support
* Budget planning
* Forecasting

---

# CATALOG TAB

Purpose:

Manage released music assets.

Current Scope:

Released music library.

Features:

* Songs
* Albums
* Singles
* EPs

Future roadmap:

* Asset management
* Metadata management
* Rights management
* Version management
* Master file storage

---

# INDUSTRY TAB

Purpose:

Industry intelligence and opportunities.

Examples:

* Music industry news
* Trends
* Opportunities
* Funding programs
* Competitions
* Playlist opportunities
* Sync opportunities

Design as an extensible discovery hub.

---

# Design Principles

## Workflow First

Navigation should mirror the actual music creation journey:

Create → Produce → Release

Everything else supports the creator's career.

## Contextual Complexity

Only show tools relevant to the current tab.

Avoid overwhelming users.

## Future Scalability

All sidebar structures should be data-driven.

New sections should be addable without redesigning navigation.

## Creator Operating System

The long-term vision is:

Studio should become the central operating system for independent music creators.

Not merely a DAW.

Not merely a project manager.

Not merely a release tool.

A complete creator platform that manages the entire lifecycle of music creation, release, collaboration and business operations.
