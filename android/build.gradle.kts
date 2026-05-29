plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

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
    
    // --- ĐOẠN MÃ SỬA LỖI NAMESPACE BẮT ĐẦU TẠI ĐÂY ---
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            // Kiểm tra nếu namespace trống thì tự động điền dựa trên group hoặc name của project
            if (android.namespace == null) {
                android.namespace = project.group.toString().ifEmpty { 
                    "com.flutter.fallback.${project.name.replace("-", "_")}" 
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