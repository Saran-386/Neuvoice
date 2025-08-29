import org.gradle.api.tasks.Delete
import org.gradle.kotlin.dsl.register
import com.android.build.api.dsl.ApplicationExtension

buildscript {
    val kotlinVersion = "2.1.0"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.12.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

rootProject.layout.buildDirectory.set(rootProject.layout.projectDirectory.dir("../build"))
subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.get().dir(project.name))
}

subprojects {
    project.ext.set("minSdkVersion", 21)
    project.ext.set("kotlin_version", "2.1.0")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
