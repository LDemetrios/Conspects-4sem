#import "header.typ": *

#show: general-style

#setup-exec("gpu.typext", it => read(it))

= Программирование на видеокартах

== Начало

=== Как это всё компилировать

===== Хост-код

`.h` файлы для C/C++ есть на официальном сайте, правда, там есть
задепрекейченные полезные функции. Придётся задефайнить версию. Достаточно
хедера `<CL/cl.h>`. Можно --- `<CL/opencl.h>`

Чтобы слинковаться, надо где-то взять либы. Под линуксом --- некий магический
package. Под виндоусом --- откуда-то взять. На официальном сайте Кроноса есть.
Обратите внимание на битность!

===== Девайс-код

Само разберётся. Обычно.

===== Запуск

В пределах конспекта код запускается с помощью `cmake`:

#let cl-cmake = read("aux/gpu-cmake.txt")

#codeblock(raw(cl-cmake, lang: "cmake"))

// Setup evaluator

#let cppgit = (prelude: read("aux/gpu-prelude.cpp"), code: "", lines: 0)

#let prelude_set(branch, new-prelude) = {
  // branch copies here
  branch.plelude = to-code(new-prelude)
  branch
}

#let code_set(branch, new-code) = {
  branch.lines = to-code(new-code).trim().split(regex("\r\n|\r|\n")).len()
  branch.code = to-code(new-code)
  branch
}

#let prelude_append(branch, appendix) = {
  branch.prelude = branch.prelude + "\n\n" + to-code(appendix)
  branch
}

#let code-sep-output = "//////////////"
#let code-sep = "\n\nstd::cout << std::endl << \"" + code-sep-output + "\" << std::endl;\n" + "std::cout << std::endl << \"" + code-sep-output + "\" << std::endl;\n "

#let code_append(branch, appendix) = {
  branch.lines = branch.lines + to-code(appendix).trim().split(regex("\r\n|\r|\n")).len()
  branch.code = branch.code + code-sep + to-code(appendix)

  branch
}

#let branch-full-code(branch) = {
  let code = branch.code
  code = code.replace("\n", "\n\t").trim()
  code = branch.prelude + "\n\nint main() {\n\t" + code + "\n}\n"
  code
}

#let show-branch-code(branch) = {
  codefragment(branch.code.replace(code-sep, "\n"), lang: "cpp")
}

#let show-last-commit-output(colored, outclr, errclr) = {
  let last-err-sep = -1
  let last-out-sep = -1
  for i in range(colored.len()) {
    if colored.at(i).line == code-sep-output {
      if colored.at(i).color == "output" {
        last-out-sep = i
      } else {
        last-err-sep = i
      }
    }
  }

  let cut-result = ()
  for i in range(colored.len()) {
    if (i > last-err-sep and colored.at(i).color == "error") or (i > last-out-sep and colored.at(i).color == "output") {
      cut-result.push(colored.at(i))
    }
  }
  colored-output(cut-result, outclr, errclr)
}

#let parse-cmake-result(result, show-results: true) = {
  if type(result) != array or result.len() != 3 or result.map(it => type(it)).any(it => it != dictionary) {
    text(fill: blue, `Evaluation results are invalid`)
  } else if result.at(0).at("code", default: -1) != 0 {
    text(fill: red, `Error preparing CMake`)
    [\ ]
    colored-output(result.at(0).output, foreground, red)
  } else if result.at(1).at("code", default: -1) != 0 {
    text(fill: red, `Compilation error`)
    [\ ]
    colored-output(result.at(1).output, foreground, red)
  } else {
    if (show-results) {
      show-last-commit-output(result.at(2).output, foreground, red)
      if (result.at(2).at("code", default: -1) > 0) {
        text(fill: red)[
          #raw("Exited with " + str(result.at(1).code))\
        ]
      }
    } else {
      none
    }
  }
}

