# Build and Run

## Generate the Xcode project

```bash
xcodegen generate
```

The repository pins a post-generation compatibility rewrite for Xcode 15.4, so rerunning `xcodegen generate` will automatically normalize the generated `project.pbxproj` away from object version `77`.

## Build the macOS app shell

```bash
xcodebuild -project phas.xcodeproj -scheme phas -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

## Run unit tests

```bash
xcodebuild -project phas.xcodeproj -scheme phas -destination 'platform=macOS' test CODE_SIGNING_ALLOWED=NO
```

## Run the verification matrix

```bash
ruby scripts/verify_matrix
```

Target a specific lane when you only need a narrower regression pass:

```bash
ruby scripts/verify_matrix smoke
ruby scripts/verify_matrix runtime recovery
```

## Launch from Xcode

Open `phas.xcodeproj`, select the `phas` scheme, then run the app on `My Mac`.
