// android/build.gradle.kts

import com.android.build.gradle.LibraryExtension
import org.gradle.kotlin.dsl.configure
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    // Only inject a namespace into flutter_bluetooth_serial
    if (project.name == "flutter_bluetooth_serial") {
        pluginManager.withPlugin("com.android.library") {
            extensions.configure<LibraryExtension> {
                // This must match the plugin’s manifest package
                namespace = "io.github.edufolly.flutterbluetoothserial"
            }
        }
    }
}

val newBuildDir: Directory = rootProject
    .layout
    .buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    // Ensure :app is evaluated before other modules
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