#let exec-branch(branch, show-results: true) = {
  let code = branch-full-code(branch)
  exec(
    ("main.cpp": code, "CMakeLists.txt": cl-cmake),
    eval(read("aux/cmake-build-command.txt")),
    (result) => {
      let data = parse-cmake-result(result, show-results: show-results);
      if data != none {
        offset(2em, marked(fill: lucid(245), stroke: foreground + .1em, data))
      }
    },
  )
}

Как водится в плюсах, придётся написать некоторое количество функций и
(тьфу-тьфу) макросов, чтобы было удобно. Полный перечень того, что использую я,
можно прочитать в файле "sources/aux/gpu-prelude".

Пытаемся запустить:

#let commit(branch, execute: true, show-code: true, show-results: true, code) = {
  let lines-was = branch.lines
  let new-branch = code_append(branch, code)

  let cont = {
    if (show-code) {
      align(left)[
        #offset(2em, codefragmentraw(code, start: lines-was + 1))
      ]
    }
    if execute {
      exec-branch(new-branch, show-results: show-results)
    }
  }
  (cont, new-branch)
}

#let (doc, new-branch) = commit(cppgit, ```cpp
std::vector v({1, 2, 3});
println(v);
```)

#doc

Работает.

=== API

Большинство функций возвращают код ошибки (как обычно, 0 --- успешно, не 0 ---
не успешно). Надо проверять! Во всяком случае, в дебаге, в учебных целях.
Написать макрос? Какой ужас.

Это за исключением функций типа `create`, которые возвращают то, что они
`create`. Тогда код ошибки, если нужен, по ссылке, передаваемой в аргумент...
Такой типичный С.

==== Получение девайсов

===== `clGetPlatformIDs`
--- API для получения списка доступных платформ. Принимает... Указатель, размер,
и указатель на размер... Буффер, размер буффера, и то, куда записывать, сколько.

Понятное дело, память она не выделяет. Так как надо, чтобы освобождал тот, кто
выделил. Такой типичный С...

Так, а какого размера выделять буффер? Для этого есть специальный вариант
вызова: `(nullptr, 0, &x)` --- тогда в `x` нам запишут то, сколько на самом деле
вариантов. Идейно. Такой принцип применяется здесь во всемх вызовах.

Правда, в отличие от типичного С, если буфера мало, то это не ошибка "буфера
мало", а нам запишут, сколько есть места.

Можно сказать, "возвращает" эта функция список id платформ, где можно запустить
opencl.

#let (doc, br-platfromIDs) = commit(cppgit, ```cpp
uint32_t s;
clGetPlatformIDs(0, nullptr, &s);
std::vector<cl_platform_id> platforms(s);
clGetPlatformIDs(s, platforms.data(), &s);
println(platforms);
```)

#doc

Результат не вполне содержательный --- `cl_platform_id` это просто указатель на
не очень понятно что. Но нам это и не надо --- это всего лишь идентификатор,
который умеют понимать другие функции апи.

==== `clGetPlatformInfo`
--- Получаем информацию о конкретной платформе. Сюда передаётся `platformID`,
полученный на предыдущем этапе, и константа, обозначающая, какую информацию мы
хотим. Остальное --- как раньше.

#let (doc, x) = commit(
  br-platfromIDs,
  ```cpp
            for (auto platform : platforms) {
                println(platform);
                size_t pl_name_length;
                clGetPlatformInfo(platform, CL_PLATFORM_NAME, 0, nullptr, &pl_name_length);
                std::vector<char> pl_name(pl_name_length);
                clGetPlatformInfo(platform, CL_PLATFORM_NAME, pl_name_length,
                                                      pl_name.data(), &pl_name_length);
                std::string str(pl_name.begin(), pl_name.end());
                println(str);
            }
            ```,
)

#doc

#show-branch-code(x)

Здесь можно запросить разную информацию. Но сначала давайте сначала сделаем
какую-нибудь обёртку для всех этих вызовов. Можно было бы сделать это
по-честному template функцией, но мы хотим без лишней возни удобные сообщения об
ошибках...

#text(size: .8em)[
  #extract("/typst/sources/aux/gpu-prelude.cpp", "wmacros")
]

Выколите мне глаза. Но, зато теперь относительно понятно, что мы делаем:

Зато теперь относительно нормально вызываем:

#let (doc, br-info-printed) = commit(
  cppgit,
  ```cpp
        auto platforms = wGetPlatformIDs();

        for (auto platform : platforms) {
            println();
            println(platform);
            auto profile = wGetPlatformInfoStr(platform, CL_PLATFORM_PROFILE);
            auto version = wGetPlatformInfoStr(platform, CL_PLATFORM_VERSION);
            auto name = wGetPlatformInfoStr(platform, CL_PLATFORM_NAME);
            auto vendor = wGetPlatformInfoStr(platform, CL_PLATFORM_VENDOR);
            auto extensions = wGetPlatformInfoStr(platform, CL_PLATFORM_EXTENSIONS);
            auto host_timer_resolution = wGetPlatformInfo<cl_ulong>(platform,
                                                 CL_PLATFORM_HOST_TIMER_RESOLUTION);
            println("Profile:               ", profile);
            println("Version:               ", version);
            println("Name:                  ", name);
            println("Vendor:                ", vendor);
            println("Extensions:            ", extensions);
            println("Host Timer Resolution: ", host_timer_resolution);
        }

        ```,
)

#doc

На компьютере установлены две платформы (у вас может быть по-другому),
встроенная графика AMD процессора, и Intel'овская реализация на процессоре.

==== `clGetDeviceIDs`

Наконец, мы хотим получить от платформы список доступных девайсов. Эта функция
принимает id платформы и тип девайса, который мы хотим, на выбор:

#align(
  center,
)[
  #box(
    width: 90%,
  )[
    #tablex(
      columns: 2,
      stroke: foreground,
      [CL_DEVICE_TYPE_CPU],
      [An OpenCL device that is the host processor. The host processor runs the OpenCL
        implementations and is a single or multi-core CPU.],
      [CL_DEVICE_TYPE_GPU],
      [An OpenCL device that is a GPU. By this we mean that the device can also be used
        to accelerate a 3D API such as OpenGL or DirectX.],
      [CL_DEVICE_TYPE_ACCELERATOR],
      [Dedicated OpenCL accelerators (for example the IBM CELL Blade). These devices
        communicate with the host processor using a peripheral interconnect such as
        PCIe.],
      [CL_DEVICE_TYPE_DEFAULT],
      [The default OpenCL device in the system.],
      [CL_DEVICE_TYPE_ALL],
      [All OpenCL devices available in the system.],
    )
  ]

  -- Прямиком из документации

  #box(
    width: 90%,
  )[
    #tablex(
      columns: 2,
      stroke: foreground,
      [CL_DEVICE_TYPE_CPU],
      [Устройство OpenCL, главный процессор. Хост-процессор запускает реализации OpenCL
        и представляет собой одно-- или многоядерный CPU.],
      [CL_DEVICE_TYPE_GPU],
      [Устройство OpenCL, графический процессор. Под этим мы подразумеваем, что
        устройство также можно использовать для ускорения 3D API, такого как OpenGL или
        DirectX.],
      [CL_DEVICE_TYPE_ACCELERATOR],
      [Специальные ускорители OpenCL (например, IBM~CELL~Blade). Эти устройства
        взаимодействуют с главным процессором с помощью периферийного соединения, такого
        как PCIe.],
      [CL_DEVICE_TYPE_DEFAULT],
      [Устройство OpenCL по умолчанию в системе.],
      [CL_DEVICE_TYPE_ALL],
      [ Все устройства OpenCL, доступные в системе. ],
    )
  ]

  -- Мне лень переводить.

]

#let (doc, obtain-devices) = commit(
  br-info-printed,
  ```cpp
        for (auto platform : platforms) {
            println("For platform ", platform);
            println("CPU:         ", wGetDeviceIDs( platform, CL_DEVICE_TYPE_CPU));
            println("GPU:         ", wGetDeviceIDs( platform, CL_DEVICE_TYPE_GPU));
            println("ACCELERATOR: ", wGetDeviceIDs( platform,
                                                      CL_DEVICE_TYPE_ACCELERATOR));
            println("DEFAULT:     ", wGetDeviceIDs( platform, CL_DEVICE_TYPE_DEFAULT));
            println("ALL:         ", wGetDeviceIDs( platform, CL_DEVICE_TYPE_ALL));
            println();
        }
        ```,
)

#doc

Здесь внезапно обнаруживаем, что если девайсов не найдено, то первый вызов
функции не "вернёт" 0, а выдаст код ошибки -1. Учитываем это.

Ну круто, у нас две платформа с одним девайсом на каждой. Выбираю реализацию на
процессоре, так как драйвера amd graphics под линукс немного глючные.

==== Делаем что-то полезное

#let (doc, select-devices) = commit(br-info-printed, ```cpp
    auto devices = wGetDeviceIDs(platforms[1], CL_DEVICE_TYPE_ALL);
