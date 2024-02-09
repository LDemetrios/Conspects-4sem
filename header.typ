#import "@preview/cetz:0.1.2"
#import "@preview/tablex:0.0.6": tablex, cellx
#import "@local/ldemetrios-commons:0.1.0" : *

#let signif(x) = [
  #box(pad(bottom: -.5em, text(size: 2em, "!"))) #x
]

#let modes = (dev: (
  name: "Development",
  shortcut: "dev",
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
), light: (
  name: "Light",
  shortcut: "light",
  background: white,
  foreground: black,
  bbf: luma(191),
  bff: luma(63),
  middle: luma(127),
  red-ish: rgb("#770000"),
  green-ish: rgb("#007700"),
  blue-ish: rgb("#000077"),
  yellow-ish: rgb("#777700"),
))

#let mode = modes.at(read("mode.txt"))

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

#let mode = mode.name

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
  #set page(height: auto)

  #metadata(modes.keys()) #label("available-modes")

  #body
]

