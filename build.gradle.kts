import org.gradle.process.internal.ExecException
import org.ldemetrios.build.*
import java.io.BufferedReader
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStreamReader
import java.util.stream.Collectors
import kotlin.system.exitProcess

org.ldemetrios.build.project = project

fun processCode(testfile: String) {
    val resultsFile = File("${testfile}exec")

    if (resultsFile.exists()) resultsFile.delete()


    val execCallsNumber = queryAsSingleOrNull<QueryRes<Int>>(testfile, "exec-calls-number")?.value ?: return
    println("Found $execCallsNumber code fragments")

    val dir = File("__tmp__")

    val executionResults = mutableListOf<List<Triple<String, String, Int>>>()

    for (i in 0 until execCallsNumber) {
        val fragmentExecutionResults = mutableListOf<Triple<String, String, Int>>()

        val fragment = queryAsSingle<QueryRes<ExecData>>(testfile, "exec-call-$i").value

        if (dir.exists()) dir.deleteRecursively()

        for ((filename, content) in fragment.files) {
            val file = File("$dir/$filename")
            file.parentFile.mkdirs()
            file.createNewFile()
            file.writeText(content)
        }

        for (command in fragment.commands) {
            try {
                println(command)
                val (out, err, ret) = call(command, root = dir)
                println("evaluated")
                fragmentExecutionResults.add(Triple(out, err, ret))
            } catch (e: ExecException) {
                throw Throwable("Unexpected", e)
            }
        }

        dir.deleteRecursively()

        executionResults.add(fragmentExecutionResults)
    }


//    println(resultsFile)

    fun String.toCode() = "\"" +
            this
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t") + "\""

    resultsFile.run {
        if (exists()) delete()
        parentFile.mkdirs()
        createNewFile()
        writeText(
            executionResults.joinToString(" \n", "(\n", "\n)") {
                it.joinToString("\n", "(\n", "\n),") {
                    """(
            |   output:${it.first.toCode()},
            |   error:${it.second.toCode()},
            |   returnCode:${it.third}
            |),
        """.trimMargin()
                }
            }
        )
    }
}


inline fun <reified T> Any?.cast(): T = this as T

tasks.register("typst-clean-exec") {
    "find"(rootDir.path, "-name", "*.typexec").forEach {
        File(it).delete()
    }

}

tasks.register("typst-compile") {
    group = "typst"
    description = "Compiles all the typst files with all the available modes"
    doLast {
        val pdfs = ("find"(rootDir.path, "-name", "*.pdf"))
        pdfs.forEach {
            File(it).delete()
        }

        val sources = ("find"(rootDir.path + "/sources", "-name", "*.typ"))


        val modefile = File("mode.txt")
        val modeWas = if (modefile.exists()) modefile.readText() else null

        var allSuccess = true

        File("$rootDir/output").deleteRecursively()


        for (source in sources) {
            File(source + "exec").delete()
            val doRender = queryAs<List<QueryRes<Boolean>>>(source, "do-not-render")
            if (doRender.isNotEmpty()) continue

            val modes = try {
                queryAsSingleOrNull<QueryRes<List<String>>>(source, "available-modes")?.value
            } catch (e: ExecException) {
                println("Can't query available modes for $source")
                allSuccess = false
                continue
            }

            if (modes == null) {
                val dest = "${rootDir}/output/" +
                        File(source).parent.drop((rootDir.path + "/sources/").length) +
                        "/" + File(source).nameWithoutExtension + ".pdf"
                File(dest).parentFile.mkdirs()
                processCode(source)
                "typst"("c", "--root", rootDir.path, source, dest)
                continue
            }

            for (mode in modes) {
                try {
                    val modedir = "${rootDir}/output/$mode"
                    File(modedir).parentFile.mkdirs()
                    modefile.writeText(mode)

                    processCode(source)

                    val dest = "${rootDir}/output/$mode/" +
                            File(source).parent.drop((rootDir.path + "/sources/").length) +
                            "/" + File(source).nameWithoutExtension + ".pdf"
                    File(dest).parentFile.mkdirs()
                    "typst"(
                        "c",
                        "--root",
                        rootDir.path,
                        source,
                        dest
                    )
                } catch (e: ExecException) {
                    allSuccess = false
                    println("Can't compile $source with mode $mode")
                }
            }
        }

        if (modeWas != null) modefile.writeText(modeWas)

        if (!allSuccess) {
            throw AssertionError("Not all files were compiled")
        }
    }
}

tasks.register("magic") {
    doLast {
        println(this.javaClass.name)
    }
}
