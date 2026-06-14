#include "utils.h"

#include <windows.h>

#include <iostream>
#include <string>

void CreateAndAttachConsole() {
  if (!AllocConsole()) {
    return;
  }
  FILE* fp;
  freopen_s(&fp, "CONOUT$", "w", stdout);
  freopen_s(&fp, "CONOUT$", "w", stderr);
  freopen_s(&fp, "CONIN$", "r", stdin);
  std::cout.clear();
  std::clog.clear();
  std::cerr.clear();
  std::cin.clear();
}

std::string GetExecutableDirectory() {
  char buffer[MAX_PATH];
  if (GetModuleFileNameA(nullptr, buffer, MAX_PATH) == 0) {
    return "";
  }
  std::string path(buffer);
  size_t pos = path.find_last_of('\\');
  if (pos != std::string::npos) {
    return path.substr(0, pos);
  }
  return "";
}
