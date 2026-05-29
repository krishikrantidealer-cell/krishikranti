allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        if (name != "app") {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.apply {
                val currentSdk = compileSdkVersion
                val sdkInt = currentSdk?.substringAfter("android-")?.toIntOrNull() ?: currentSdk?.toIntOrNull()
                if (sdkInt == null || sdkInt < 34) {
                    compileSdkVersion(34)
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
