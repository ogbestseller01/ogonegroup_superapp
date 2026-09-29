allprojects {
    repositories {
        google()
        mavenCentral()
    }

    subprojects {
        afterEvaluate {
            extensions.findByName("android")?.let { android ->
                val ext = android as com.android.build.gradle.BaseExtension
                ext.compileSdkVersion(37)
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