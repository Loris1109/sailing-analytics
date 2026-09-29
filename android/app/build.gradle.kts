import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.tacktics"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.tacktics"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Nur füllen, wenn key.properties wirklich da ist.
            //
            // Ohne diese Prüfung wirft `as String` auf einem fehlenden
            // Eintrag — und zwar beim KONFIGURIEREN, nicht erst beim Bauen.
            // Damit scheitert jeder Gradle-Task, auch ein Debug-Build: wer
            // das Repo ohne Keystore klont, könnte die App nicht einmal
            // starten. Der Keystore gehört aber bewusst nicht ins Repo.
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = (keystoreProperties["storeFile"] as String).let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Mit Keystore echt signieren, sonst Debug — damit
            // `flutter run --release` auch ohne key.properties läuft.
            //
            // Ein so gebautes Bundle lehnt Play ab, und das ist die richtige
            // Reihenfolge: ein fehlender Keystore fällt beim Hochladen auf,
            // ein kaputter Build fiele schon beim Entwickeln auf.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
