# Сборщик прошивок Cortex-M

Образ Linux amd64 на Ubuntu 24.04 с официальным ARM GNU Toolchain
15.3.Rel2, CMake 4.4.5 и Ninja 1.13.2. Архивы инструментов проверяются по SHA-256.
Также установлены Make, Python 3, Git, SSH-клиент, обычные GCC/G++ для тестов
на хосте и ARM GDB. Совместимость с официальным toolchain важнее минимального размера.

## Сборка образа

```sh
docker build --pull -t bevice/cortex-m-builder:2026-11 .
python tests/smoke.py bevice/cortex-m-builder:2026-11
```

Версии инструментов и их SHA-256 заданы в Dockerfile. При переопределении версии
через `--build-arg` нужно также передать соответствующую контрольную сумму.
Для ARM64-хоста требуется запуск Linux amd64 через эмуляцию Docker
(`--platform linux/amd64`). Нативная сборка образа для ARM64 не поддерживается.

## Использование

```sh
docker run --rm \
  -v /path/to/src:/src:ro \
  -v /path/to/artifacts:/artifacts \
  bevice/cortex-m-builder:2026-11 \
  -DCMAKE_BUILD_TYPE=Release
```

PowerShell / Docker Desktop с Linux-контейнерами:

```powershell
New-Item -ItemType Directory -Force artifacts | Out-Null
docker run --rm -v "${PWD}:/src:ro" -v "${PWD}/artifacts:/artifacts" bevice/cortex-m-builder:2026-11 -DCMAKE_BUILD_TYPE=Debug
```

Пути внутри контейнера:

- `/src` — проект с CMakeLists.txt. Подмодули нужно получить заранее.
- `/build` — временный каталог сборки. Для повторных сборок можно подключить
  отдельный Docker volume; при смене компилятора или генератора нужен новый каталог.
- `/artifacts` — готовые `.bin`, `.elf`, `.hex` и `.map` из дерева сборки.
  Относительные подкаталоги сохраняются; файлы в корне остаются в корне.
  Каталог назначения автоматически не очищается: для отдельной сборки используйте пустой.

Проект должен сам выбирать ARM-компилятор, CPU, linker script и генерировать
нужные форматы прошивки. Образ задаёт `ARM_TOOLCHAIN_PATH=/opt/arm-gnu-toolchain`
и добавляет инструменты в PATH. Можно передать `-DCMAKE_TOOLCHAIN_FILE=/src/toolchain.cmake`.
При ошибке конфигурации, компиляции или копирования контейнер завершается с ошибкой.
Отсутствие артефактов также считается ошибкой.

## Параметры

По умолчанию используется Ninja и параллельная сборка по числу доступных CPU.

- Аргументы после имени образа передаются CMake при конфигурации.
  Это предпочтительный способ, особенно для значений с пробелами.
- `CMAKE_PARAMS` — прежний способ передать параметры конфигурации,
  например `-e CMAKE_PARAMS=-DCMAKE_BUILD_TYPE=Debug`.
- `CMAKE_BUILD_PARAMS` — параметры `cmake --build`, например `--target firmware`.
- `CMAKE_BUILD_PARALLEL_LEVEL` — число параллельных заданий, например `-e CMAKE_BUILD_PARALLEL_LEVEL=4`.
- `CMAKE_GENERATOR` — генератор, например `-e 'CMAKE_GENERATOR=Unix Makefiles'`.

Две переменные `*_PARAMS` разбиваются по пробельным символам, без интерпретации
кавычек и shell-кода. Старый Make-специфичный `-- -j 8` лучше заменить
на `CMAKE_BUILD_PARALLEL_LEVEL=8`, работающий и с Ninja, и с Make.

Для интерактивной работы или использования как окружения в CI переопределите entrypoint:

```sh
docker run --rm -it --entrypoint bash bevice/cortex-m-builder:2026-11
```

В GitLab CI для собственных команд `script` используйте:

```yaml
build:
  image:
    name: bevice/cortex-m-builder:2026-11
    entrypoint: [""]
  tags:
    - docker
  script:
    - cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
    - cmake --build build --parallel
  artifacts:
    paths:
      - build/*.elf
      - build/*.bin
      - build/*.hex
```

## Совместимость со старыми проектами

Переход с GCC 9 на GCC 15 может потребовать исправления исходников и проверки
прошивки на устройстве. CMake 4 больше не поддерживает проекты с policy version
ниже 3.5. Предпочтительно обновить `cmake_minimum_required` в проекте; для старых
зависимостей при необходимости можно передать `-DCMAKE_POLICY_VERSION_MINIMUM=3.5`.

Исторический образ 2019 года использовал Alpine со сторонней glibc и автоматически
скачивал builder.sh из GitHub. Теперь скрипт включён в образ из этого репозитория.
