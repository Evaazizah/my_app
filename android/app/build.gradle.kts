plugins {
    id("com.android.application") // Plugin inti untuk aplikasi Android
    id("kotlin-android")          // Plugin untuk dukungan Kotlin
    id("dev.flutter.flutter-gradle-plugin") // Plugin khusus untuk Flutter
    id("com.google.gms.google-services")
}


android {
    namespace = "com.example.trenix" // Namespace aplikasi Anda
    compileSdk = 35 // Mengatur compileSdk ke versi 35, sesuai kebutuhan plugin

    ndkVersion = "27.0.12077973" // Versi NDK yang Anda tentukan

    defaultConfig {
        applicationId = "com.example.trenix" // ID aplikasi Anda
        minSdk = 23 // Versi Android minimum yang didukung
        targetSdk = 35 // Versi Android target (sesuai compileSdk)
        versionCode = 1 // Kode versi aplikasi
        versionName = "1.0" // Nama versi aplikasi
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11 // Kompatibilitas sumber Java 11
        targetCompatibility = JavaVersion.VERSION_11 // Kompatibilitas target Java 11
        isCoreLibraryDesugaringEnabled = true // WAJIB untuk fitur desugaring Java 8+
    }

    kotlinOptions {
        jvmTarget = "11" // Target JVM untuk Kotlin ke Java 11
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true     // Mengaktifkan ProGuard/R8 untuk mengurangi ukuran kode
            isShrinkResources = true   // Mengaktifkan penghapusan resource yang tidak terpakai
            signingConfig = signingConfigs.getByName("debug") // Ini biasanya diganti dengan konfigurasi penandatanganan untuk rilis produksi
        }
        // Anda bisa menambahkan konfigurasi untuk build 'debug' di sini jika diperlukan,
        // meskipun biasanya isMinifyEnabled dan isShrinkResources disetel 'false'
        // untuk mempercepat proses build saat pengembangan.
        // getByName("debug") {
        //     isMinifyEnabled = false
        //     isShrinkResources = false
        //     signingConfig = signingConfigs.getByName("debug")
        // }
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.." 
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7") 
    // Memperbarui versi desugar_jdk_libs ke 2.1.4 atau lebih tinggi,
    // sesuai kebutuhan plugin seperti flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
