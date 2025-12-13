![nemo](https://i.ibb.co/nqb4T0NW/Capture-d-cran-2025-12-12-201411.png)

# Nemo
A early and fast LuaU decompiler.

## Info
Nemo is a small project I wanted to work on to provide a good, free, and love-made decompiler. Help is always appreciated.

## How do I use it?

Use this script to redefine the decompile function:

```lua
    assert(disassemble, "Your exploit does not support Nemo")
  assert(getscriptbytecode, "Your exploit does not support Nemo")
  assert(loadstring, "Your exploit does not support Nemo")
  
  local Decompiler = loadstring(game:HttpGet("https://raw.githubusercontent.com/golddemon1973/Nemo/main/decompiler.luau"))()

  getgenv().decompile = function (scriptinst)
    return Decompiler:Decompile(disassemble(scriptinst))
  end

  warn("Loaded Nemo!")
```

# Contributors
> golddemon1973 - Creator

Thanks to everyone that will, or has contributed to this project. Thank you.

# Features

✔️ -> Included
🛠️ -> W.I.P
❌ -> Not included

Functions: ✔️
Upvalues: ❌


Variables: ✔️
Globals: ✔️


Ifs: 🛠️
Whiles: ❌
Repeats: ❌
Loops: 🛠️


New Table: 🛠️
Set Table Key: 🛠️


Others: 🛠️
