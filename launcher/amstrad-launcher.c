/* Amstrad PC1512 launcher: starts local\dist\86Box.exe on the local\amstrad VM
   with the cabinet and CRT settings, without PowerShell or a console window.

   It lives in the project root. On the first launch, when the VM does not
   exist yet, it runs scripts\prepare-vm.ps1 once, hidden, to create it.
   Arguments: -NoCRT disables the CRT shader (same as scripts\launch.ps1).

   Everything is relative to the launcher's folder, so a release runs from
   wherever it is unpacked. The user's firmware goes in roms\machines\<model>. */
#define WIN32_LEAN_AND_MEAN
#ifndef UNICODE
#    define UNICODE
#endif
#ifndef _UNICODE
#    define _UNICODE
#endif
#include <windows.h>
#include <shellapi.h>
#include <wchar.h>

static wchar_t root[MAX_PATH];

static void
fail(const wchar_t *what, const wchar_t *detail)
{
    wchar_t text[2048];
    _snwprintf(text, 2048, L"%ls\n\n%ls", what, detail);
    text[2047] = 0;
    MessageBoxW(NULL, text, L"Amstrad PC1512", MB_OK | MB_ICONERROR);
}

static void
path(wchar_t *out, const wchar_t *relative)
{
    _snwprintf(out, MAX_PATH, L"%ls\\%ls", root, relative);
    out[MAX_PATH - 1] = 0;
}

static int
exists(const wchar_t *file)
{
    return GetFileAttributesW(file) != INVALID_FILE_ATTRIBUTES;
}

/* First launch only: create the VM, its media copies and configuration. */
static int
prepare_vm(void)
{
    wchar_t script[MAX_PATH], cmd[2 * MAX_PATH + 128];
    path(script, L"scripts\\prepare-vm.ps1");
    _snwprintf(cmd, sizeof(cmd) / sizeof(cmd[0]),
               L"powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%ls\" -Name amstrad",
               script);
    cmd[sizeof(cmd) / sizeof(cmd[0]) - 1] = 0;

    STARTUPINFOW        si = { sizeof(si) };
    PROCESS_INFORMATION pi;
    if (!CreateProcessW(NULL, cmd, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, root, &si, &pi)) {
        fail(L"Could not run the first-launch VM setup.", script);
        return 0;
    }
    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD code = 1;
    GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    if (code) {
        fail(L"The first-launch VM setup failed. Check that the PC1512 ROMs (40043, 40044, 40078) are in "
             L"roms\\machines\\pc1512 beside Amstrad PC1512.exe.",
             L"Run scripts\\prepare-vm.ps1 from PowerShell to see the details.");
        return 0;
    }
    return 1;
}

int WINAPI
wWinMain(HINSTANCE inst, HINSTANCE prev, LPWSTR args, int show)
{
    (void) inst;
    (void) prev;
    (void) show;

    GetModuleFileNameW(NULL, root, MAX_PATH);
    wchar_t *slash = wcsrchr(root, L'\\');
    if (slash)
        *slash = 0;

    int crt = 1, argc = 0;
    LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);
    for (int i = 1; argv && i < argc; i++)
        if (!_wcsicmp(argv[i], L"-NoCRT") || !_wcsicmp(argv[i], L"/NoCRT"))
            crt = 0;
    LocalFree(argv);
    (void) args;

    wchar_t exe[MAX_PATH], roms[MAX_PATH], vm[MAX_PATH], cfg[MAX_PATH], cabinet[MAX_PATH], crtlog[MAX_PATH], workdir[MAX_PATH];
    path(exe, L"local\\dist\\86Box.exe");
    path(roms, L"roms");
    path(vm, L"local\\amstrad");
    path(cfg, L"local\\amstrad\\86box.cfg");
    path(cabinet, L"assets\\front\\pc1512-front.png");
    path(crtlog, L"local\\amstrad\\crt.log");
    path(workdir, L"local\\dist");

    if (!exists(exe)) {
        fail(L"The emulator is not built yet.", L"Run scripts\\build.ps1 first.");
        return 1;
    }
    if (!exists(cabinet)) {
        fail(L"The cabinet image is missing.", cabinet);
        return 1;
    }
    if (!exists(cfg) && !prepare_vm())
        return 1;

    /* Same environment as scripts\launch.ps1; the emulator inherits it. */
    SetEnvironmentVariableW(L"AMSTRAD_CABINET", cabinet);
    SetEnvironmentVariableW(L"AMSTRAD_CRT", crt ? L"1" : L"0");
    SetEnvironmentVariableW(L"AMSTRAD_CRT_LOG", crtlog);
    SetEnvironmentVariableW(L"AMSTRAD_TEST_PATTERN", NULL);

    wchar_t cmd[6 * MAX_PATH];
    _snwprintf(cmd, sizeof(cmd) / sizeof(cmd[0]),
               L"\"%ls\" -P \"%ls\" -R \"%ls\" -O \"%ls\\global.cfg\" -L \"%ls\\86box.log\"",
               exe, vm, roms, vm, vm);
    cmd[sizeof(cmd) / sizeof(cmd[0]) - 1] = 0;

    STARTUPINFOW        si = { sizeof(si) };
    PROCESS_INFORMATION pi;
    if (!CreateProcessW(exe, cmd, NULL, NULL, FALSE, 0, NULL, workdir, &si, &pi)) {
        fail(L"Could not start the emulator.", exe);
        return 1;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 0;
}
