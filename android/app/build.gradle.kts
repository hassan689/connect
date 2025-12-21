plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.connect"
    compileSdk = 36
    // ndkVersion = "27.0.12077973" // Commented out to use default NDK

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.connect"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // Fix for Windows paths with spaces - use build directory in GRADLE_USER_HOME if available
    val gradleUserHome = System.getenv("GRADLE_USER_HOME")
    val buildDirPath = if (gradleUserHome != null && gradleUserHome.isNotEmpty()) {
        // Use a build directory in GRADLE_USER_HOME (path without spaces)
        file("$gradleUserHome/build/${project.name}")
    } else {
        // Fallback to relative build directory
        file("build")
    }
    buildDir = buildDirPath
}

flutter {
    source = "../.."
    // Override Flutter's build directory to avoid path-with-spaces issues
    // Use GRADLE_USER_HOME if available (path without spaces)
    val gradleUserHome = System.getenv("GRADLE_USER_HOME")
    if (gradleUserHome != null && gradleUserHome.isNotEmpty()) {
        // Set Flutter's build directory to a location without spaces
        val flutterBuildDir = file("$gradleUserHome/flutter-build/${project.name}")
        // This will be used by Flutter's build process
        project.extensions.extraProperties.set("flutter.buildDir", flutterBuildDir.absolutePath)
    }
}

// Fix for Windows paths with spaces - configure build directory
afterEvaluate {
    tasks.withType<JavaCompile>().configureEach {
        options.encoding = "UTF-8"
    }
    
    // Override Flutter's compileFlutterBuildDebug task to use a path without spaces
    val gradleUserHome = System.getenv("GRADLE_USER_HOME")
    if (gradleUserHome != null && gradleUserHome.isNotEmpty()) {
        // Create Flutter intermediates directory in GRADLE_USER_HOME (no spaces)
        val flutterIntermediatesDir = file("$gradleUserHome/flutter-build/${project.name}/intermediates/flutter/debug")
        flutterIntermediatesDir.mkdirs()
        
        // Override the Flutter build task's output directory by modifying the task inputs/outputs
        // Only configure if task exists (for debug builds)
        tasks.findByName("compileFlutterBuildDebug")?.let { task ->
            task.doFirst {
                // Pre-create the directory Flutter expects but in a location without spaces
                val expectedPath = file("${project.buildDir}/intermediates/flutter/debug")
                val actualPath = file("$gradleUserHome/flutter-build/${project.name}/intermediates/flutter/debug")
                
                // Create both directories
                actualPath.mkdirs()
                
                // Create a symlink/junction from expected path to actual path if possible
                try {
                    if (!expectedPath.exists() && expectedPath.parentFile.exists()) {
                        // Try to create the directory structure
                        expectedPath.parentFile.mkdirs()
                    }
                } catch (e: Exception) {
                    println("Warning: Could not create expected directory structure: $e")
                }
            }
        }
    }
    
    // Copy APK to Flutter's expected location to fix path parsing issues
    val copyApkTask = tasks.register("copyApkToFlutterLocation") {
        doLast {
            val debugApk = file("${project.buildDir}/outputs/apk/debug/app-debug.apk")
            val releaseApk = file("${project.buildDir}/outputs/apk/release/app-release.apk")
            
            // Flutter's expected location (original project directory)
            val flutterApkDir = file("${rootProject.projectDir}/../build/app/outputs/flutter-apk")
            flutterApkDir.mkdirs()
            
            // Also copy to GRADLE_USER_HOME if available (for backup/alternative location)
            val gradleUserHome = System.getenv("GRADLE_USER_HOME")
            val altApkDir = if (gradleUserHome != null && gradleUserHome.isNotEmpty()) {
                file("$gradleUserHome/flutter-apk")
            } else {
                null
            }
            altApkDir?.mkdirs()
            
            if (debugApk.exists()) {
                // Copy to Flutter's expected location (required for Flutter to find it)
                val flutterDebugApk = file("${flutterApkDir}/app-debug.apk")
                if (flutterDebugApk.exists()) {
                    flutterDebugApk.delete()
                }
                debugApk.copyTo(flutterDebugApk, overwrite = true)
                println("✓ Copied debug APK to: ${flutterDebugApk.absolutePath}")
                
                // Also copy to alternative location if available
                altApkDir?.let {
                    val altDebugApk = file("${it}/app-debug.apk")
                    if (altDebugApk.exists()) {
                        altDebugApk.delete()
                    }
                    debugApk.copyTo(altDebugApk, overwrite = true)
                    println("✓ Also copied to: ${altDebugApk.absolutePath}")
                }
            }
            
            if (releaseApk.exists()) {
                val flutterReleaseApk = file("${flutterApkDir}/app-release.apk")
                if (flutterReleaseApk.exists()) {
                    flutterReleaseApk.delete()
                }
                releaseApk.copyTo(flutterReleaseApk, overwrite = true)
                println("✓ Copied release APK to: ${flutterReleaseApk.absolutePath}")
                
                altApkDir?.let {
                    val altReleaseApk = file("${it}/app-release.apk")
                    if (altReleaseApk.exists()) {
                        altReleaseApk.delete()
                    }
                    releaseApk.copyTo(altReleaseApk, overwrite = true)
                    println("✓ Also copied to: ${altReleaseApk.absolutePath}")
                }
            }
        }
    }
    
    // Make copy task run after assemble tasks
    tasks.named("assembleDebug").configure {
        finalizedBy(copyApkTask)
    }
    
    tasks.named("assembleRelease").configure {
        finalizedBy(copyApkTask)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

