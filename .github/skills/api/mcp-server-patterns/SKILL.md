---
name: mcp-server-patterns
description: "Use when: building MCP (Model Context Protocol) servers, exposing tools to AI agents, or creating MCP integrations."
user-invocable: true
---

# MCP Server Patterns

## When to Activate

- Building MCP servers for AI agent integration
- Exposing tools and resources to LLMs
- Implementing MCP protocol handlers

## Core Concepts

### MCP Server Structure

```python
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent


app = Server("my-server")


@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="search_users",
            description="Search users by name or email",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string"}
                },
                "required": ["query"],
            },
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "search_users":
        results = await db.search_users(arguments["query"])
        return [TextContent(type="text", text=json.dumps(results))]
```

## Best Practices

- Keep tools focused — one responsibility per tool
- Use clear, descriptive tool names and descriptions
- Validate inputs with JSON Schema
- Return structured data (JSON)
- Handle errors gracefully with error messages
- Document authentication requirements
