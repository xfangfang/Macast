# AGENTS.md: 智能代理与技能集成

## 1. 项目概述

Macast 是一个数字媒体渲染系统，集成了智能代理和技能系统，提供高级的媒体管理、用户交互和系统优化功能。AGENTS.md 文档记录了 Macast 项目中集成的智能代理和相关技能，包括其功能、API、使用方法、项目规则和技能工作流。

Macast 项目的核心组件之一是 CLAUDE - AI 增强模块，它将先进的人工智能能力集成到系统中，提供智能媒体分析、用户交互、系统管理和网络优化功能。

## 2. 智能代理架构

Macast 项目采用模块化的智能代理架构，支持多种代理类型和技能扩展：

- **核心代理**：项目内置的主要代理组件
- **第三方代理**：通过插件系统集成的外部代理
- **技能系统**：提供可扩展的功能模块

### 2.1 代理开发规则

- 所有代理必须实现 `AgentProtocol` 接口
- 代理必须提供清晰的功能描述和使用文档
- 核心代理必须经过安全审计和性能测试
- 第三方代理必须通过插件系统进行集成，不得直接修改核心代码
- 代理必须支持热加载和卸载，不影响系统稳定性

### 2.2 技能开发规则

- 技能必须实现 `SkillProtocol` 接口
- 技能应该是模块化的，专注于单一功能
- 技能必须提供完整的 API 文档和示例代码
- 技能必须遵循安全最佳实践，特别是处理用户数据时
- 技能应该支持配置参数，允许用户自定义行为

### 2.3 安全规则

- 所有代理和技能必须遵循最小权限原则
- 处理敏感数据时必须进行加密
- 网络通信必须使用安全协议（如 HTTPS/WSS）
- 定期进行安全审计和漏洞扫描
- 严格控制第三方依赖的安全风险

### 2.4 性能规则

- 代理和技能的启动时间不应超过 1 秒
- 内存占用不应超过系统可用内存的 5%
- CPU 使用率在空闲状态下应低于 1%
- 网络请求应设置合理的超时时间
- 大量数据处理应使用异步方式

## 3. 技能调用流程

Macast 项目支持将多个技能组合成工作流，以实现复杂的功能。技能调用遵循以下模式：

### 3.1 基础技能调用

```swift
// 示例：调用单个技能
func callSkill(skillName: String, parameters: [String: Any]) {
    let skill = SkillManager.shared.getSkill(skillName)
    skill?.call(parameters: parameters) { result in
        // 处理结果
        print("技能执行结果：\(result)")
    }
}
```

### 3.2 技能工作流模式

```swift
// 示例：技能工作流
func skillWorkflow(skillSequence: [String], parameters: [String: Any]) {
    var currentIndex = 0
    
    func executeNextSkill() {
        if currentIndex < skillSequence.count {
            let skillName = skillSequence[currentIndex]
            let skill = SkillManager.shared.getSkill(skillName)
            
            skill?.call(parameters: parameters) { result in
                // 更新参数并执行下一个技能
                parameters["previousResult"] = result
                currentIndex += 1
                executeNextSkill()
            }
        } else {
            // 工作流完成
            print("工作流执行完成")
        }
    }
    
    executeNextSkill()
}
```

### 3.3 技能选择指南

| 场景 | 推荐技能 |
|------|---------|
| 创意工作（新功能、组件开发） | brainstorming |
| 创建实施计划 | writing-plans |
| 执行计划任务 | executing-plans |
| 调试问题 | systematic-debugging |
| 测试驱动开发 | test-driven-development |
| 探索代码库 | gitnexus-exploring |
| 调试代码 | gitnexus-debugging |
| 分析变更影响 | gitnexus-impact-analysis |
| 重构代码 | gitnexus-refactoring |
| PR审查 | gitnexus-pr-review |
| 完成开发分支 | finishing-a-development-branch |
| 设置工作树 | using-git-worktrees |
| 请求代码审查 | requesting-code-review |
| 接收代码审查 | receiving-code-review |
| 创建新技能 | writing-skills |
| 并行处理任务 | dispatching-parallel-agents |
| 系统性验证 | verification-before-completion |
| 使用GitNexus CLI | gitnexus-cli |
| 使用Superpowers | using-superpowers |

