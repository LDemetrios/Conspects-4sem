package org.ldemetrios.build

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.gradle.api.Project


@Serializable
data class QueryRes<T>(val func: String, val value: T, val label: String)

@Serializable
data class ExecData(val files: Map<String, String>, val commands: List<List<String>>)

inline fun <reified T> Project.queryAs(file: String, label: String) =
    Json.decodeFromString<T>("typst"("query", "--root", rootDir.path, file, "<$label>").joinToString("\n"))

inline fun <reified T> Project.queryAsSingle(file: String, label: String) =
    queryAs<List<T>>(file, label).single()

inline fun <reified T> Project.queryAsSingleOrNull(file: String, label: String) =
    queryAs<List<T>>(file, label).singleOrNull()
