#import "/typst/styles/theme-dispatch.typ": *


#let decide(on, whatif) = if (on == none) { body => body } else { whatif }
#let either(..a) = if (a.pos().contains(none)) { none } else { 1 }

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
    #show: decide(base, (body) => { set page(fill: base); body })
    #show: decide(fill, (body) => { set text(fill: fill); body })
    #show:decide(subtle, (body) => { set line(stroke: subtle); body })
    #show : decide(either(subtle, overlay), (body) => {
        set circle(stroke: subtle, fill: overlay)
        set ellipse(stroke: subtle, fill: overlay)
        set path(stroke: subtle, fill: overlay)
        set polygon(stroke: subtle, fill: overlay)
        set rect(stroke: subtle, fill: overlay)
        set square(stroke: subtle, fill: overlay)
        body
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

#let lucid(lightness) = color.mix((foreground, (255 - lightness)), (background, lightness))

#let theme-show-rule = (rest) => [
    #show : showtheme(
        base:background,
        fill:foreground,
    )
    
    #show : decide(pagewidth, body => { set page(width:pagewidth); body } )
    #show : decide(pageheight, body => { set page(height:pageheight); body } )
    
    #rest
]
