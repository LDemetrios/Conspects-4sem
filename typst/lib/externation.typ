
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

#let externation-data = state("externation-data", (
  do-show-result: false,
  exec-call-counter: 0,
  exec-results-file: none,
  reader: none,
))

#let exec(
  files, /* dict<filename, string> */
  commands, /* array<command : array<args>> */
  displayer, /* function (result) => content */
  stub: () => text(fill: blue, `Evaluation results aren't displayed`), /* function () => replacement */
) = {
  externation-data.display(
    data => {
      let cnt = data.exec-call-counter
      [
        #metadata((files: files, commands: commands))#label("exec-call-" + str(cnt))
      ]
      if data.do-show-result {
        let eval-res = eval((data.reader)(data.exec-results-file))
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

  externation-data.update(it =>
  (
    do-show-result: it.do-show-result,
    exec-call-counter: it.exec-call-counter + 1,
    exec-results-file: it.exec-results-file,
    reader: it.reader,
  ))
}

#let setup-exec(results-file, reader) = {
  try-catch(() => {
    let _ = reader(results-file)
    externation-data.update(it =>
    (
      do-show-result: true,
      exec-call-counter: 0,
      exec-results-file: results-file,
      reader: reader,
    ))
  }, () => {
    externation-data.update(it =>
    (
      do-show-result: false,
      exec-call-counter: 0,
      exec-results-file: results-file,
      reader: reader,
    ))
  })
}

#let close-exec() = {
  externation-data.display(it => [
    #metadata(it.exec-call-counter)#label("exec-calls-number")
  ])
}

#let remove-fragment-markers(rgx: regex("/\* *#ext:[a-zA-Z0-9.:\-]* *\*/"), body) = {
  body.replace(rgx, "");
}

#let search-fragments(marker, begin-format: (it) => regex("/\* *#ext:begin:" + it + " *\*/"), end-format: (it) => regex("/\* *#ext:end:" + it + " *\*/"), fragment-markers-regex:regex("/\* *#ext:[a-zA-Z0-9.:\-]* *\*/"), code) = {
  let begin-marker = begin-format(marker)
  let end-marker = end-format(marker)

  code.split(begin-marker).slice(1).map(
    it => it.split(end-marker)
  ).filter(
    it => it.len() > 1
  ).map(
    it => it.at(0).trim(regex("[\r\n]*"))
  )
}


#let do-not-render() = {
  [
    #metadata(true)<do-not-render>
  ]
}

#do-not-render()

#let colored-output(entry, out, err) = {
  let output = entry.at("output", default:())
  for line in output {
    let clr = if line.color == "output" { out } else { err }
    text(fill:clr, raw(line.line))
    [\ ]
  }
}