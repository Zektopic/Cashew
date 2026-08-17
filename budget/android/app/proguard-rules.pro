# R8 rules for the release build.
#
# Flutter's Gradle plugin picks this file up automatically when it exists --
# see FlutterPlugin.kt, "Optionally adds custom Proguard rules as needed from
# android/app/proguard-rules.pro". No build.gradle change is needed.
#
# Without these, `flutter build apk --release` fails outright at
# :app:minifyReleaseWithR8 with "Compilation failed to complete", preceded by a
# list of "Missing class androidx.window..." lines. The rules below are exactly
# what AGP writes to build/app/outputs/mapping/release/missing_rules.txt.
#
# Why the classes are genuinely absent, rather than a dependency being wrong:
# androidx.window's Sidecar and Extensions APIs are the OEM-implemented
# foldable/multi-window interfaces. They ship in the device's system image, not
# in the app, so androidx.window binds to them reflectively and declares them
# compileOnly. R8 sees the references, cannot resolve them, and refuses to
# continue unless told these absences are expected. They are: on a device
# without the extension, androidx.window falls back at runtime.
#
# app/build.gradle pulls androidx.window in directly (window + window-java).

-dontwarn androidx.window.extensions.WindowExtensions
-dontwarn androidx.window.extensions.WindowExtensionsProvider
-dontwarn androidx.window.extensions.area.ExtensionWindowAreaPresentation
-dontwarn androidx.window.extensions.layout.DisplayFeature
-dontwarn androidx.window.extensions.layout.FoldingFeature
-dontwarn androidx.window.extensions.layout.WindowLayoutComponent
-dontwarn androidx.window.extensions.layout.WindowLayoutInfo
-dontwarn androidx.window.sidecar.SidecarDeviceState
-dontwarn androidx.window.sidecar.SidecarDisplayFeature
-dontwarn androidx.window.sidecar.SidecarInterface$SidecarCallback
-dontwarn androidx.window.sidecar.SidecarInterface
-dontwarn androidx.window.sidecar.SidecarProvider
-dontwarn androidx.window.sidecar.SidecarWindowLayoutInfo
