
from os import chdir, listdir, path
from time import time

IGNORE_FILES = ["installer", "LICENSE", "README.md", ".git", ".gitignore"]
IGNORE_LINE = ["", " ", "    ", "\n"]
WORK_DIR = __file__.split("installer", 1)[0][:-1]

chdir(WORK_DIR)

directories: list[str] = []
files: list[str] = []

def remove_spaces(string: str) -> str:
    string = string.removeprefix('\t').removeprefix(' ')
    if string[0] in ('\t', ' '):
        return remove_spaces(string)
    return string

PACK_CHARS = [", ", "{ ", " }", " .. ", " = ", " == ", " ~= ", " ", " "]
def pack(line: str) -> str:
    for char in PACK_CHARS:
        line = line.replace(char, char.replace(" ", ""))
    return line

print("Сканирование файлов...")
def scan(dir: str) -> None:
    for file in listdir(dir):
        if file in IGNORE_FILES:
            continue
        p = f"{dir}\\{file}".replace("\\\\", "\\")

        if path.isfile(p):
            files.append(p)
        else:
            directories.append(p)
            scan(p)
scan(WORK_DIR)
print(f"Сканирование завершено. Директорий: {len(directories)}, файлов: {len(files)}")

def full() -> None:
    print("[FULL] Создание общего файла...")
    file = open(f"installer/builds/{int(time())}-Full.rbf", mode = "w", encoding = "utf-8")

    print("[FULL] Запись директорий...")
    file.write("dirs" + ",".join(directory.removeprefix(WORK_DIR).replace("\\", "/") for directory in directories) + "")

    print("[FULL] Запись файлов...")
    for fl in files:
        file.write(f"file={(fl.removeprefix(WORK_DIR).replace('\\', '/'))}")
        with open(fl, mode = "r", encoding = "utf-8") as code:
            for l in code.readlines():
                line = l.split("--", 1)[0]
                if line in IGNORE_LINE:
                    continue

                file.write(pack(remove_spaces(l).replace("\n", "").replace("  ", " ")))
            file.write("")
    file.close()

full()
print("Готово.")
