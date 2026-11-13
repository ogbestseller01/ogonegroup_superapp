allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // ⚠️ DO NOT force compileSdkVersion(37) on every subproject — it will
    // break plugins that haven't been updated for API 37 (which doesn't
    // exist yet). Let each plugin use its own compileSdk.
}

// Declare the Google services plugin once (no `apply` here).
// The `app` module applies it via `id("com.google.gms.google-services")`.
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}