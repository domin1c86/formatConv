#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates a Win32Window with |title| that is positioned and sized using
  // |origin| and |size|. Returns true if the window was created successfully.
  bool Create(const std::wstring& title, const POINT& origin, const SIZE& size);

  // Release OS resources associated with this window.
  void Destroy();

  // Getter for the handle of the underlying Windows HWND.
  HWND GetHandle() const;

  // If |visible| is true, shows the window. Otherwise, hides it.
  void Show();

 protected:
  // Processes and route salient window messages for mouse handling,
  // size change and DPI. Delegates handling of these to member overloads that
  // inheriting classes can handle.
  virtual LRESULT MessageHandler(HWND hwnd, UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

  virtual bool OnCreate();
  virtual void OnDestroy();

  // Sets the child content (Flutter view) to fill the parent window.
  void SetChildContent(HWND content);

 private:
  HWND handle_;

  // Stores the child content (Flutter view) that fills the client area.
  HWND child_content_;

  // Called when the DPI changes for the window.
  void OnDpiScale(UINT dpi);

  // Called when the window is resized.
  void OnResize(UINT width, UINT height);

  static LRESULT CALLBACK WndProc(HWND hwnd, UINT const message,
                                   WPARAM const wparam,
                                   LPARAM const lparam) noexcept;
};

#endif  // RUNNER_WIN32_WINDOW_H_
