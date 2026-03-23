with open('budget/android/build.gradle', 'r') as f:
    content = f.read()

search = """    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile).configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }"""

replace = """    project.android {
        compileOptions {
            sourceCompatibility JavaVersion.VERSION_17
            targetCompatibility JavaVersion.VERSION_17
        }
    }

    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile).configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }"""

content = content.replace(search, replace)

with open('budget/android/build.gradle', 'w') as f:
    f.write(content)
