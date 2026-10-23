allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}   

// --- THE ISAR FIX MUST GO HERE (BEFORE EVALUATION) ---
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            configure<com.android.build.gradle.LibraryExtension> {
                compileSdk = 36
                if (namespace.isNullOrBlank()) {
                    val safeGroup = project.group.toString()
                    namespace = if (safeGroup.isNotBlank()) safeGroup else "com.example.${project.name.replace("-", "_")}"
                }
            }
        }
    }
}
// -----------------------------------------------------

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}