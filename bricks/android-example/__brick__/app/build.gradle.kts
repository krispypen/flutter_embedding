plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "{{exampleAndroidPackageName}}"
    compileSdk = 36

    defaultConfig {
        applicationId = "{{exampleAndroidPackageName}}"
        minSdk = 24
        targetSdk = 36

        versionCode = (project.findProperty("projVersionCode") as? String)?.toInt() ?: 1
        versionName = (project.findProperty("projVersionName") as? String) ?: "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
    buildFeatures {
        viewBinding = true
    }
}

dependencies {

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.10.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    // Start Flutter dependencies
    debugImplementation("{{{androidPackage}}}:flutter_debug:1.0")
    //add("profileImplementation", "{{{androidPackage}}}:flutter_profile:1.0")
    releaseImplementation("{{{androidPackage}}}:flutter_release:1.0")
    // End Flutter dependencies
}