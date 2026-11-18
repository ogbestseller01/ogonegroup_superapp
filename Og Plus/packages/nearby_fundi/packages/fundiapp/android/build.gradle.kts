allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }

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
                ext.compileSdkVersion(37)   // was 36 — required by permission_handler 14.x
            }
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