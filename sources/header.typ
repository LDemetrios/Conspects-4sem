#import "@preview/cetz:0.1.2"
#import "@preview/tablex:0.0.6": *
#import "@local/ldemetrios-commons:0.1.0" : *

#import "@preview/tablex:0.0.6": *

#let conf(title: none, authors: (), abstract: [], doc) = {
  set page(
    paper: "us-letter",
    header: align(right + horizon, title),
    numbering: "1",
  )

  set par(justify: true)
  set text(font: "Linux Libertine", size: 11pt)

  // Heading show rules.
  show heading.where(level: 1): it => block(width: 100%)[
    #set align(center)
    #set text(12pt, weight: "regular")
    #smallcaps(it.body)
  ]

  show heading.where(level: 2): it => text(size: 11pt, weight: "regular", style: "italic", it.body + [.])

  set align(center)
  text(17pt, title)

  let count = authors.len()
  let ncols = calc.min(count, 3)
  grid(columns: (1fr,) * ncols, row-gutter: 24pt, ..authors.map(author => [
    #author.name \
    #author.affiliation \
    #link("mailto:" + author.email)
  ]))

  par(justify: false)[
    *Abstract* \
    #abstract
  ]

  set align(left)
  columns(2, doc)
}

#let nobreak(body) = block(breakable: false, body)

#let centbox(body) = align(center)[
  #box[
    #align(left)[
      #body
    ]
  ]
]

#let quote(pref: none, author: none, text) = {
  [#pref]
  tablex(
    columns: (.7em, .4em, 1fr),
    align: left + horizon,
    auto-vlines: false,
    auto-hlines: false,
    [],
    vlinex(start: 0, end: 1, stroke: rgb("#aaaaaa") + 3pt),
    [],
    [
      #text
      #if author != none {
        align(right)[--- _ #author _]
      }
    ],
  )
}

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

#let showtheme(
  base: none,
  fill: none,
  surface: none,
  high: none,
  subtle: none,
  overlay: none,
  iris: none,
  foam: none,
  fnote: none,
) = body => [

  #let decide(on, whatif) = if (on == none) { body => body } else { whatif }
  #let either(..a) = if (a.pos().contains(none)) { none } else { 1 }

  #show: decide(base, (body) => { set page(fill: base); body })
  #show: decide(fill, (body) => { set text(fill: fill); body })
  #show:decide(subtle, (body) => { set line(stroke: subtle);body })
  #show : decide(either(subtle, overlay), (body) => {
    set circle(stroke: subtle, fill: overlay)
    set ellipse(stroke: subtle, fill: overlay)
    set path(stroke: subtle, fill: overlay)
    set polygon(stroke: subtle, fill: overlay)
    set rect(stroke: subtle, fill: overlay)
    set square(stroke: subtle, fill: overlay)
  })
  #show : decide(high, (body) => { set highlight(fill: highlight.high); body })
  #show : decide(
    either(surface, high),
    (body) => { set table(fill: surface, stroke: highlight.high); body },
  )

  #show link: decide(iris, (body) => { set text(fill: iris); body })
  #show ref: decide(foam, (body) => { set text(fill: foam); body })
  #show footnote: decide(fnote, (body) => { set text(fill: fnote); body })

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

#let dx = $upright(d)x$
#let dy = $upright(d)y$
#let dz = $upright(d)z$
#let dw = $upright(d)w$
#let du = $upright(d)u$
#let dv = $upright(d)v$
#let dp = $upright(d)p$
#let dt = $upright(d)t$

#let signif(x) = [
  #box(pad(bottom: -.5em, text(size: 2em, "!"))) #x
]

