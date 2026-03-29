---
name: gitnexus-exploring
description: Navigate unfamiliar code using GitNexus knowledge graph
---

# Exploring Codebases

## Quick Start
```
0. If "Index is stale" → gitnexus_analyze({})
1. READ gitnexus://context        → Get codebase overview (~150 tokens)
2. READ gitnexus://clusters       → See all functional clusters
3. READ gitnexus://cluster/{name} → Deep dive on specific cluster
```

## When to Use
- "How does authentication work?"
- "What's the project structure?"
- "Show me the main components"
- "Where is the database logic?"

## Workflow Checklist
```
Exploration Progress:
- [ ] READ gitnexus://context for codebase overview
- [ ] READ gitnexus://clusters to list all clusters
- [ ] Identify the relevant cluster by name
- [ ] READ gitnexus://cluster/{name} for cluster details
- [ ] Use gitnexus_explore for specific symbols
```

## Resource Reference

### gitnexus://context
Codebase overview. **Read first.**
```yaml
project: my-app
stats:
  files: 42
  symbols: 918
  clusters: 12
  processes: 45
tools_available: [search, explore, impact, overview, cypher]
resources_available: [clusters, processes, cluster/{name}, process/{name}]
```

### gitnexus://clusters
All functional clusters with cohesion scores.
```yaml
clusters:
  - name: "Auth"
    symbols: 47
    cohesion: 92%
  - name: "Database"
    symbols: 32
    cohesion: 88%
```

### gitnexus://cluster/{name}
Members of a specific cluster.
```yaml
name: Auth
symbols: 47
cohesion: 92%
members:
  - name: validateUser
    type: Function
    file: src/auth/validator.ts
```

### gitnexus://process/{name}
Full execution trace.
```yaml
name: LoginFlow
type: cross_community
steps:
  1: handleLogin (src/auth/handler.ts)
  2: validateUser (src/auth/validator.ts)
  3: createSession (src/auth/session.ts)
```

## Tool Reference (When Resources Aren't Enough)

### gitnexus_explore
For detailed symbol context with callers/callees:
```
gitnexus_explore({name: "validateUser", type: "symbol"})
→ Callers: loginHandler, apiMiddleware
→ Callees: checkToken, getUserById
```

### gitnexus_search
For finding code by query:
```
gitnexus_search({query: "payment validation", depth: "full"})
```

## Example: "How does payment processing work?"

```
1. READ gitnexus://context
   → 918 symbols, 12 clusters

2. READ gitnexus://clusters
   → Clusters: Auth, Payment, Database, API...

3. READ gitnexus://cluster/Payment
   → Members: processPayment, validateCard, PaymentService

4. READ gitnexus://process/CheckoutFlow
   → handleCheckout → validateCart → processPayment → sendConfirmation
```
