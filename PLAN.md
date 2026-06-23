# Implementation Plan: Folder-Based Jellyfin Android Client - PathPlayer

This document details the functional requirements, API integration specifics, and a multi-phase development plan for a specialized, folder-centric Android music player. It is structured to serve as context and step-by-step instructions for a coding agent.
The chosen name for the App is PathPlayer.
---

## 1. Core Requirements & Architecture Overview

Unlike mainstream music players that parse metadata tags (Artist, Album, Genre), this application mirrors the physical directory structure of your Jellyfin media library.

### Key Workflows
1. **Directory-Based Navigation:** Browse music through the exact folder hierarchy defined on your storage backend.
2. **Folder Shuffle Play:** Select any directory containing audio files, load all contents, shuffle the compilation dynamically, and stream immediately.
3. **Fuzzy Search & Direct Play:** Search for individual tracks globally via text phrase and play a specific selection immediately.

### Architectural Layout
The application is built with Flutter and follows a clean-architecture separation:
```
[ UI layer (Flutter Widgets) ]
                   │
                   ▼
    [ State Management (Riverpod) ]
                   │
                   ▼
     [ Service / API Layer (Jellyfin Client) ]
                   │
                   ▼
       [ Audio Player Engine (just_audio + audio_service) ]
```

---

## 2. Jellyfin API Implementation Spec

The coding agent must implement Jellyfin's username/password authentication and use the authenticated user's token for all subsequent requests.

### Authentication Flow
1. The app presents a login screen on first launch. The user enters the Jellyfin server URL, username, and password.
2. On submit, the app calls `POST /Users/AuthenticateByName` with a JSON body containing `Username` and `Pw`.
3. Include an `Authorization` header describing the client in this format:
   ```
   MediaBrowser Client="PathPlayer", Device="<device-name>", DeviceId="<device-id>", Version="1.0.0"
   ```
4. On success, the response contains:
   * `User.Id` — used for per-user endpoints.
   * `AccessToken` — appended as `api_key=<token>` to stream URLs and sent as `Authorization: MediaBrowser Token=<token>` for API calls.
5. Credentials are persisted securely with `flutter_secure_storage` (platform keychain/keystore), so subsequent launches authenticate automatically. A **Logout** action in the browse-screen menu clears the stored credentials and returns to the login screen.

### Target Endpoints

#### A. Directory Browsing
* **Root Navigation:** `GET /Users/{userId}/Items?Recursive=false`
  * *Purpose:* Fetches top-level collection folders (e.g., the music library).
* **Folder Contents:** `GET /Users/{userId}/Items?ParentId=<folder_id>&Recursive=false`
  * *Purpose:* Returns immediate children of a folder. Items with `IsFolder: true` are rendered as subfolders; items with `Type: Audio` are playable tracks.

#### B. Global Search
* **Fuzzy Text Match:** `GET /Users/{userId}/Items?searchTerm=<phrase>&Recursive=true&IncludeItemTypes=Audio,MusicAlbum,MusicArtist`
  * *Purpose:* Returns folders and audio tracks matching the phrase.

#### C. Audio Streaming
* **Binary Stream Route:** `GET /Audio/{track_id}/stream?static=true&api_key=<access_token>`
  * *Purpose:* Supplies the continuous raw audio stream binary for ingestion by the player engine.

---

## 3. Flutter Implementation Blueprint

### Recommended Package Stack
* **State Management:** `flutter_riverpod`
* **HTTP Client:** `dio`
* **Audio Engine:** `just_audio` + `audio_service` (critical for background playback stability)

### Step-by-Step Prompting Sequence for the Agent

#### Phase F1: Setup, Auth, and Root API Connections
> **Prompt for Agent:**
> Create a robust network client class in Dart for our Jellyfin application. Implement the `AuthenticateByName` flow with the required `MediaBrowser` device header. Store the returned `User.Id` and `AccessToken`. Write data models mapping the JSON response of `/Users/{userId}/Items`. Use `Path` to derive the real filesystem name of each item, because Jellyfin's `Name` field is often metadata-derived rather than the actual folder name.

#### Phase F2: Folder Directory Navigation UI
> **Prompt for Agent:**
> Build a Flutter page displaying a scrollable list of folders. When a user taps a root folder, fetch its children using `/Users/{userId}/Items?ParentId=...`. Map the JSON output to handle two types of visual items: child directories (render as folder rows with a chevron) and song files (render as audio track rows). If a directory contains audio files, render a prominent "Shuffle Play Folder" button at the top of the interface.

#### Phase F3: Audio Player Engine Setup
> **Prompt for Agent:**
> Integrate the `just_audio` package into our application. Create a playback controller that accepts an array of audio item IDs found inside the current folder. Convert these IDs into fully qualified `/Audio/{id}/stream?static=true&api_key=...` URLs. Implement a method that shuffles the array, constructs a `ConcatenatingAudioSource` queue, maps it to the engine, and initiates playback immediately. Ensure basic background audio states are active.

#### Phase F4: Global Phrase Search Screen
> **Prompt for Agent:**
> Implement a dedicated search screen with a basic text input field. When the user types or presses enter, call the `/Users/{userId}/Items` search endpoint. Render both folders and audio tracks in a clean vertical list. Clicking a song should clear the current playback queue, initialize the player with that specific single stream URL, and play it instantly.


