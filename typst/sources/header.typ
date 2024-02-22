#import "/typst/lib/externation.typ": *
#import "/typst/styles/theme.typ": *
//#show : theme-show-rule
#import "@preview/codelst:2.0.0": *
#import "@preview/tablex:0.0.8": *

#do-not-render()

#let nobreak(body) = block(breakable: false, body)

#let centbox(body) = align(center)[
  #box[
    #align(left)[
      #body
    ]
  ]
]

// author: gaiajack
#let labeled-box(lbl, body) = block(above: 2em, stroke: 0.5pt + foreground, width: 100%, inset: 14pt)[
  #set text(font: "Noto Sans")
  #place(
    top + left,
    dy: -.8em - 14pt, // Account for inset of block
    dx: 6pt - 14pt,
    block(fill: background, inset: 2pt)[*#lbl*],
  )
  #body
]

#let marked(fill: lucid(230), stroke: (foreground + 0.25em), body) = {
  let stroke = if type(stroke) == length {
    foreground + stroke
  } else if type(stroke) == color {
    stroke + 0.25em
  } else {
    stroke
  }
  rect(fill: fill, stroke: (left: stroke), width: 100%, body)
}

#let quote(pref: none, author: none, text) = {
  [#pref]
  marked(fill: lucid(235), stroke: foreground + 3pt)[
    #text
    #if author != none {
      align(right)[--- _ #author _]
    }
  ]
}

#let full-externation-log(files, commands, foreground: black, error: rgb("#770000")) = {
  for file in files.keys() {
    labeled-box(file, raw(files.at(file), lang: file.split(".").last()))
  }
  exec(
    files,
    commands,
    (result) => {
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

#let dx = $upright(d)x$
#let dy = $upright(d)y$
#let dz = $upright(d)z$
#let dw = $upright(d)w$
#let du = $upright(d)u$
#let dv = $upright(d)v$
#let dp = $upright(d)p$
#let dt = $upright(d)t$

#let slfrac(a, b) = box(baseline: 50% - 0.3em)[
  #cetz.canvas({
    import cetz.draw : *
    content((0, 0), a, anchor: "bottom-right")
    line((.5em, .5em), (-.2em, -1em), stroke: 1pt)
    content((.35em, -.4em), b, anchor: "top-left")
  })
]

#let cyrsmallcaps(body) = [
  #show regex("[а-яёa-z]") : it => text(size: .7em, upper(it))
  #body
]

#let all-math-display = rest => [
  #show math.equation: it => {
    if it.body.fields().at("size", default: none) != "display" {
      math.display(it)
    } else {
      it
    }
  }
  #rest
]

#let smallcaps-headings(..level-descriptions) = (body) => {
  let descr = level-descriptions.pos()
  show heading : (it) => [
    #set text(size: descr.at(it.level - 1).at(0))
    #set align(descr.at(it.level - 1).at(1))
    #cyrsmallcaps(it)
  ]
  body
}

#let TODO(x) = rect(width: 100%, height: 5em, fill: red, stroke: 3pt + foreground)[
  #set align(center + horizon)
  #text(size: 1.5em, "TODO!")\ #x
]

#let to-code(data) = {
  if type(data) == str {
    data
  } else if type(data) == content {
    if data.func() == raw {
      data.text
    } else {
      assert(false)
    }
  } else if type(data) == none {
    ""
  } else {
    assert(false)
  }
}

#full-externation-log(
  ("test.sh": "ls -Ali\n", "test2.sh": "ps | head -n 10\n"),
  (("ls", "-Ali"), ("bash", "test2.sh")),
)

#let shraw(body, ..args) = pad(left: 2em, y: .5em, raw(align: left, to-code(body), ..args))

//#raw()


#let extract(file, what)  = {
  let ext = file.split(".").last()
  let file = read(file)
  let fragments = search-fragments(what, file)
  assert(fragments.len() == 1)
let  fragment = fragments.at(0)

  let pos = file.position(fragment)
  assert(pos != 0)

  let lines-before = file.slice(0, pos).matches(regex("\r\n|\r|\n")).len()
  
  sourcecode(frame: it=>it, numbers-start:lines-before + 1, raw(fragment, lang:ext))
}


#let general-style = (body) => [
  #show : theme-show-rule
  #show math.ast: math.dot
  #show: all-math-display

  #show: smallcaps-headings(
    (1.8em, center),
    (1.6em, center),
    (1.4em, center),
    (1.4em, left),
    (1.4em, left),
  )

  #set par(justify: true)

  #body
]


