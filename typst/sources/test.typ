#import "header.typ": *

#show : general-style

aaa _bbb_ <x>

#metadata((a: 1, b: 2))<y>

bbb

#setup-exec("test.typext", it => read(it))

= aaaaaa

== b _b_ <x> bb

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

#let marked(fill: luma(240), body) = {
  rect(fill: fill, stroke: (left: 0.25em), width: 100%, body)
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

