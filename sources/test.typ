#import "header.typ" : *

#show : general-style

bbb

#setup-exec("test-result.typexec", it => read(it))

#exec(
  ("test.sh": "ls -Ali\n"),
  (("bash", "test.sh"),),
  (text) => eval(text.at(0).output.replace("\n", "\n\n"), mode: "markup"),
)
