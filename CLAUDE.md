<!-- gitnexus:start -->
# GitNexus MCP

This project is indexed by GitNexus, providing AI agents with deep code intelligence.

## Project: Macast

| Metric | Count |
|--------|-------|
| Files | 112 |
| Symbols | 1102 |
| Relationships | 3783 |
| Communities | 175 |
| Processes | 75 |

## Quick Start

```
1. READ gitnexus://context        → Get codebase overview (~150 tokens)
2. READ gitnexus://clusters       → See all functional clusters
3. READ gitnexus://cluster/{name} → Deep dive on specific cluster
4. gitnexus_search(query)         → Find code by query
```

## Available Resources

| Resource | Purpose |
|----------|---------|
| `gitnexus://context` | Codebase stats, tools, and resources overview |
| `gitnexus://clusters` | All clusters with symbol counts and cohesion |
| `gitnexus://cluster/{name}` | Cluster members and details |
| `gitnexus://processes` | All execution flows with types |
| `gitnexus://process/{name}` | Full process trace with steps |
| `gitnexus://schema` | Graph schema for Cypher queries |

## Available Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `search` | Semantic + keyword search | Finding code by query |
| `overview` | List clusters & processes | Understanding architecture |
| `explore` | Deep dive on symbol/cluster/process | Detailed investigation |
| `impact` | Blast radius analysis | Before making changes |
| `cypher` | Raw graph queries | Complex analysis |

## Workflow Examples

### Exploring the Codebase
```
READ gitnexus://context           → Stats and overview
READ gitnexus://clusters          → Find relevant cluster
READ gitnexus://cluster/Auth      → Explore Auth cluster
gitnexus_explore("validateUser", "symbol") → Detailed symbol info
```

### Planning a Change
```
gitnexus_impact("UserService", "upstream") → See what breaks
READ gitnexus://processes         → Check affected flows
gitnexus_explore("LoginFlow", "process") → Trace execution
```

## Graph Schema

**Nodes:** File, Function, Class, Interface, Method, Community, Process

**Relationships:** CALLS, IMPORTS, EXTENDS, IMPLEMENTS, DEFINES, MEMBER_OF, STEP_IN_PROCESS

```cypher
// Example: Find callers of a function
MATCH (caller)-[:CodeRelation {type: 'CALLS'}]->(f:Function {name: "myFunc"})
RETURN caller.name, caller.filePath
```

<!-- gitnexus:end -->
