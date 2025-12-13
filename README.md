<img width="1483" height="1483" alt="Capture d&#39;écran 2025-12-12 201411" src="https://github.com/user-attachments/assets/867dbb28-d958-48f6-aac0-167ac885613f" />

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

✔️ -> Included <br />
🛠️ -> W.I.P <br /> 
❌ -> Not included <br />

Functions: ✔️ <br />
Upvalues: ❌ <br />


Variables: ✔️ <br />
Globals: ✔️ <br />


Ifs: 🛠️ <br />
Whiles: ❌ <br />
Repeats: ❌ <br />
Loops: 🛠️ <br />


New Table: ✔️ <br />
Set Table Key: ✔️ <br />

Logical Sets: 🛠️
Special Logical Sets: 🛠️

Others:❓ <br />
