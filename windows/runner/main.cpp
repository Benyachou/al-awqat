#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// Mode fond d'écran (argument --fond) : glisse la fenêtre derrière les icônes
// du bureau, sur l'écran principal, à la place de l'image de fond.
static void AttachToDesktop(HWND hwnd) {
  HWND progman = ::FindWindow(L"Progman", nullptr);
  // Demande à l'explorateur de créer la couche WorkerW derrière les icônes.
  ::SendMessageTimeout(progman, 0x052C, 0xD, 0x1, SMTO_NORMAL, 1000, nullptr);

  // Windows 11 24H2 et suivants : les icônes (SHELLDLL_DefView) et l'image de
  // fond (WorkerW) sont des enfants de Progman. On s'accroche à Progman, entre
  // les deux : WorkerW est recréé par Windows (Windows + D), pas Progman.
  HWND parent = progman;
  HWND icons = ::FindWindowEx(progman, nullptr, L"SHELLDLL_DefView", nullptr);
  if (!icons || !::FindWindowEx(progman, nullptr, L"WorkerW", nullptr)) {
    // Versions précédentes : WorkerW est la fenêtre qui suit celle des icônes.
    parent = nullptr;
    icons = nullptr;
    ::EnumWindows(
        [](HWND top, LPARAM out) -> BOOL {
          if (::FindWindowEx(top, nullptr, L"SHELLDLL_DefView", nullptr)) {
            *reinterpret_cast<HWND*>(out) =
                ::FindWindowEx(nullptr, top, L"WorkerW", nullptr);
          }
          return TRUE;
        },
        reinterpret_cast<LPARAM>(&parent));
  }
  if (!parent) {
    return;
  }

  MONITORINFO info = {sizeof(info)};
  ::GetMonitorInfo(::MonitorFromPoint({0, 0}, MONITOR_DEFAULTTOPRIMARY), &info);
  // rcWork = l'écran sans la barre des tâches, qui cacherait le bas de l'app.
  RECT area = info.rcWork;
  ::MapWindowPoints(nullptr, parent, reinterpret_cast<POINT*>(&area), 2);

  ::SetWindowLongPtr(hwnd, GWL_STYLE, WS_CHILD | WS_VISIBLE);
  if (icons) {
    // Un enfant de Progman doit être « layered » pour être dessiné.
    ::SetWindowLongPtr(hwnd, GWL_EXSTYLE, WS_EX_LAYERED);
    ::SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA);
  }
  ::SetParent(hwnd, parent);
  ::SetWindowPos(hwnd, HWND_TOP, area.left, area.top, area.right - area.left,
                 area.bottom - area.top, SWP_NOACTIVATE | SWP_FRAMECHANGED);

  if (icons) {
    // 24H2 : la fenêtre doit rester juste sous les icônes. L'affichage de la
    // première image la remonte au-dessus, donc on la replace régulièrement.
    static HWND wallpaper, icons_layer;
    wallpaper = hwnd;
    icons_layer = icons;
    ::SetTimer(nullptr, 0, 1000, [](HWND, UINT, UINT_PTR, DWORD) {
      if (::GetWindow(icons_layer, GW_HWNDNEXT) != wallpaper) {
        ::SetWindowPos(wallpaper, icons_layer, 0, 0, 0, 0,
                       SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
      }
    });
  }
}

// Mode écran de veille (argument /s, envoyé par Windows) : plein écran sans
// bordure, au-dessus de tout, sur l'écran principal.
static void ShowAsScreenSaver(HWND hwnd) {
  MONITORINFO info = {sizeof(info)};
  ::GetMonitorInfo(::MonitorFromPoint({0, 0}, MONITOR_DEFAULTTOPRIMARY), &info);
  const RECT& area = info.rcMonitor;
  ::SetWindowLongPtr(hwnd, GWL_STYLE, WS_POPUP);
  ::SetWindowPos(hwnd, HWND_TOPMOST, area.left, area.top,
                 area.right - area.left, area.bottom - area.top,
                 SWP_FRAMECHANGED);
  ::ShowCursor(FALSE);
}

// Vrai si ce message est un geste de l'utilisateur qui doit fermer l'écran de
// veille : touche, clic, molette, ou souris déplacée de plus de 10 pixels.
static bool EndsScreenSaver(const MSG& msg) {
  static POINT start;
  static bool has_start = false;
  switch (msg.message) {
    case WM_KEYDOWN:
    case WM_SYSKEYDOWN:
    case WM_LBUTTONDOWN:
    case WM_RBUTTONDOWN:
    case WM_MBUTTONDOWN:
    case WM_MOUSEWHEEL:
      return true;
    case WM_MOUSEMOVE:
      if (!has_start) {
        start = msg.pt;
        has_start = true;
        return false;
      }
      return abs(msg.pt.x - start.x) > 10 || abs(msg.pt.y - start.y) > 10;
  }
  return false;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  bool wallpaper_mode = false;
  bool screensaver_mode = false;
  for (const std::string& argument : command_line_arguments) {
    if (argument == "--fond") {
      wallpaper_mode = true;
    }
    // Windows lance un écran de veille avec /s (l'afficher), /p (aperçu dans
    // les réglages) ou /c (configurer). Seul /s nous intéresse.
    if (argument.size() >= 2 && argument[0] == '/') {
      const char mode = static_cast<char>(tolower(argument[1]));
      if (mode == 's') {
        screensaver_mode = true;
      } else if (mode == 'p' || mode == 'c') {
        return EXIT_SUCCESS;
      }
    }
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"al_awqat", origin, size)) {
    return EXIT_FAILURE;
  }
  if (wallpaper_mode) {
    AttachToDesktop(window.GetHandle());
  }
  if (screensaver_mode) {
    ShowAsScreenSaver(window.GetHandle());
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    if (screensaver_mode && EndsScreenSaver(msg)) {
      // Ferme la fenêtre proprement avant de sortir : sans ça le moteur
      // Flutter est détruit trop tard et l'app plante à la fermeture.
      window.Destroy();
      break;
    }
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
