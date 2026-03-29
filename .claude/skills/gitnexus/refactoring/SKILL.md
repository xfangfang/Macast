---
name: gitnexus-refactoring
description: Plan safe refactors using blast radius and dependency mapping
---

# Refactoring with GitNexus

## Quick Start
```
0. If "Index is stale" → gitnexus_analyze({})
1. gitnexus_impact({target, direction: "upstream"}) → Map all dependents
2. READ gitnexus://schema                           → Understand graph structure
3. gitnexus_cypher                                  → Find all references
```

## When to Use
- "Rename this function safely"
- "Extract this into a module"
- "Split this service"
- "Refactor without breaking things"

## Checklists

### Rename Symbol
```
Rename Refactoring:
- [ ] gitnexus_impact(oldName, "upstream") — find all callers
- [ ] gitnexus_search(oldName) — find string literals
- [ ] Check for reflection/dynamic references
- [ ] Update in order: interface → implementation → usages
- [ ] Run tests for affected processes
```

### Extract Module
```
Extract Module:
- [ ] gitnexus_explore(target, "symbol") — map dependencies
- [ ] gitnexus_impact(target, "upstream") — find callers
- [ ] READ gitnexus://cluster/{name} — check cohesion
- [ ] Define new module interface
- [ ] Update imports across affected files
```

### Split Function
```
Split Function:
- [ ] gitnexus_explore(target, "symbol") — understand callees
- [ ] Group related logic
- [ ] gitnexus_impact — verify callers won't break
- [ ] Create new functions
- [ ] Update callers
```

## Resource Reference

### gitnexus://schema
Graph structure for Cypher queries:
```yaml
nodes: [Function, Class, Method, Community, Process]
relationships: [CALLS, IMPORTS, EXTENDS, MEMBER_OF]

example_queries:
  find_callers: |
    MATCH (caller)-[:CodeRelation {type: 'CALLS'}]->(f:Function {name: "X"})
    RETURN caller.name
```

### gitnexus://cluster/{name}
Check if extraction preserves cohesion:
```yaml
name: Payment
cohesion: 92%
members: [processPayment, validateCard, PaymentService]
```

## Tool Reference

### Finding all references
```cypher
MATCH (caller)-[:CodeRelation {type: 'CALLS'}]->(f:Function {name: "validateUser"})
RETURN caller.name, caller.filePath
ORDER BY caller.filePath
```

### Finding imports of a module
```cypher
MATCH (importer)-[:CodeRelation {type: 'IMPORTS'}]->(f:File {name: "utils.ts"})
RETURN importer.name, importer.filePath
```

## Example: Safely Rename `validateUser` to `authenticateUser`

```
1. gitnexus_impact({target: "validateUser", direction: "upstream"})
   → loginHandler, apiMiddleware, testUtils

2. gitnexus_search({query: "validateUser"})
   → Found in: config.json (dynamic reference!)

3. READ gitnexus://processes
   → LoginFlow, TokenRefresh, APIGateway

4. Plan update order:
   1. Update declaration in auth.ts
   2. Update config.json string reference
   3. Update loginHandler
   4. Update apiMiddleware
   5. Run tests for LoginFlow, TokenRefresh
```

## Refactoring Safety Rules

| Risk Factor | Mitigation |
|-------------|------------|
| Many callers (>5) | Update in small batches |
| Cross-cluster | Coordinate with other teams |
| String references | Search for dynamic usage |
| Reflection | Check for dynamic invocation |
| External exports | May break downstream repos |
