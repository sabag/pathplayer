# Implementation Plan: Folder-Based Navidrome Android Client - PathPlayer

This document details the functional requirements, API integration specifics, and a multi-phase development plan for a specialized, folder-centric Android music player. It is structured to serve as context and step-by-step instructions for a coding agent.
the chosen name for the App is PathPlayer.
---

## 1. Core Requirements & Architecture Overview

Unlike mainstream music players that parse metadata tags (Artist, Album, Genre), this application mirrors the physical directory structure of your Navidrome server.

### Key Workflows
1. **Directory-Based Navigation:** Browse music through the exact folder hierarchy defined on your storage backend.
2. **Folder Shuffle Play:** Select any directory containing audio files, load all contents, shuffle the compilation dynamically, and stream immediately.
3. **Fuzzy Search & Direct Play:** Search for individual tracks globally via text phrase and play a specific selection immediately.

### Architectural Layout
Whether implemented in Flutter or Kotlin, the application must adhere to a strict clean-architecture separation:
```
[ UI layer (Compose / Flutter Widgets) ]
                  │
                  ▼
   [ State Management (View Model / Bloc) ]
                  │
                  ▼
    [ Service / API Layer (Subsonic Client) ]
                  │
                  ▼
     [ Audio Player Engine (ExoPlayer / just_audio) ]
```

---

## 2. Navidrome (Subsonic) API Implementation Spec

The coding agent must implement the native Subsonic API token-and-salt authentication routine instead of transmitting plaintext passwords.

### Authentication Formula
For every network request, append the following query parameters:
* `u`: Username
* `v`: `1.16.1` (Minimum target version for OpenSubsonic capabilities)
* `c`: `FolderPlayer` (Client identifier)
* `f`: `json` (Format override)
* `s`: A randomly generated string (Salt), unique per request.
* `t`: An MD5 hex hash of the concatenation of the user's plaintext password and the unique salt: `md5(password + salt)`.

### Target Endpoints

#### A. Directory Browsing
* **Root Navigation:** `GET /rest/getIndexes.view`
  * *Purpose:* Fetches top-level index structures or root directories.
* **Folder Contents:** `GET /rest/getMusicDirectory.view?id=<directory_id>`
  * *Purpose:* Returns an object containing lists of child `directory` nodes (subfolders) and child `child` nodes (playable audio tracks).

#### B. Global Search
* **Fuzzy Text Match:** `GET /rest/search3.view?query=<url_encoded_phrase>&songCount=50`
  * *Purpose:* Returns tracks, albums, and artists matching the phrase. The application should parse the `song` results array exclusively.

#### C. Audio Streaming
* **Binary Stream Route:** `GET /rest/stream.view?id=<track_id>`
  * *Purpose:* Supplies the continuous raw audio stream binary for ingestion by the player engine.

---

## 3. Flutter Implementation Blueprint

### Recommended Package Stack
* **State Management:** `flutter_riverpod` or native `ChangeNotifier` (for absolute simplicity)
* **HTTP Client:** `dio` or `http`
* **Audio Engine:** `just_audio` + `audio_service` (critical for background playback stability)

### Step-by-Step Prompting Sequence for the Agent

#### Phase F1: Setup, Auth, and Root API Connections
> **Prompt for Agent:**
> Create a robust network client class in Dart for our Navidrome application. Implement the Subsonic MD5 token-and-salt authentication logic given a base URL, username, and plaintext password. Write data models mapping the JSON response of `getIndexes.view`. Ensure all requests explicitly append `f=json` and valid token parameters.

#### Phase F2: Folder Directory Navigation UI
> **Prompt for Agent:**
> Build a Flutter page displaying a scrollable list of folders. When a user taps a root folder from `getIndexes`, fetch its content using `getMusicDirectory.view`. Map the JSON output to handle two types of visual items: child directories (render as folder rows with a chevron) and song files (render as audio track rows). If a directory contains audio files, render a prominent "Shuffle Play Folder" button at the top of the interface.

#### Phase F3: Audio Player Engine Engine Setup
> **Prompt for Agent:**
> Integrate the `just_audio` package into our application. Create a playback controller that accepts an array of track IDs found inside the current `getMusicDirectory` view. Convert these IDs into fully qualified `/rest/stream.view` URLs with valid auth parameters. Implement a method that shuffles the array, constructs a `ConcatenatingAudioSource` queue, maps it to the engine, and initiates playback immediately. Ensure basic background audio states are active.

#### Phase F4: Global Phrase Search Screen
> **Prompt for Agent:**
> Implement a dedicated search screen with a basic text input field. When the user types or presses enter, call the `search3.view` endpoint. Parse out the `song` list from the results object and render them in a clean vertical list. Clicking a song should clear the current playback queue, initialize the player with that specific single stream URL, and play it instantly.

---

## 4. Kotlin (Jetpack Compose) Implementation Blueprint

### Recommended Framework Stack
* **UI Architecture:** Jetpack Compose (Declarative UI)
* **Asynchronous Flow:** Kotlin Coroutines & StateFlow
* **Network Client:** Retrofit or Ktor Client with Kotlinx Serialization
* **Audio Engine:** Media3 ExoPlayer (`androidx.media3:media3-exoplayer`)

### Step-by-Step Prompting Sequence for the Agent

#### Phase K1: Core Network Layer and Subsonic Crypto Auth
> **Prompt for Agent:**
> Write a Kotlin repository class using Ktor or Retrofit to interact with a Navidrome server. Implement a helper function that generates an MD5 hash sequence from a random salt string appended to a password string. Create models representing the data payload from the Subsonic `getIndexes.view` API endpoint. Return data safely using standard Kotlin Result wrappers.

#### Phase K2: Compose Folder Browser Interface
> **Prompt for Agent:**
> Create a Jetpack Compose screen for directory-based navigation. Build a `LazyColumn` that loops through items fetched from the server. When an index item is clicked, call the `getMusicDirectory.view` endpoint. Differentiate the UI rows: sub-directories should feature an explicit icon indicator, while tracks should look like standard audio files. Add an item at the top of the column labeled "Shuffle Play Folder" if any audio tracks are present in the list state.

#### Phase K3: Media3 ExoPlayer Service Implementation
> **Prompt for Agent:**
> Implement an Android Media3 ExoPlayer wrapper to stream music directly from the Navidrome backend. Write a playback function that accepts a collection of track records from the active directory. For each record, build a `MediaItem` utilizing the explicit `/rest/stream.view` URL format populated with valid query credentials. Shuffle the sequence inside the controller list, attach the array directly to the ExoPlayer instance, clear any legacy tracks, and invoke `.prepare()` and `.play()`.

#### Phase K4: Dynamic Search Implementation
> **Prompt for Agent:**
> Create a Jetpack Compose Search UI containing a standard OutlinedTextField. Route text queries to the Subsonic `search3.view` route via our repository layer. Filter incoming objects exclusively down to the underlying matching track/song nodes. Render them in an intuitive list layout where a simple click builds an individual isolated `MediaItem` instance, flushes the active playlist array, and immediately triggers an instantaneous playback change.
