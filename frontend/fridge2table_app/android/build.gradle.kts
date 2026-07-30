import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (tflite_flutter, at least) pin their own Java
// sourceCompatibility/targetCompatibility to an older version (11) in
// their own android/build.gradle without setting a matching Kotlin
// jvmTarget -- so their Kotlin compile task falls back to whatever JDK is
// running Gradle (17, from Android Studio's bundled JDK on this machine),
// producing "Inconsistent JVM-target compatibility detected for tasks
// 'compileReleaseJavaWithJavac' (11) and 'compileReleaseKotlin' (17)"
// after upgrading Flutter/AGP/Kotlin. Editing the plugin's own copy under
// pub-cache isn't an option (it doesn't survive a `flutter pub get`, and
// isn't shared with anyone else building this project).
//
// Rather than forcing every module's Java target to one hardcoded value
// (tried that -- AGP throws "sourceCompatibility has been finalized" once
// a module's own build script already set it, as tflite_flutter's does),
// this only ever *reads* each module's own already-declared Java target
// and points that same module's Kotlin task at it -- :app stays Java 17 /
// Kotlin 17 (already matched, untouched), tflite_flutter becomes Java 11
// / Kotlin 11 (matched, instead of drifting to whatever JDK runs Gradle).
// Read-only means no finalization conflict is possible.
subprojects {
    tasks.withType<KotlinCompile>().configureEach {
        val targetCompatibility = project.extensions
            .findByType(com.android.build.gradle.BaseExtension::class.java)
            ?.compileOptions
            ?.targetCompatibility
        if (targetCompatibility != null) {
            compilerOptions {
                jvmTarget.set(JvmTarget.fromTarget(targetCompatibility.toString()))
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
