with open('budget/android/build.gradle', 'r') as f:
    gradle_content = f.read()

# Force AGP version up to 8.9.1 or 8.7.0 (Wait, it says "requires Android Gradle plugin 8.9.1", but I can just force the androidx.browser and core versions back down).
# Actually, the easiest way is to add a build script resolutionStrategy to force older androidx versions or bump AGP.

if "subprojects {" not in gradle_content:
    gradle_content += """
subprojects {
    configurations.all {
        resolutionStrategy {
            force 'androidx.core:core:1.13.1'
            force 'androidx.core:core-ktx:1.13.1'
            force 'androidx.browser:browser:1.8.0'
        }
    }
}
"""
else:
    gradle_content = gradle_content.replace('subprojects {', '''subprojects {
    configurations.all {
        resolutionStrategy {
            force 'androidx.core:core:1.13.1'
            force 'androidx.core:core-ktx:1.13.1'
            force 'androidx.browser:browser:1.8.0'
        }
    }''')

with open('budget/android/build.gradle', 'w') as f:
    f.write(gradle_content)
