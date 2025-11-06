# Godot MCP Setup Guide

Este proyecto incluye el servidor MCP "Godot MCP" (https://github.com/Coding-Solo/godot-mcp) ya clonado y compilado. Con él, un asistente compatible puede:

- Abrir el editor de Godot de este proyecto
- Ejecutar el juego en modo debug y capturar logs/errores
- Inspeccionar la estructura del proyecto y crear/editar escenas y nodos

## Requisitos
- Godot 4 instalado en tu sistema (probado con 4.4)
- Node.js y npm instalados

## Configuración para GitHub Copilot (VS Code)

**IMPORTANTE**: A partir de VS Code 1.102+, el soporte MCP integrado usa la API `languageModels.chatRequestAccess`. Sin embargo, GitHub Copilot aún no expone herramientas MCP de forma nativa sin extensiones adicionales.

### Opción 1: Usar extensión MCP Bridge (recomendado)

Instala una extensión que exponga servidores MCP a Copilot Chat:

```
jasonkneen.mcpsx-run
```

**Configuración**:
1. Instala la extensión desde el Marketplace
2. Abre su panel de configuración (icono en Activity Bar o Command Palette)
3. Añade un nuevo servidor MCP:
   - Name/Label: `Godot`
   - Command: `<ruta-absoluta-a-este-proyecto>/tools/godot-mcp/run-godot-mcp.sh`
   - Args: (vacío)
4. Activa/habilita el servidor
5. Recarga VS Code si es necesario
6. Abre Copilot Chat y verifica que aparecen las herramientas MCP

### Opción 2: Configuración manual (experimental)

Si prefieres no usar extensiones, añade esto en tu `settings.json` del workspace (`.vscode/settings.json`):

```json
{
  "languageModels.mcp.servers": {
    "godot": {
      "command": "<ruta-absoluta-a-este-proyecto>/tools/godot-mcp/run-godot-mcp.sh",
      "args": []
    }
  }
}
```

**Nota**: Esta opción puede no funcionar con GitHub Copilot actual ya que Copilot no consume servidores MCP del sistema de VS Code por defecto.

## Ejecutar el servidor manualmente

Si la extensión lo requiere o para testing:
```bash
cd <ruta-a-este-proyecto>
./tools/godot-mcp/run-godot-mcp.sh
```

El servidor autodetecta `godot-preview` (o `godot4`/`godot`) y queda corriendo en stdio.

## Variables de entorno útiles
- `GODOT_PATH`: Ruta al ejecutable de Godot si la autodetección falla (p. ej. `/usr/bin/godot4` o AppImage).
- `DEBUG`: Ponla a `true` para logs detallados del servidor MCP.

## Problemas comunes
- Si el asistente no ve las herramientas MCP, revisa que la extensión puente esté habilitada y el servidor registrado.
- Si Godot no abre o no se encuentra, define `GODOT_PATH`.
