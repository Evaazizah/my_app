plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.trenix"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.trenix"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true

        manifestPlaceholders["backgroundLocationPermission"] = "Allow Trenix to access your location in background?"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    packagingOptions {
        resources {
            excludes += "META-INF/*"
        }
    }
}

dependencies {
    implementation(project(":flutter"))

    // Untuk core desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Untuk fitur Track & Alert
    implementation("androidx.work:work-runtime:2.7.1")
    implementation("com.google.android.gms:play-services-location:21.0.1")
}
