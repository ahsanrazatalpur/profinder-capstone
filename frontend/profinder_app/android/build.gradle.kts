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
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val method = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    method.invoke(androidExt, 35)
                } catch (e1: Exception) {
                    try {
                        val method = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                        method.invoke(androidExt, 35)
                    } catch (e2: Exception) {
                        try {
                            val method = androidExt.javaClass.getMethod("setCompileSdk", Integer::class.java)
                            method.invoke(androidExt, 35)
                        } catch (e3: Exception) {
                        }
                    }
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
