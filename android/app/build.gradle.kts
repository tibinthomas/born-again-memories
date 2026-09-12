import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
// Keep the installed application ID aligned with the Android OAuth client in
// google-services.json. The namespace can change independently of this ID.
val androidApplicationId = "m4memories.surprise.in"
val isReleaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
} else if (isReleaseBuildRequested) {
    throw GradleException(
        "Release signing is not configured. Copy android/key.properties.example " +
            "to android/key.properties and provide the upload-keystore credentials.",
    )
}

// Firebase is initialized from lib/firebase_options.dart. Apply the native
// resource generator when the project-specific Android config is available,
// but do not make local builds fail solely because that uncommitted file is
// absent.
val googleServicesFile = file("google-services.json")
val googleServicesMatchesApplicationId = googleServicesFile.exists() &&
    Regex(
        "\\\"package_name\\\"\\s*:\\s*\\\"${Regex.escape(androidApplicationId)}\\\"",
    ).containsMatchIn(googleServicesFile.readText())

if (googleServicesMatchesApplicationId) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn(
        if (googleServicesFile.exists()) {
            "google-services.json has no client for $androidApplicationId; " +
                "native Google services configuration is disabled"
        } else {
            "google-services.json not found; native Google services configuration is disabled"
        },
    )
}

android {
    namespace = "app.growingmemories.in"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = androidApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appAuthRedirectScheme"] = androidApplicationId
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                val requiredKeys = listOf(
                    "keyAlias",
                    "keyPassword",
                    "storeFile",
                    "storePassword",
                )
                val missingKeys = requiredKeys.filter {
                    keystoreProperties.getProperty(it).isNullOrBlank()
                }
                if (missingKeys.isNotEmpty()) {
                    throw GradleException(
                        "Missing release signing properties: ${missingKeys.joinToString()}",
                    )
                }

                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Never fall back to a debug key for distributable builds.
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
