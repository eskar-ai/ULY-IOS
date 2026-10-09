# Export compliance (encryption)

When uploading the build, App Store Connect asks about encryption.

## Info.plist (already set)

`ITSAppUsesNonExemptEncryption` = **false** in the host app Info.plist.

## Questionnaire answers

| Question | Answer |
|----------|--------|
| Does your app use encryption? | Yes (HTTPS/TLS is exempt; app uses standard iOS APIs) |
| Is it exempt under Category 5 Part 2? | **Yes** — only uses encryption exempt under U.S. EAR |
| Provide documentation annually? | Usually **No** when using only exempt encryption |

The app does **not** implement custom cryptography for user data. The bundled lexicon is static JSON, not encrypted at rest beyond iOS file protection.

If Connect still prompts: choose **No** for non-exempt encryption / standard exempt app path.
