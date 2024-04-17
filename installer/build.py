
from io import TextIOWrapper
from os import chdir, listdir, path
from time import time


class FilesData:
    def __init__(self, ignore: list[str], rename: dict[str, str] = {}) -> None:
        self.ignore = ignore
        self.rename = rename

# ----------------------------------------------------

FILES: dict[str, FilesData] = {
    "FULL": FilesData(
        ignore = ["installer", "LICENSE", "README.md", ".git", ".gitignore"]
    ),
    "LITE": FilesData(
        ignore = ["installer", "LICENSE", "README.md", ".git", ".gitignore", "hashes", "bios"]
    )
}
WORK_DIR = __file__.split("installer", 1)[0][:-1]

chdir(WORK_DIR)

# ----------------------------------------------------

def remove_spaces(string: str) -> str:
    string = string.removeprefix('\t').removeprefix(' ')
    if len(string) > 0 and string[0] in ('\t', ' '):
        return remove_spaces(string)
    return string

PACK_CHARS = [", ", "{ ", " }", " .. ", " = ", " == ", " ~= ", " >= ", " <= ", " > ", " < ", " ", " + ", " - ", " / ", " * "]
REPLACEMENTS = {
    ",": ",", 
    "{": "{"
}
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
                chunk = chunk.replace(k, REPLACEMENTS[k])
                
            lines.append(chunk)
        else:
            lines.append(l)

    return "\"".join(lines)

def scan(files: list, directories: list, files_data: FilesData = FILES["FULL"], dir: str = WORK_DIR) -> None:
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
                files_data = files_data,
                dir = p
            )

def write_directories(file: TextIOWrapper, directories: list[str]) -> None:
    file.write("dirs" + ",".join(directory.removeprefix(WORK_DIR).replace("\\", "/") for directory in directories) + "")

def write_files(file: TextIOWrapper, files: list[str], files_data: FilesData = FILES["FULL"]) -> None:
    for fl in files:
        name = fl.removeprefix(WORK_DIR).replace('\\', '/')
        file.write(f"file={files_data.rename.get(name, name)}")
        with open(fl, mode = "r", encoding = "utf-8") as code:
            for l in code.readlines():
                if l.split("--", 1)[0] in IGNORE_LINE:
                    continue
                file.write(pack(l.replace("\n", "")))
            file.write("")

# ----------------------------------------------------

def build(version: str) -> None:
    directories: list[str] = []
    files: list[str] = []

    print(f"[{version}] Сканирование файлов...")
    scan(files, directories, files_data = FILES[version])
    print(f"[{version}] Сканирование завершено. Директорий: {len(directories)}, файлов: {len(files)}")

    print(f"[{version}] Создание общего файла...")
    file = open(f"installer/builds/{int(time())}-{version[0] + version[1:].lower()}.rbf", mode = "w", encoding = "utf-8")

    print(f"[{version}] Запись директорий...")
    write_directories(file, directories)

    print(f"[{version}] Запись файлов...")
    write_files(file, files, files_data = FILES[version])
    file.close()

# ----------------------------------------------------

for key in list(FILES.keys()):
    build(key)
print("Готово.")
