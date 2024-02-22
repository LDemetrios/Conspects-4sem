#import "header.typ": *

#show : general-style

aaa _bbb_ <x>

#metadata((a: 1, b: 2))<y>

bbb

#setup-exec("test.typext", it => read(it))

= aaaaaa

== b _b_ <x> bb

// author: gaiajack
#let labeled-box(lbl, body) = block(above: 2em, stroke: 0.5pt + black, width: 100%, inset: 14pt)[
  #set text(font: "Noto Sans")
  #place(
    top + left,
    dy: -.8em - 14pt, // Account for inset of block
    dx: 6pt - 14pt,
    block(fill: white, inset: 2pt)[*#lbl*],
  )
  #body
]

#let marked(fill: luma(240), body) = {
  rect(fill: fill, stroke: (left: 0.25em), width: 100%, body)
}

#let full-externation-log(files, commands, foreground: black, error: rgb("#770000")) = {
  exec(
    files,
    commands,
    (result) => {
      for file in files.keys() {
        labeled-box(file, sourcecode(
          numbers-start: 1,
          frame: (body) => body,
          raw(files.at(file), lang: file.split(".").last()),
        ))
      }

      let x = for i in range(calc.min(commands.len(), result.len())) {
        ({
          ` $ `

          let command = commands.at(i).map(arg => {
            if arg.contains(regex("[^a-zA-Z0-9\-/.]")) {
              "'" + arg.replace("'", "'\''") + "'"
            } else { arg }
          })
          raw(command.join(" "), lang: "bash")

          [\ ]

          for line in result.at(i).output {
            let clr = if (line.color == "output") { foreground } else { error }
            text(fill: clr, raw(line.line))
            [\ ]
          }

          `Process finished with exit code `
          raw(str(result.at(i).code))
        },)
      }
      x.join([\ #line(length: 50%, stroke: .25pt + maroon) ])
    },
  )
}

aa "bb" cc

$a /b$
a <l>

/* #ext:begin:fel */
#full-externation-log(
  ("test.sh": "ls -Ali\n", "test2.sh": "ps | \n     head -n 10\n"),
  (("ls", "-Ali"), ("bash", "test2.sh")),
)
/* #ext:end:fel */

#extract("test.typ", "fel") 

#close-exec()

