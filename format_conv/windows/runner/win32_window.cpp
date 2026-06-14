#include "win32_window.h"

#include <flutter_windows.h>

#include <memory>

Win32Window::Win32Window() : handle_(nullptr), child_content_(nullptr) {}

Win32Window::~Win32Window() { Destroy(); }

bool Win32Window::Create(const std::wstring& title, const POINT& origin,
                          const SIZE& size) {
  Destroy();

  WNDCLASS window_class = {};
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = L"FLUTTER_RUNNER_WIN32_WINDOW";
  window_class.style = CS_HREDRAW | CS_VREDRAW;
  window_class.lpfnWndProc = WndProc;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hIcon =
      LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APPLICATION));
  RegisterClass(&window_class);

  UINT dpi = FlutterDesktopGetDpiForMonitor(MonitorFromPoint(
      {origin.x, origin.y}, MONITOR_DEFAULTTONEAREST));

  double scale_factor = dpi / 96.0;

  HWND window = CreateWindow(
      window_class.lpszClassName, title.c_str(),
      WS_OVERLAPPEDWINDOW | WS_VISIBLE,
      origin.x, origin.y,
      static_cast<int>(size.cx * scale_factor),
      static_cast<int>(size.cy * scale_factor),
      nullptr, nullptr, window_class.hInstance, this);

  if (!window) {
    return false;
  }

  handle_ = window;
  return true;
}

void Win32Window::Destroy() {
  if (handle_) {
    DestroyWindow(handle_);
    handle_ = nullptr;
  }
}

HWND Win32Window::GetHandle() const { return handle_; }

void Win32Window::Show() {
  if (handle_) {
    ShowWindow(handle_, SW_SHOWNORMAL);
  }
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, handle_);
  RECT frame;
  GetClientRect(handle_, &frame);
  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);
}

bool Win32Window::OnCreate() {
  return true;
}

void Win32Window::OnDestroy() {}

LRESULT Win32Window::MessageHandler(HWND hwnd, UINT const message,
                                     WPARAM const wparam,
                                     LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      if (hwnd == handle_) {
        handle_ = nullptr;
        DestroyWindow(hwnd);
        PostQuitMessage(0);
      }
      break;
    case WM_SIZE:
      if (hwnd == handle_ && child_content_) {
        RECT frame;
        GetClientRect(hwnd, &frame);
        MoveWindow(child_content_, frame.left, frame.top,
                   frame.right - frame.left, frame.bottom - frame.top, true);
      }
      break;
    case WM_ACTIVATE:
      if (child_content_) {
        SetFocus(child_content_);
      }
      break;
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

LRESULT CALLBACK Win32Window::WndProc(HWND hwnd, UINT const message,
                                        WPARAM const wparam,
                                        LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    auto window = reinterpret_cast<Win32Window*>(window_struct->lpCreateParams);
    SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(window));
    window->OnCreate();
  } else if (Win32Window* window = reinterpret_cast<Win32Window*>(
                 GetWindowLongPtr(hwnd, GWLP_USERDATA))) {
    return window->MessageHandler(hwnd, message, wparam, lparam);
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}