```, show-results: false)

#doc

... или несколько...

Кстати, конечно, выбирать явным индексом, конечно, плохая идея, но об этом мы
потом подумаем.

Теперь нам нужно создать контекст.

===== `clCreateContext`

Контекст --- это своего рода `globalThis` от мира OpenCL. Он инкапсулирует в
себе всё, что мы хотим из хост-кода делать с девайс-кодом.

Функция принимает кучу всего. В частности, умеет принимать несколько девайсов,
если они принадлежат одной платформе. Ну, пока обойдёмся. В качестве `user_data`
передаём nullptr. `properties` --- тоже странная штука, пока обойдёмся без неё.

#let (doc, context-created) = commit(select-devices, ```cpp
auto context = wCreateContext(nullptr, devices, nullptr, nullptr);
println(context);
```)

#doc

Ещё один несодержательный указатель.

Теперь нужно в этом контексте создать тот код, который мы будем запускать в этом
контексте:

==== `clCreateProgramWithSource`

"Принимает" массив указателей на source.

Обычно мы хотим не извращаться с C-style строчками, а иметь отдельный файл с
исходным кодом (обычно расширение `.cl`). То есть, надо открыть файл, прочитать
и скормить (компиляция девайс-кода будет уже в рантайме). Предлагается
использовать обычные C'шные функции fread и прочее. Открыть в `binary`, `seek`
до конца и так далее.

Эта функция не делает ничего особенного. Если мы тут зафейлились, мы где-то
конкретно налажали --- передали кривой буфер или ещё что-нибудь. Ошибки внутри
девайс-кода будут обнаруживаться уже потом.

==== `clBuildProgram`

Вот это уже серьёзно: компиляция нашего исходника. Передаём сюда `id` нашего
`program`'a, который мы по'create'или, и девайс, под который надо скомпилиться.
Или передать null, и тогда будет скомпилированно под все девайсы, привязанные к
контексту.

Компиляция может занимать продолжительное время! Имеет смысл локально
закэшировать. Но так как результат сильно зависит от драйверов, девайсов,
версий, погоды, фазы луны; распространять прекомпилированную версию не имеет
смысла.

Если в девайс-коде есть какая-нибудь синтаксическая (или ещё что-нибудь) ошибка,
то она вылезет здесь. Обязательно проверять результат здесь! Можно сделать
`clGetBuildInfo`, чтобы получить билд-лог (своего рода compilation error), ему
нужно давать честный `id` девайса.

build-options --- не должен быть null! Некоторые платформы могут его не
пережить. Передайте пустую строчку. Или, лучше, используйте по назначению!
Например, можно с помощью `-D` передавать дефайнами переменные.

Здесь функция-обёртка поосмысленней:

#extract("/typst/sources/aux/gpu-prelude.cpp", "buildmacro")

==== Наконец, девайс-код

```
kernel void add(global const int *a, global const int *b, global int *c) {
  *c = *a + *b;
}
```

Здесь немного нового по сравнению с С.

- `kernel` означает, что это точка входа в программу. Их может быть несколько ---
  это не совсем то же, что `main`.

- `global` означает... что означает? потом поговорим.

Давайте делать.

#let (doc, program-built) = commit(
  context-created,
  ```cpp
        const char* source = "kernel void add(global const int *a, "
            "global const int *b, global int *c) {\n"
            "    *c = *a + *b;\n"
            "}\n";
        auto source_len = std::string(source).length();

        cl_program program = wCreateProgramWithSource(context, 1, &source, &source_len);

        println(program);

        wBuildProgram(program, devices, "", nullptr, nullptr);
        ```,
)

#doc

... и ещё один указатель куда-то...

Зато, если у нас не удался `build`, мы получаем человекочитаемое сообщение об
ошибке!

Например, попытаемся вставить пробел в середину слова `void`:

#let (doc, _) = commit(
  context-created,
  ```cpp
        const char* source = "kernel vo id add(global const int *a, "
            "global const int *b, global int *c) {\n"
            "    *c = *a + *b;\n"
            "}\n";
        auto source_len = std::string(source).length();

        cl_program program = wCreateProgramWithSource(context, 1, &source, &source_len);

        println(program);

        wBuildProgram(program, devices, "", nullptr, nullptr);
        ```,
)

#doc

===== `clCreateKernel`
--- создаёт идентификатор, через который мы сможем вызывать `kernel`. Передаём
туда имя.

#let (doc, kernel-created) = commit(program-built, ```cpp
cl_kernel add = wCreateKernel(program, "add");
```, execute: false)

#doc

Теперь мы хотим передать ему аргументы и запустить его! Проблемы? Э-э-э.........
Указатели на память, что вы думаете, сработает? Ха. Где память? На девайсе. Мы
её выделили? Нет. Очень жаль. Давайте выделять...

==== Here we go again

===== `clCreateBuffer`
Выделяем память на девайсе. Нам надо только передать размер буфера, и то, как мы
хотим к нему обращаться из кернела (read only, write only, read-write). В данном
случае, мы хотим три буфера: под `a` и под `b` --- read-only, под `c` ---
write-only. Ну, мы можем оба подписать read-write, но лучше так --- так
что-нибудь оптимизировать (не надо про протокол когерентности, кэши, всё
остальное думать).

Понятно, что доступ распространяется только на кернел, с хоста-то мы и так
записать/прочитать сможем.

`clCreateBuffer` возвращает `cl_mem`, это своего рода указатель, но не
указатель. Это хендл, арифметику с ним делать нельзя.

А мы написали `int`... а что это? Понятное дело, что `int` на девайсе и `int` на
хосте могут отличаться. Ну так для этого может быть `cl_int`. На самом деле, они
даже фиксированы, не зависят от девайса. Так что это всегда 32 бита. Лучше, чем
в С! А вот `size_t` девайса мы не знаем. Точнее, можем спросить, но это будет
уже в рантайме и у конкретного девайса. Так что кернелам просто запрещено
принимать `size_t`.

#let (doc, buffers-created) = commit(kernel-created, ```cpp
cl_mem aBuffer = wCreateBuffer(context, CL_MEM_READ_ONLY, 4, nullptr);
cl_mem bBuffer = wCreateBuffer(context, CL_MEM_READ_ONLY, 4, nullptr);
cl_mem cBuffer = wCreateBuffer(context, CL_MEM_WRITE_ONLY, 4, nullptr);
```, execute: false)

#doc

===== `clSetKernelArg`
Наконец, можем накормить кернел аргументами. Указываем сюда идентификатор
кернела, номер аргумента, значение аргумента (оно --- как адрес + количество
байтов). Так как мы передаём "указатели", в качестве количества байтов у нас
`size_of(cl_mem)`

#let (doc, args-set) = commit(buffers-created, ```cpp
wSetKernelArg(add, 0, sizeof(cl_mem), &aBuffer);
wSetKernelArg(add, 1, sizeof(cl_mem), &bBuffer);
wSetKernelArg(add, 2, sizeof(cl_mem), &cBuffer);
```, execute: false)

#doc

===== `clEnqueueWriteBuffer`
В наших буферах лежит какой-то мусор, надо его наполнить. Чувствуется в названии
подвох.

===== `clCreateCommandQueue`
--- очередь команд, чего мы хотим. Принимает контекст и девайс. А ещё принимает _флажки_.
Один из них полезный --- profiling info (или как-то так), причём почти ничего не
стоит. Рассказывает, сколько времени уходит на процессы. Второй --- `out of
order executionary mode`. Не влезай, убьёт.

#let (doc, queue-created) = commit(
  args-set,
  ```cpp
        auto command_queue = wCreateCommandQueue(context, devices[0],
                                                      CL_QUEUE_PROFILING_ENABLE);
        ```,
  execute: false,
)

#doc

===== `clEnqueueWriteBuffer`
, да. Принимает `cl_mem`, указатель наш (откуда брать данные), флажок `blocking
write`. Про блокирующее чтение и запись. Мы ставим _задание на постановку в очередь_.
Если мы не поставим флажок, то оно вернётся мгновенно! И ничего не дождётся.
Имеет смысл делать передачу данных *на* девайс не блокирующей, а *с* девайса ---
блокирующей. Очередь ленивая, не будет ничего исполнять, пока мы не пнём её. Ну,
или можно пнуть через "подождать выполнения всех функций". Или спросить "#strike[а не в омах ли измеряется сопротивление] а
не закончилось ли исполнение".

- Спойлер: В конце захотим `clEnqueueReadBuffer`.

#let (doc, buffers-wrote) = commit(queue-created, ```cpp
cl_int a = 2;
cl_int b = 3;

