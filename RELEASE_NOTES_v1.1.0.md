# Kite for macOS v1.1.0

macOS only. KiteWin for Windows is not part of this release and stays at v1.0.0.

## Read first
- **Intel (`x86_64`) build only.** No Apple Silicon build.
- **Requires macOS 26 or later.**
- **Not notarized.** The first launch is blocked by Gatekeeper. Right-click the app and choose Open, or run `xattr -dr com.apple.quarantine /Applications/Kite.app`.
- The v1.0.0 page and README called the build "Universal" and "signed". That was wrong; v1.1.0 states the facts above.

## AI translator and architect chat
- **Fixed the cause of canned answers.** The default model `gemini-2.5-flash` returns 404 for current keys, and the app silently showed an offline template. The default is now `gemini-3.5-flash`.
- **Busy servers no longer break answers.** On 503, 429 or 404 the app retries and moves to other models. A model name Google has retired is replaced by the default.
- **Offline answers are labelled.** Without a key, or when the model fails, the text says it is a template and not an AI answer.
- **Streaming.** Answers appear as they are generated; if the stream breaks, the part received is kept.
- **Faster short answers.** Chat and the Brief, Actions and Targeted modes use a short deliberation.
- **Modes differ.** Plan, Stitch, Targeted, Brief and Actions now ask the model for different artifacts and use your chosen skills and style tokens.
- **Interview.** Before Plan or Stitch the model asks 2-3 questions about your idea; the answers become explicit decisions in the plan. It can be switched off in Settings, AI & Models.
- **Chat knows your work.** It sees your ideas, the open idea and the canvas, keeps its history between launches, and has verified facts about how Kite and KiteWin sync.

## Search
- Ranked, tokenized search over ideas and the skills catalog, with plugin ranking and highlighted matches.

## Canvas
- Dark canvas with a graphite background. The "Link" button is readable in dark mode.

## Also added
- Screen Snip with Apple Vision text recognition in the quick capture window, and Scaffolding 2.0 for new projects. Both build and compile, but neither was exercised by hand before this release.

## Known limits
- The interview panel and chat history loading were not looked at on screen before release.
- Search highlighting was not checked on screen.

## Checksums (SHA-256)
```text
8bb8f5ae06ea3e208df1790dbaa45a07a92019b7ee7834a5887f20d98948fb58  Kite-1.1.0-macOS.dmg
2136ab68793c1f17cd956c26d2c105c1b9f1673c596c7afbd56f0618e63df3e4  Kite-1.1.0-macOS.zip
```
