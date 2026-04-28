allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    plugins.withId("com.android.library") {
        val androidExtension = extensions.findByName("android") ?: return@withId

        val getNamespace = androidExtension.javaClass.methods.firstOrNull {
            it.name == "getNamespace" && it.parameterTypes.isEmpty()
        }
        val setNamespace = androidExtension.javaClass.methods.firstOrNull {
            it.name == "setNamespace" && it.parameterTypes.contentEquals(arrayOf(String::class.java))
        }

        if (getNamespace != null && setNamespace != null) {
            val currentNamespace = getNamespace.invoke(androidExtension) as? String
            if (currentNamespace.isNullOrBlank()) {
                val sanitizedProjectName = project.name.replace('-', '_')
                setNamespace.invoke(androidExtension, "com.plugin.$sanitizedProjectName")
            }
        }
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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
