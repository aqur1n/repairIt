
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
        ignore = ["installer", "LICENSE", "README.md", ".git", ".gitignore"],
        file_replace = {"/init.lua": {"%REPAIRIT_VERSION%": "Full"}}
    ),
    FilesData(
        "LITE",
        ignore = ["installer", "LICENSE", "README.md", ".git", ".gitignore", "hashes", "bios"],
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
def pack(line: str) -> str:
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

# ----------------------------------------------------

def scan(files: list, directories: list, files_data: FilesData, dir: str = WORK_DIR) -> None:
    for file in listdir(dir):
        if file in files_data.ignore:
            continue
        p = f"{dir}\\{file}".replace("\\\\", "\\")

        if path.isfile(p):
            files.append(p)
        else:
            directories.append(p)
            scan(
                files, 
                directories, 
                files_data,
                dir = p
            )

def write_directories(file: TextIOWrapper, directories: list[str]) -> None:
    file.write("dirs" + ",".join(directory.removeprefix(WORK_DIR).replace("\\", "/") for directory in directories) + "")

def write_files(file: TextIOWrapper, files: list[str], files_data: FilesData) -> None:
    for fl in files:
        command: bool | Callable = False
        name = fl.removeprefix(WORK_DIR).replace('\\', '/')

        file.write(f"file={files_data.rename.get(name, name)}")
        with open(fl, mode = "r", encoding = "utf-8") as code:
            for l in code.readlines():
                d = l.split("--", 1)
                if len(d) > 1 and d[1].startswith("build:"):
                    command = Commands.parse(d[1], files_data)
                elif d[0] in IGNORE_LINE:
                    continue
            
                if command is False:
                    file.write(pack(files_data.replace(name, l.replace("\n", ""))))
                else:
                    c = command(files_data.replace(name, l.replace("\n", "")), files_data)
                    if isinstance(c, str):
                        file.write(pack(c))
                    elif c is True:
                        command = False

            file.write("")

# ----------------------------------------------------

def build(file_data: FilesData) -> None:
    directories: list[str] = []
    files: list[str] = []

    print(f"[{file_data.version}] Сканирование файлов...")
    scan(files, directories, files_data = file_data)
    print(f"[{file_data.version}] Сканирование завершено. Директорий: {len(directories)}, файлов: {len(files)}")

    print(f"[{file_data.version}] Создание общего файла...")
    file = open(
        f"installer/builds/{int(time())}-{file_data.version[0] + file_data.version[1:].lower()}.rbf", 
        mode = "w", 
        encoding = "utf-8"
    )

    print(f"[{file_data.version}] Запись директорий...")
    write_directories(file, directories)

    print(f"[{file_data.version}] Запись файлов...")
    write_files(file, files, file_data)
    file.close()

# ----------------------------------------------------

for file_data in FILES:
    build(file_data)
print("Готово.")
