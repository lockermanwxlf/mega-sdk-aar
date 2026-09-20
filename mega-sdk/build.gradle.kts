import org.gradle.api.tasks.Exec
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

val generatedRoot = layout.buildDirectory.dir("generated/mega-sdk")

val buildMegaSdk by tasks.registering(Exec::class) {
    group = "build"
    description = "Builds the native MEGA SDK and generates its Java bindings."

    val sdkDirectory = rootProject.layout.projectDirectory.dir("megasdk")
    val buildScript = rootProject.layout.projectDirectory.file("scripts/build-native.sh")

    inputs.file(buildScript)
    inputs.property(
        "androidApiLevel",
        providers.environmentVariable("ANDROID_API_LEVEL").orElse("28")
    )
    inputs.property(
        "buildAbis",
        providers.environmentVariable("BUILD_ABIS").orElse("armeabi-v7a arm64-v8a x86 x86_64")
    )
    inputs.property(
        "buildType",
        providers.environmentVariable("MEGA_BUILD_TYPE").orElse("Release")
    )
    inputs.property(
        "ndkHome",
        providers.environmentVariable("ANDROID_NDK_HOME")
            .orElse(providers.environmentVariable("NDK_ROOT"))
            .orElse("unset")
    )
    inputs.files(
        sdkDirectory.file("CMakeLists.txt"),
        sdkDirectory.file("CMakePresets.json"),
        sdkDirectory.file("vcpkg.json"),
        sdkDirectory.dir("bindings"),
        sdkDirectory.dir("cmake"),
        sdkDirectory.dir("include"),
        sdkDirectory.dir("src"),
        sdkDirectory.dir("third_party")
    )
    outputs.dir(generatedRoot)

    environment("MEGA_OUTPUT_DIR", generatedRoot.get().asFile.absolutePath)
    commandLine(buildScript.asFile.absolutePath)
}

android {
    namespace = "nz.mega.sdk"
    compileSdk = 36

    defaultConfig {
        minSdk = 28
        consumerProguardFiles("consumer-rules.pro")
    }

    sourceSets.named("main") {
        java.srcDir(rootProject.file("megasdk/bindings/java"))
        java.srcDir(generatedRoot.map { it.dir("java") })
        java.exclude("**/MegaApiSwing.java")
        jniLibs.srcDir(generatedRoot.map { it.dir("jniLibs") })
        resources.srcDir(generatedRoot.map { it.dir("resources") })
        manifest.srcFile("src/main/AndroidManifest.xml")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_21)
    }
}

dependencies {
    api("androidx.exifinterface:exifinterface:1.4.1")
    compileOnly("androidx.annotation:annotation:1.8.1")
    compileOnly("org.jetbrains:annotations:13.0")
}

tasks.named("preBuild").configure {
    dependsOn(buildMegaSdk)
}
