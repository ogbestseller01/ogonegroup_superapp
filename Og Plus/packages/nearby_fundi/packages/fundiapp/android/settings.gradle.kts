pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val sdkPath = properties.getProperty("flutter.sdk")
        require(sdkPath != null) { "flutter.sdk not set in local.properties" }
        sdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven { url = uri("https://jitpack.io") }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.10" apply false
}

include(":app")

subprojects {
    project.beforeEvaluate {
        if (project.name == "flutter_inappwebview_android") {
            val buildGradleFile = project.file("build.gradle")
            if (buildGradleFile.exists()) {
                val content = buildGradleFile.readText()
                if (content.contains("proguard-android.txt")) {
                    val updatedContent = content.replace(
                        "proguard-android.txt",
                        "proguard-android-optimize.txt"
                    )
                    buildGradleFile.writeText(updatedContent)
                }
            }
        }
    }

    afterEvaluate {
        extensions.findByName("android")?.let { android ->
            val ext = android as com.android.build.gradle.BaseExtension
            ext.compileSdkVersion(37) // Required by permission_handler 14.x
        }
    }
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