#let modes = (development: (
  name: "Development",
  shortcut: "development",
  background: black,
  foreground: white,
  bbf: luma(63),
  bff: luma(191),
  middle: luma(127),
  red-ish: rgb("#ff7777"),
  green-ish: rgb("#77ff77"),
  blue-ish: rgb("#7777ff"),
  yellow-ish: rgb("#ffff77"),
), print: (
  name: "Print",
  shortcut: "print",
  background: white,
  foreground: black,
  bbf: luma(191),
  bff: luma(63),
  middle: luma(127),
  red-ish: luma(127),
  green-ish: luma(127),
  blue-ish: luma(127),
  yellow-ish: luma(127),
), dark: (
  name: "Dark",
  shortcut: "dark",
  background: rgb("#212121"),
  foreground: rgb("#f0f0f0"),
  bbf: luma(80),
  bff: luma(191),
  middle: luma(135),
  red-ish: rgb("#ff7777"),
  green-ish: rgb("#77ff77"),
  blue-ish: rgb("#7777ff"),
  yellow-ish: rgb("#ffff77"),
),  sepia: (
  name: "Sepia",
  shortcut: "sepia",
  background: rgb("#ebd5b3"),
  foreground: black,
  bbf: luma(191),
  bff: luma(63),
  middle: luma(127),
  red-ish: rgb("#770000"),
  green-ish: rgb("#007700"),
  blue-ish: rgb("#000077"),
  yellow-ish: rgb("#777700"),
),  regular: (
  name: "Regular",
  shortcut: "regular",
  background: rgb("#ffffff"),
  foreground: black,
  bbf: luma(191),
  bff: luma(63),
  middle: luma(127),
  red-ish: rgb("#770000"),
  green-ish: rgb("#007700"),
  blue-ish: rgb("#000077"),
  yellow-ish: rgb("#777700"),
))



#let mode = modes.at(read("../mode.txt"))

#let (
  background,
  foreground,
  bbf,
  bff,
  middle,
  red-ish,
  green-ish,
  blue-ish,
  yellow-ish,
) = mode

#let mode = mode.shortcut


#let TODO(x) = rect(width: 100%, height: 5em, fill: bbf, stroke: 1pt + foreground)[
  #set align(center + horizon)
  #text(size: 1.5em, "TODO!")\ #x
]


#let labeled-try-catch(unique-label, first, on-error) = {
  locate(loc => {
    let lbl = label(unique-label)
    let first-time = query(locate(_ => {}).func(), loc).len() == 0
    if first-time or query(lbl, loc).len() > 0 {
      [#first() #lbl]
    } else {
      on-error()
    }
  })
}

#let try-catch-counter = state("try-catch-counter", 0)

#let try-catch(a, b) = {
  try-catch-counter.display(cnt => {
    labeled-try-catch("try-catch-lbl-" + str(cnt), a, b)
  })
  try-catch-counter.update(cnt => { cnt + 1 })
}

#let do-show-results = state("do-show-results", false)
#let exec-call-counter = state("exec-call-counter", 0)
#let exec-results-file = state("exec-results-file", none)

#let exec(
  files, /* dict<filename, string> */
  commands, /* array<command : array<args>> */
  displayer, /* function (result) => content */
  stub: () => text(fill: blue, `Evaluation results aren't displayed`), /* function () => replacement */
) = {
  exec-call-counter.display(
    cnt => {
      exec-results-file.display(
        res => {
          do-show-results.display(
            do-show => {
              [
                #metadata((files: files, commands: commands))#label("exec-call-" + str(cnt))
              ]
              if do-show {
                let eval-res = eval((res.reader)(res.results-file))
                if (eval-res.len() > cnt) {
                  displayer(eval-res.at(cnt))
                } else {
                  `Not yet evaluated`
                }
              } else {
                stub()
              }
            },
          )
        },
      )
    },
  )

  exec-call-counter.update(it => { it + 1 })
}

#let setup-exec(results-file, reader) = {
  exec-results-file.update(it => (results-file: results-file, reader: reader))
  try-catch(() => {
    let _ = reader(results-file)
    do-show-results.update(it => true)
  }, () => {
    do-show-results.update(it => false)
  })
  [
    #metadata(results-file)#label("exec-results-file")
  ]
}

#let close-exec() = {
  exec-call-counter.display(cnt => [
    #metadata(cnt)#label("exec-calls-number")
  ])
}

#let do-not-render() = {
  [
    #metadata(true)<do-not-render>
  ]
}

#do-not-render()

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

#let shraw(body, ..args) = pad(left: 2em, y: .5em, raw(align:left, to-code(body), ..args))

#let general-style = (body) => [
  #show math.ast: math.dot
  #show: all-math-display

  #show: showtheme(base: background, fill: foreground)

  #show: smallcaps-headings(
    (1.8em, center),
    (1.6em, center),
    (1.4em, center),
    (1.4em, left),
    (1.2em, left),
  )

  #set par(justify: true)

  #if mode == "print" {
    [
      #metadata(modes.keys()) #label("available-modes")

      #body
    ]
  } else {
    [
      #set page(height: auto)
      #metadata(modes.keys()) #label("available-modes")
      #body
    ]
  }
]

