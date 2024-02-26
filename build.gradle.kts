import org.ldemetrios.typst4gradle.Typst4Gradle

fun Project.typst4gradle(config: Typst4Gradle.() -> Unit) =
    configure<Typst4Gradle>(config)

plugins {
    kotlin("jvm") version "1.9.21"
//    id("org.ldemetrios:typst4gradle") version ("1.0.0.20240220.1549")

}

group = "org.ldemetrios"
version = "1.0-SNAPSHOT"

buildscript {
    repositories {
        mavenLocal()

        dependencies {
            classpath("org.ldemetrios:typst4gradle:1.0.0.20240220.1549")
        }
    }
}
apply(plugin = ("typst4gradle"))


typst4gradle {
    stylingFile = "$rootDir/typst/styles/theme.typ"
    themeDispatcherFile = "$rootDir/typst/styles/theme-dispatch.typ"
}

repositories {
    mavenCentral()
}

dependencies {
    testImplementation("org.jetbrains.kotlin:kotlin-test")
}

tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}