wEnqueueWriteBuffer(command_queue, aBuffer, false, 0, 4, &a, 0,
                                                   nullptr, nullptr);
wEnqueueWriteBuffer(command_queue, bBuffer, false, 0, 4, &b, 0,
                                                   nullptr, nullptr);
```, execute: false)

#doc

===== `clEnqueueNDRangeKernel` --- урааа!
Запуск кернела. Передаём туда, очевидно, очередь и кернел. Принимает также
dimensions (who? пока передаём 1); global work size, причём через указатель
(пока тоже 1); local work size --- смело кормим null'ами, так же поступаем с
event'ами.

#let (doc, kernel-ranged) = commit(
  buffers-wrote,
  ```cpp
        size_t global_work_size = 1;
        wEnqueueNDRangeKernel(command_queue, add, 1, nullptr, &global_work_size,
                                                     nullptr, 0, nullptr, nullptr);
        ```,
  execute: false,
)

#doc

===== `clEnqueueReadBuffer`
Наконец, читаем нашу замечательную сумму двух чисел. Будем на это, во всяком
случае, надеяться.

#let (doc, buffers-read) = commit(
  kernel-ranged,
  ```cpp
        cl_int c = 0;
        wEnqueueReadBuffer(command_queue, cBuffer, true, 0, 4, &c, 0, nullptr, nullptr);
        ```,
  execute: false,
)

#doc

- Замечание к окончанию: всё, что мы `create`, хорошо бы потом `release`. А то
  может быть грустно.

#let (doc, all-released) = commit(buffers-read, ```cpp
clReleaseMemObject(aBuffer);
clReleaseMemObject(bBuffer);
clReleaseMemObject(cBuffer);
clReleaseProgram(program);
clReleaseKernel(add);
clReleaseCommandQueue(command_queue);
clReleaseContext(context);

