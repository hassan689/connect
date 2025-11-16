allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configure build directory to avoid path issues with spaces
// Use GRADLE_USER_HOME if available (path without spaces), otherwise use relative path
val gradleUserHome = System.getenv("GRADLE_USER_HOME")
val rootBuildDir = if (gradleUserHome != null && gradleUserHome.isNotEmpty()) {
    file("$gradleUserHome/build/${rootProject.name}")
} else {
    file("build")
}
rootProject.layout.buildDirectory.set(rootBuildDir)

subprojects {
    val subBuildDir = if (gradleUserHome != null && gradleUserHome.isNotEmpty()) {
        file("$gradleUserHome/build/${rootProject.name}/${project.name}")
    } else {
        file("${rootProject.layout.buildDirectory.get()}/${project.name}")
    }
    project.layout.buildDirectory.set(subBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
