import com.android.build.gradle.BaseExtension

fun Project.androidCompileSdk(): Int? =
    (extensions.findByName("android") as? BaseExtension)
        ?.compileSdkVersion
        ?.substringAfter("android-")
        ?.toIntOrNull()

allprojects {
    repositories {
        google()
        mavenCentral()
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
// Some Flutter plugins pin a compileSdk older than the app's (flutter_line_sdk pins 33), which
// fails AGP's AAR metadata check. Raise any such plugin to the app's compileSdk. Registered before
// the evaluationDependsOn block below, which eagerly evaluates ":app".
subprojects {
    afterEvaluate {
        val appCompileSdk = project(":app").androidCompileSdk() ?: return@afterEvaluate
        val extension = extensions.findByName("android") as? BaseExtension ?: return@afterEvaluate
        val current = extension.compileSdkVersion?.substringAfter("android-")?.toIntOrNull()
        if (current != null && current < appCompileSdk) {
            extension.compileSdkVersion(appCompileSdk)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
