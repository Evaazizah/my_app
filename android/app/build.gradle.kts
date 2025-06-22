apply plugin: 'com.android.application'

android {
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.example.trenix"
        minSdkVersion 23
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
        
        // Khusus fitur track & alert
        multiDexEnabled true
        manifestPlaceholders = [
            backgroundLocationPermission: "Allow ${appName} to access your location in background?"
        ]
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
            signingConfig signingConfigs.debug
        }
    }

    // Untuk handle library native
    packagingOptions {
        exclude 'META-INF/*'
    }
}

dependencies {
    implementation project(':flutter')
    // Dependensi khusus track & alert
    implementation 'androidx.work:work-runtime:2.7.1' // Untuk background service
    implementation 'com.google.android.gms:play-services-location:21.0.1' // Untuk lokasi
}