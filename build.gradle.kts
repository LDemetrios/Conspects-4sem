import org.gradle.process.internal.ExecException
import java.io.ByteArrayOutputStream

operator fun String.invoke(vararg args: String): List<String> {
    val out = ByteArrayOutputStream()
//    val err = ByteArrayOutputStream()
    val res = project.exec {
        println(this@invoke + " " + args.joinToString(" "))
        commandLine(this@invoke, *args)
        standardOutput = out
        errorOutput = System.err
        workingDir = project.projectDir
    }

    return out.toString().split(Regex("\r\n|[\r\n\u2028\u2029\u0085]")).filter(String::isNotBlank)
}

val typst = "typst"

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
            val modes = try {
                typst("query", "--root", rootDir.path, source, "<available-modes>", "--field", "value")
            } catch (e: ExecException) {
                println("Can't query available modes for $source")
                allSuccess = false
                continue
            }
                .joinToString(" ")
                .filter { it !in "[]" }
                .split(",")
                .filter(String::isNotBlank)
                .map(String::trim)
                .map { it.substring(1, it.length - 1) }


            for (mode in modes) {
                try {
                    val modedir = "${rootDir}/output/$mode"
                    File(modedir).parentFile.mkdirs()
                    modefile.writeText(mode)

                    val dest = "${rootDir}/output/$mode/" +
                            File(source).parent.drop((rootDir.path + "/sources/").length) +
                            "/" + File(source).nameWithoutExtension + ".pdf"
                    File(dest).parentFile.mkdirs()
                    typst(
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