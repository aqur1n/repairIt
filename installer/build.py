
from io import TextIOWrapper
from os import chdir, listdir, path, mkdir
from time import time
from typing import Callable


class FilesData:
    def __init__(self, version: str, ignore: list[str], rename: dict[str, str] = {}, file_replace: dict[str, dict[str, str]] = {}) -> None:
        self.version = version
        self.ignore = ignore
        self.rename = rename
        self.file_replace = file_replace

    def replace(self, file_name: str, line: str) -> str:
        if self.file_replace.get(file_name, None) is None:
            return line
        
        for k in self.file_replace[file_name]:
            line = line.replace(k, self.file_replace[file_name][k])
        return line  
    
FILES: list[FilesData] = [
    FilesData(
        "FULL",
        ignore = ["installer", "LICENSE", "README.md", ".git", ".gitignore", "empty.lua"],
        file_replace = {"/init.lua": {"%REPAIRIT_VERSION%": "Full"}}
    ),
    FilesData(
        "LITE",
        ignore = ["installer", "LICENSE", "README.md", ".git", ".gitignore", "empty.lua", "hashes", "bios"],
        file_replace = {"/init.lua": {"%REPAIRIT_VERSION%": "Lite"}}
    )
]

# ----------------------------------------------------

class Commands:
    @staticmethod
    def parse(line: str, file_data: FilesData):
        c = getattr(
            Commands, 
            line.split(":", 1)[1].split("=", 1)[0].removesuffix("\n"), 
            None
        )
        if c:
            return c(line, file_data)
        else:
            return False
        
    # ------------------------------------------

    @staticmethod
    def ignore(line: str, file_data: FilesData):
        if line.startswith("build:ignore"):
            c = line[:-1].split("=", 1)
            if len(c) == 1 or file_data.version in c[1].split(","):
                return Commands.ignore
        elif line.startswith("--build:end"):
            return True
        return False

# ----------------------------------------------------

WORK_DIR = __file__.split("installer", 1)[0][:-1]
chdir(WORK_DIR)

if not path.exists("installer/builds/"):
    mkdir("installer/builds/")

# ----------------------------------------------------

def remove_spaces(string: str) -> str:
    string = string.removeprefix('\t').removeprefix(' ')
    if len(string) > 0 and string[0] in ('\t', ' '):
        return remove_spaces(string)
    return string

PACK_CHARS = [", ", "{ ", " }", " .. ", " = ", " == ", " ~= ", " >= ", " <= ", " > ", " < ", " ", " + ", " - ", " / ", " * "]
REPLACEMENTS = [",", "{"]
IGNORE_LINE = ["", " ", "    ", "\n"]

class Builder:
    def __init__(self, file_data: FilesData) -> None:
        self.file_data = file_data

        self.files: list[str] = []
        self.directories: list[str] = []

    def pack(self, line: str, file_name: str) -> str:
        lines = []
        for i, l in enumerate(line.split("\"")):
            if i % 2 == 0:
                chunk = l.split("--", 1)[0].replace("  ", " ")
                if i == 0: 
                    chunk = remove_spaces(chunk)

                for char in PACK_CHARS:
                    chunk = chunk.replace(char, char.replace(" ", ""))
                for k in REPLACEMENTS:
                    chunk = chunk.replace(k + "", k)

                lines.append(chunk)
            else:
                lines.append(l)

        return "\"".join(lines)
    
    def scan(self, dir: str = WORK_DIR) -> None:
        for file in listdir(dir):
            if file in self.file_data.ignore:
                continue
            p = f"{dir}\\{file}".replace("\\\\", "\\")

            if path.isfile(p):
                self.files.append(p)
            else:
                self.directories.append(p)
                self.scan(dir = p)

    def write_directories(self, file: TextIOWrapper) -> None:
        file.write("dirs" + ",".join(directory.removeprefix(WORK_DIR).replace("\\", "/") for directory in self.directories) + "")

    def write_files(self, file: TextIOWrapper) -> None:
        for fl in self.files:
            command: bool | Callable = False
            name = fl.removeprefix(WORK_DIR).replace('\\', '/')

            file.write(f"file={self.file_data.rename.get(name, name)}")
            with open(fl, mode = "r", encoding = "utf-8") as code:
                for l in code.readlines():
                    d = l.split("--", 1)
                    if len(d) > 1 and d[1].startswith("build:"):
                        command = Commands.parse(d[1], self.file_data)
                    elif d[0] in IGNORE_LINE:
                        continue
                    
                    if command is False:
                        file.write(self.pack(self.file_data.replace(name, l.replace("\n", "")), name))
                    else:
                        c = command(self.file_data.replace(name, l.replace("\n", "")), self.file_data)
                        if isinstance(c, str):
                            file.write(self.pack(c, name))
                        elif c is True:
                            command = False

                file.write("")
            print(f"    {self.file_data.rename.get(name, name)} упакован.")

# ----------------------------------------------------

def build(file_data: FilesData) -> None:
    builder = Builder(file_data)

    print(f"=-=-=-=-=-=-=-= {file_data.version} =-=-=-=-=-=-=-=")
    print(f"[{file_data.version}] Сканирование файлов...")
    builder.scan()
    print(f"[{file_data.version}] Сканирование завершено. Директорий: {len(builder.directories)}, файлов: {len(builder.files)}")

    print(f"[{file_data.version}] Создание общего файла...")
    with open(f"installer/builds/{int(time())}-{file_data.version[0] + file_data.version[1:].lower()}.rbf", mode = "w", encoding = "utf-8") as file:
        print(f"[{file_data.version}] Запись директорий...")
        builder.write_directories(file)

        print(f"[{file_data.version}] Запись файлов...")
        builder.write_files(file)
        file.close()

# ----------------------------------------------------

for file_data in FILES:
    build(file_data)
print("Готово.")
