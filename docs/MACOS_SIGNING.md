# macOS release signing

Public macOS releases require an active Apple Developer Program membership, a
`Developer ID Application` certificate, and Apple notarization credentials.
The GitHub Actions release job fails closed when any required credential is
missing; ordinary `main` builds remain ad-hoc CI artifacts.

Configure these GitHub repository secrets:

- `MACOS_CERTIFICATE_BASE64`: base64 text of the exported Developer ID
  certificate and private key (`.p12`). On macOS, generate it with
  `base64 -i DeveloperIDApplication.p12 | pbcopy`.
- `MACOS_CERTIFICATE_PASSWORD`: password chosen while exporting the `.p12`.
- `MACOS_KEYCHAIN_PASSWORD`: strong temporary-keychain password used by the
  GitHub runner.
- `APPLE_DEVELOPER_ID_APPLICATION`: full certificate name, normally
  `Developer ID Application: Name (TEAMID)`.
- `APPLE_ID`: Apple ID belonging to the developer team.
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password created at
  appleid.apple.com. Do not use the normal Apple ID password.
- `APPLE_TEAM_ID`: ten-character Apple Developer Team ID.

Add them under **Repository Settings → Secrets and variables → Actions**. Never
commit the certificate, private key, passwords, or their base64 representation.

For a tag matching `rc-flight-lab-v*`, the workflow imports the certificate
into a temporary keychain, signs with hardened runtime and a secure timestamp,
submits the app with `notarytool`, staples the accepted ticket, and verifies the
finished app using both `codesign` and Gatekeeper's `spctl`.
