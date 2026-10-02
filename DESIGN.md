---
version: alpha
name: Paoly
description: A Thai and English personal finance notebook with a virtual dog.
colors:
  primary: '#7C6FC4'
  primaryDark: '#594C9A'
  background: '#F8F6FF'
  lightPurple: '#EFE9FF'
  textDark: '#1A192E'
  textMuted: '#8F8BA2'
  border: '#EAE7F4'
  expense: '#F06969'
  income: '#4CAF82'
typography:
  body:
    fontFamily: Noto Sans Thai
  numeric:
    fontFamily: Inter
rounded:
  card: 14px
  sheet: 24px
spacing:
  page: 20px
omitted:
  - section: components
    reason: Flutter Material primitives and existing widget implementations own component geometry.
---

# Paoly design context

## Overview

A pocket finance notebook with a dog companion. This is a product interface for recording and reviewing money, with playful expression concentrated in the pet and emoji icons. README and the current UI establish Thai/English language support and THB amounts. Preserve the existing identity during bug fixes; avoid trading legible financial data for game decoration.

Runtime ownership: `lib/theme/app_theme.dart` is canonical for colors. This document mirrors those constants; it does not generate code. Typography, card radii and page padding mirror existing screen widgets. No palette or font redesign is introduced by the audit fixes.

## Colors

Purple denotes primary actions and selection, pale purple denotes surfaces. Income is green and expense red, always accompanied by labels or signs. The implementation currently provides a light theme only. Existing muted text and semantic colors still require a complete contrast audit; this document does not certify accessibility.

## Typography

Use Noto Sans Thai for bilingual content and Inter for numeric amounts. Avoid truncating an amount or forcing Thai names into a single narrow line. Material components supply their default theme typography unless explicitly styled.

## Layout

Preserve the bottom navigation, safe-area layout, scrollable transaction lists and modal entry sheet. Existing page padding is 20 logical pixels. Error recovery must remain visible while the user works; save buttons keep their dimensions when busy.

## Elevation & Depth

Existing finance cards use soft purple shadows. Modal sheets and confirmation dialogs use Material layering; feedback must not shift navigation ownership.

## Shapes

Finance cards commonly use 14-pixel corners. Transaction sheets use 24-pixel top corners. Keep the established rounded controls and emoji icon containers.

## Components

`lib/widgets/transaction_actions.dart` owns shared deletion confirmation, Undo and persistence-error feedback. `AddTransactionSheet` owns entry validation and the localized Material date picker. Both finance list screens use the same deletion flow. See `UX-CONTRACT.md` for behavior.

## Do's and Don'ts

Keep money and date values reviewable, preserve input after a failed save, and distinguish OCR suggestions from verified values. Do not imply desktop OCR support, guaranteed Thai OCR or guaranteed bank-specific recognition. Do not interpret an empty static audit as an accessibility certification.
