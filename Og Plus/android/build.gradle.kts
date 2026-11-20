import org.gradle.api.Action
import org.gradle.api.Project
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    beforeEvaluate {
        if (project.name == "flutter_inappwebview_android") {
            val buildGradleFile = project.file("build.gradle")
            if (buildGradleFile.exists()) {
                val content = buildGradleFile.readText()
                if (content.contains("proguard-android.txt")) {
                    buildGradleFile.writeText(
                        content.replace("proguard-android.txt", "proguard-android-optimize.txt")
                    )
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")

    val configureAndroid = Action<Project> {
        val androidExtension = extensions.findByName("android") ?: return@Action
        try {
            val current = androidExtension.javaClass
                .getMethod("getCompileSdk")
                .invoke(androidExtension) as? Int

            if (current == null || current < 34) {
                androidExtension.javaClass
                    .getMethod("setCompileSdk", Int::class.javaObjectType)
                    .invoke(androidExtension, 36)
            }
        } catch (e: Exception) {
            logger.warn("compileSdk override failed for ${project.name}: $e")
        }
    }

    if (state.executed) {
        configureAndroid.execute(this)
    } else {
        afterEvaluate(configureAndroid)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}