println(c);
```)

#doc

- А если что-нибудь криво работает на девайсе... Ну, упадёт видео-драйвер. Винда
  его обычно поднимает через пару секунд, остальные --- ... поэкспериментируйте!

#TODO("Полный код")

=== Наконец, занимаемся чем-то полезным.

Хотим посчитать сумму элементов массива.

- work_item --- идейно тред. Но их много. Тысячи их.

- SINT: single instruction, multiple threads. Есть вычислительные блоки, а есть
  понятие "ядер" видеокарты. Если проводить аналогию с процессором --- ядер не так
  много. Quda-псевдо-ядра это что-то в духе конвеером (умеет считать, но не имеет
  логики управления). Конвееры объединяются в ядра, как раз. И вот эти work-item'ы
  --- запускаются на конвейерах. И они исполняют одну и ту же команду
  одновременно. Если у нас ситуация, что есть if, то сначала все исполняют одну
  ветку (часть тредов ждёт), потом наоборот. Хотя если все одновременно в одну
  ветку зашли, то ждать не будут. Особенно интересно про циклы будет, конечно...

- Соответственно, пачку тредов, исполняющихся одновременно, называем варпом. Их
  там 32 или 64, но это не очень важно. Где-то зашито, где-то можно выбрать. Это
  набор тредов, выполняющихся аппаратно синхронно. Хотя на новых видеокарточках,
  бывает, расходится, ну да неважно.

- Сэкономили на обращении к памяти. Запускаем на ядре несколько пачек тредов, и
  переключаемся между ними, когда текущая обращается к памяти. Поэтому
  принципиально кэш видеокарточкам не нужен, но кое-где его делают. Где-то для
  буферизации записи, где-то для экономии энергии.

- Так вот, `global_work_size` --- это то, сколько тредов мы хотим запустить _всего_.
  Они, конечно, не обязательно будут запущены одновременно. `local_work_size` ---
  гарантированно будет запущенно на одном аппаратном исполнителе. Зачем? У тредов
  есть оперативка девайса (global), и регистры (одного потока, их мало). А ещё!
  Есть локальная память (local). Она общая для тредов одного исполнителя.
На размер локальной группы есть ограничения, можно спросить у девайса, какой у
него лимит. По стандарту нам гарантируется, что максимальный --- ... адын! Хотя
на самом деле обычно 256, а DirectX и вовсе требует 1024. Ну и соответственно,
если сделать некратно размеру варпа, то просто часть тредов будет неактивна.

Итак, что мы теперь делаем, чтобы запустить наше `a+b`?

+ Буфера размера побольше.
+ Global work size размером в количество элементов.
+ Мы не используем никакого межтредового взаимодействия, так что `local_work_size`
  --- `null`. То есть, драйвер, разбирайся сам.
+ Получить внутри кернела его номер: `get_global_id(0)` (возвращает size_t)

+ Наконец, поменять кернел:

```
  size_t x = get_global_id(0);
  c[x] = a[x] + b[x];
```

Правда, регистры здесь все 32-битные, а size_t не обязательно 32-битное. А мы
хотим не выжирать много регистров (приватной памяти), а то часть ещё пойдёт в
глобальную память... Так что будьте внимательны, может, лучше использовать
иногда uint. Кстати, можно узнать, сколько у нас не влезло в регистры, и
поправить код. А то это самая большая просадка по времени будет.

Аналогично с `get_global_id`, есть `get_local_id` --- номер в группе, и
`get_group_id` --- номер группы.

А почему 0? А помните у нас был dimension --- 1? Это нумерация тредов. Она может
быть одномерной, двумерной, трёхмерной. Соответственно, тогда у треда будет
номер по х, номер по y, номер по z. Просто для удобства нумерации, чтобы не надо
было в случае чего делить/умножать/и так далее. Так вот 0 --- это номер
координаты.

#close-exec()
