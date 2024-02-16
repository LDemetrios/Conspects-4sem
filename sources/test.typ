#import "header.typ" : *

#show : general-style

bbb

#setup-exec("test.typexec", it => read(it))

= aaaaaa

== b _b_ <x> bb

aa "bb" cc

$a /b$
a <l>

#exec(
  ("test.sh": "ls -Ali\n"),
  (("bash", "test.sh"),),
  (text) => eval(text.at(0).output.replace("\n", "\n\n"), mode: "markup"),
)

#set math.equation(numbering: "(1)")

$#rect[a]$<fe>

- 1
- 2 
  - 3
  - 4
- 5

+ 1
+ 3
  + 5
+ 6

@fe
