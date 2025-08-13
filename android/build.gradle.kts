// buildscript block not needed; pluginManagement in settings.gradle.kts provides repositories and plugins

allprojects {
    // Do not add repositories here; settings.gradle.kts defines them via dependencyResolutionManagement
}

// Ensure all subprojects use available ffmpeg-kit artifacts from Maven Central
subprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.arthenica" && requested.name.startsWith("ffmpeg-kit")) {
                useVersion("6.0-2.LTS")
                because("Ensure Maven Central resolves ffmpeg-kit artifacts")
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // Avoid forcing NDK installation for modules that don't need it
    afterEvaluate {
        extensions.findByName("android")?.let {
            val androidExtension = it
            try {
                val ndkVersionProperty = androidExtension.javaClass.methods.find { m -> m.name == "setNdkVersion" }
                // If present, clear ndkVersion to let AGP choose or skip
                ndkVersionProperty?.invoke(androidExtension, null)
            } catch (_: Exception) { }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
