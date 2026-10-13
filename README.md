Intern Error-Corrector (x86 Assembly) 

A low-level file-processing program written in x86 MASM assembly, reading temperature measurements from a file, converting ASCII values to integers, and displaying them in reverse order.

What It Does
Reads a data file of comma-delimited temperature readings using buffered file I/O
Parses and converts ASCII digit strings to integer values using string primitives (no library string-to-int calls)
Displays results in reverse order using custom procedures
Uses reusable macros for common I/O operations (prompting, reading, and displaying strings) to avoid duplicated inline code
Why This Is Here

Low-level systems programming — manual memory/register management, stack-based argument passing, and macro design — that most web/app development work never touches directly, but that builds a real understanding of what's happening underneath higher-level languages.

Tech Stack
Language: x86 Assembly (MASM), using the Irvine32 library
Toolchain: Visual Studio (MASM build tools)
Build

Open Project6.sln in Visual Studio with MASM/Irvine32 configured, then Build → Run.
