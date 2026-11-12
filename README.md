# Project Fernet

A premium fictional gaming launcher for iOS, inspired by Fortnite Chapter 2 Season 3.

## Overview

Project Fernet is an unofficial community launcher concept built with SwiftUI. It is **not** affiliated with Epic Games, Inc.

## Features

- **Home** — Cinematic hero screen with flooded island artwork, animated background, server status, announcements and activity feed
- **Download** — Simulated game download with live progress, speed, ETA, pause/resume
- **Library** — Installed game management, version history, game info
- **Item Shop** — Fictional cosmetic shop with featured/daily items, V-Bucks balance, purchase animations
- **Leaderboard** — Top 15 players with sortable columns and podium display
- **Settings** — General, Appearance, Animations, Sound, About

## Design System

Custom design system in `FernetDesignSystem.swift`:
- Midnight black / deep navy / charcoal palette
- Sophisticated pink + muted violet + cyan highlights
- Glass card components
- Cinematic gradients
- Floating particle animations
- Premium typography

## Project Structure

The Swift source files and `Assets.xcassets` are expected at the repository root. XcodeGen configuration is in `project.yml`.

## Requirements

- iOS 16.0+
- Xcode 15+
- Swift 5.0

## Setup

```bash
brew install xcodegen
xcodegen generate
open ProjectFernet.xcodeproj
```

## Disclaimer

This is an unofficial fan-made community launcher concept. Not affiliated with or endorsed by Epic Games, Inc. No actual game files are downloaded.