## 4. 可用技能列表

### 4.1 核心工作流技能

| 技能名称 | 描述 | 何时使用 |
|---------|------|---------|
| using-superpowers | 使用Superpowers技能的基础技能 | 任何需要Superpowers能力的场景 |
| brainstorming | 在任何创意工作前进行头脑风暴 | 创建新功能、组件或修改行为之前 |
| writing-plans | 创建多步骤任务的实施计划 | 有明确需求和规格时 |
| executing-plans | 执行已编写的实施计划 | 有详细计划需要执行时 |
| finishing-a-development-branch | 完成开发分支并决定集成方式 | 所有测试通过后 |
| using-git-worktrees | 设置隔离的Git工作树 | 开始新功能工作时 |

### 4.2 调试和测试技能

| 技能名称 | 描述 | 何时使用 |
|---------|------|---------|
| systematic-debugging | 系统性调试问题 | 遇到任何bug或意外行为时 |
| test-driven-development | 测试驱动开发(TDD) | 实现任何功能或bug修复时 |
| verification-before-completion | 完成前验证 | 声称工作完成前 |

### 4.3 代码探索和分析技能

| 技能名称 | 描述 | 何时使用 |
|---------|------|---------|
| gitnexus-cli | GitNexus CLI命令 | 需要运行GitNexus命令时 |
| gitnexus-exploring | 使用GitNexus探索代码库 | 了解代码工作原理时 |
| gitnexus-debugging | 使用GitNexus调试 | 调试bug或错误时 |
| gitnexus-impact-analysis | 使用GitNexus进行影响分析 | 变更代码前需要了解影响时 |
| gitnexus-refactoring | 使用GitNexus进行安全重构 | 重命名、提取或重构代码时 |
| gitnexus-pr-review | 使用GitNexus进行PR审查 | 审查Pull Request时 |

### 4.4 代码审查技能

| 技能名称 | 描述 | 何时使用 |
|---------|------|---------|
| receiving-code-review | 接收代码审查反馈 | 收到代码审查反馈时 |
| requesting-code-review | 请求代码审查 | 完成任务或功能前 |

### 4.5 技能开发技能

| 技能名称 | 描述 | 何时使用 |
|---------|------|---------|
| writing-skills | 创建和编辑技能 | 需要创建新技能时 |

### 4.6 任务管理技能

| 技能名称 | 描述 | 何时使用 |
|---------|------|---------|
| dispatching-parallel-agents | 并行分发多个代理 | 有多个独立任务需要处理时 |

### 4.7 项目特定技能

| 技能名称 | 描述 | 何时使用 |
|---------|------|---------|
| subagent-driven-development | 使用子代理驱动开发 | 需要子代理支持时 |

## 5. 技能工作流示例

### 5.1 新功能开发工作流

**概述**：从头脑风暴到完成开发的完整流程

**涉及技能**：
1. brainstorming - 头脑风暴和设计
2. writing-plans - 创建实施计划
3. using-git-worktrees - 设置隔离工作树
4. executing-plans - 执行计划任务
5. verification-before-completion - 验证完成
6. finishing-a-development-branch - 完成分支

**工作流步骤**：
```swift
// 1. 使用brainstorming进行头脑风暴
brainstorming(topic: "new feature")
  → 设计文档

// 2. 使用writing-plans创建实施计划
writing-plans(spec: designDocument)
  → 实施计划

// 3. 使用using-git-worktrees设置工作树
using-git-worktrees()
  → 隔离工作树

// 4. 使用executing-plans执行计划
executing-plans(plan: implementationPlan)
  → 任务执行

// 5. 使用verification-before-completion验证
verification-before-completion(result: executionResult)
  → 验证结果

// 6. 使用finishing-a-development-branch完成
finishing-a-development-branch(verification: verificationResult)
  → 完成分支
```

### 5.2 调试工作流

