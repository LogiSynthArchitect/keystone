# Inventory Image Upload Improvement

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve the image upload experience on the BASIC tab (step 1) of the inventory add/edit dialog.

**Architecture:** Single-file change to `inventory_screen.dart` — replace the current image picker row with a richer upload experience showing file size, auto-upload on pick, animated progress, and icon-only controls.

**Tech Stack:** Flutter/Dart, CloudinaryService, ImagePicker

---

## Design

### Current Behavior
- Image picker is a compact row with small 44x44 thumbnail, "PHOTO" label, "Tap to add item photo" text
- File size is not shown
- Upload only happens when user taps "Save" on the final step
- No upload progress indication

### Proposed Behavior — 3 States

**1. Empty State**
- Dashed border drop zone with camera icon centered
- "ADD PHOTO" label + "Tap to select from gallery" subtitle
- Tapping opens image picker (gallery)

**2. Uploading State (auto-starts after pick)**
- 120x120 preview (vs current 44x44) with dim opacity + spinning loader overlay
- Filename displayed
- File size displayed (KB/MB)
- Animated progress bar with percentage
- Cancel icon (✕) to abort upload

**3. Uploaded State**
- 120x120 preview with green success border + checkmark badge
- Filename + file size displayed
- Trash icon (🗑️) to remove uploaded image

### Key Changes
- Upload triggers immediately on image pick (not on form save)
- Icon-only controls (no text buttons)
- File size extraction from `File.lengthSync()`
- `CloudinaryService.uploadMedia()` called at pick time, URL stored in state
- Progress simulation via Timer or stream from upload service
