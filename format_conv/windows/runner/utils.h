#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>

// Creates a console for the process if one is not already attached.
void CreateAndAttachConsole();

// Gets the path to the directory containing the running executable.
std::string GetExecutableDirectory();

#endif  // RUNNER_UTILS_H_