**概述**：系统性调试问题并修复

**涉及技能**：
1. systematic-debugging - 系统性调试
2. test-driven-development - 编写测试
3. verification-before-completion - 验证修复

**工作流步骤**：
```swift
// 1. 使用systematic-debugging进行调试
systematic-debugging(issue: "bug description")
  → 根本原因分析

// 2. 使用test-driven-development编写测试
test-driven-development(bug: rootCause)
  → 回归测试

// 3. 使用verification-before-completion验证
verification-before-completion(result: testResult)
  → 确认修复
```

### 5.3 代码审查工作流

**概述**：请求和接收代码审查

**涉及技能**：
1. requesting-code-review - 请求审查
2. receiving-code-review - 接收反馈
3. verification-before-completion - 验证修改

**工作流步骤**：
```swift
// 1. 使用requesting-code-review请求审查
requesting-code-review(task: "completed feature")
  → 审查反馈

// 2. 使用receiving-code-review接收反馈
receiving-code-review(feedback: reviewFeedback)
  → 理解和评估反馈

// 3. 实施修改
applyFeedback(feedback: feedback)
  → 代码修改

// 4. 使用verification-before-completion验证
verification-before-completion(result: modifiedCode)
  → 验证修改
```

### 5.4 GitNexus分析工作流

**概述**：使用GitNexus探索和分析代码库

**涉及技能**：
1. gitnexus-cli - CLI命令
2. gitnexus-exploring - 探索代码库
3. gitnexus-debugging - 调试
4. gitnexus-impact-analysis - 影响分析
5. gitnexus-refactoring - 重构
6. gitnexus-pr-review - PR审查

**工作流步骤**：
```swift
// 1. 使用gitnexus-cli进行分析
gitnexus-cli(command: "analyze")
  → 代码库索引

// 2. 使用gitnexus-exploring探索
gitnexus-exploring(query: "code structure")
  → 代码库理解

// 3. 根据需要使用其他技能
gitnexus-debugging(issue: "problem")
  → 问题调试

gitnexus-impact-analysis(target: "function")
  → 影响分析

gitnexus-refactoring(code: "to refactor")
  → 安全重构

gitnexus-pr-review(pr: "number")
  → PR审查
```

### 5.5 并行任务处理工作流

**概述**：并行处理多个独立任务

**涉及技能**：
1. dispatching-parallel-agents - 并行分发

**工作流步骤**：
```swift
// 使用dispatching-parallel-agents处理多个任务
dispatching-parallel-agents(tasks: [
    ["domain": "test file A", "goal": "fix failures"],
    ["domain": "test file B", "goal": "fix failures"],
    ["domain": "test file C", "goal": "fix failures"]
])
  → 并行处理
  → 整合结果
```

## 6. 最佳实践

### 6.1 技能调用原则

1. **先检查技能**：在任何任务开始前，先检查是否有相关的技能可用
2. **组合技能**：将多个技能组合成工作流以实现复杂功能
3. **遵循流程**：严格按照技能定义的流程执行
4. **验证结果**：在完成前使用verification-before-completion技能
5. **记录决策**：在头脑风暴阶段记录所有设计决策

### 6.2 工作流选择指南

| 场景 | 推荐工作流 |
|------|-----------|
| 开发新功能 | 新功能开发工作流 |
| 修复bug | 调试工作流 |
| 审查代码 | 代码审查工作流 |
| 分析代码库 | GitNexus分析工作流 |
| 处理多个失败测试 | 并行任务处理工作流 |

## 7. 常见问题

### 7.1 如何选择正确的技能？

- 查看技能列表和描述
- 参考技能选择指南
- 遵循技能的"何时使用"部分

### 7.2 如何组合多个技能？

- 按照工作流示例的模式
- 前一个技能的输出作为后一个技能的输入
- 使用verification-before-completion技能验证每个步骤

### 7.3 技能调用失败怎么办？

- 检查技能名称是否正确
- 查看技能的前置条件
- 参考技能的"何时使用"部分
- 使用systematic-debugging技能进行调试
