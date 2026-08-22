import godot.annotation.processor.classgraph.AnnotationProcessingMode
import godot.gradle.GodotLanguage

plugins {
    id("com.utopia-rise.godot-kotlin-jvm") version "0.17.1-4.7.2"
}

repositories {
    mavenCentral()
}

dependencies {
	implementation("org.apache.commons:commons-compress:1.28.0")
}

godot {
    // --------- Setup ---------
    languages.set(setOf(GodotLanguage.KOTLIN))
    annotationProcessingMode.set(AnnotationProcessingMode.Inferred)
    godotProjectDirectory.set(file(".")) // only change this if the Godot project root is not this Gradle project directory
    // Enable to mark this Gradle project as a reusable library rather than a runnable Godot project.
    //isLibrary.set(true)

    // Enable coroutines integration with Godot signal/lifecycle callbacks.
    isGodotCoroutinesEnabled.set(true)

    // --------- Toolchain ---------
    //javaVersion.set(17)
    //kotlinVersion.set("2.3.20")
    //scalaVersion.set("3.6.3")
}

tasks.generateEmbeddedJre.configure {
    modules = arrayOf(
	    "java.base",
	    "java.logging",
		"jdk.jdwp.agent"
    )
}