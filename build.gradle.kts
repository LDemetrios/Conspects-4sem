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
        val sources = ("find"(rootDir.path, "-name", "*.typ"))

        val modefile = File("mode.txt")

        var allSuccess = true

        File("$rootDir/output").deleteRecursively()

        for (source in sources) {
            val modes = try {
                typst("query", source, "<available-modes>", "--field", "value")
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
                    File(modedir).mkdirs()
                    modefile.writeText(mode)
                    typst("c", source, "${rootDir}/output/$mode/" + File(source).nameWithoutExtension + ".pdf")
                } catch (e: ExecException) {
                    allSuccess = false
                    println("Can't compile $source with mode $mode")
                }
            }
        }

        modefile.writeText("dev")

        if(!allSuccess) {
            throw AssertionError("Not all files were compiled")
        }
    }
}