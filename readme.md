# Docker-сборщик arm-none-eabi-gcc

## Использование
```docker run -rm -v /path/to/src:/src -v /path/to/artifacts:/artifacts bevice/cortex-m-builder```

Используемые внутри контейнера пути:
* ```/src```   - Исходники для сборки, должен содержать CMakeLists.txt
* ```/build``` - Временная папка для сборки
* ```/artifacts``` - сюда будут скопированы *.elf *.bin из папки сборки


## Дополнительные параметры CMake
Ключи запуска cmake можно установить через переменную CMAKE_PARAMS, например: ```--env CMAKE_PARAMS="-DCMAKE_BUILD_TYPE=Debug"```
Ключи запуска сборки можно установить через переменную CMAKE_BUILD_PARAMS 

## Docker Windows
Необходимо разрешить использование [Shared Disks](https://docs.docker.com/docker-for-windows/). [Подробнее тут](https://blogs.msdn.microsoft.com/stevelasker/2016/06/14/configuring-docker-for-windows-volumes/)
Пример команды:
```docker run --rm -it -v c:/tmp/test_src:/src -v C:/tmp/fw:/artifacts bevice/cortex-m-builder```

