# CTOD Presentation Mode Audio

Presentation Mode is built to support two fixed professional narrators plus a browser-based expressive fallback.

## Voice roles

- **Executive Strategist**: lower, deliberate, authoritative. Used for the problem, manager impact, enterprise intelligence, data/succession, and final vision.
- **Product Guide**: warmer, brighter, conversational. Used for the system explanation, employee journey, location view, career model, and configurability.

## Production audio filenames

Add final mastered MP3 files to this folder using these exact names:

1. `01-problem.mp3`
2. `02-system.mp3`
3. `03-employee.mp3`
4. `04-manager.mp3`
5. `05-location.mp3`
6. `06-enterprise.mp3`
7. `07-data.mp3`
8. `08-model.mp3`
9. `09-organizations.mp3`
10. `10-vision.mp3`

The presentation engine checks for the MP3 before each chapter. If the file exists, it plays the mastered recording. If it does not exist, CTOD automatically falls back to the dual-voice browser narration engine.

## Mastering target

- Clean corporate narration, natural and confident rather than announcer-heavy.
- Consistent loudness across both speakers.
- 250–500 ms of clean head/tail room per chapter.
- No baked-in music. Music/ambience should be controlled separately by Presentation Mode so it can be adjusted or disabled without regenerating narration.
- Export MP3 at 192 kbps or higher.

## Presentation behavior

Playback begins at Chapter 1, switches narrator by chapter, automatically advances, and ends on the CTOD vision screen ready for executive questions. The final fixed audio files will produce identical narration on every device and browser.
