#!/usr/bin/env python3
"""
Multi-Model Elite Agent Orchestration System
Intelligent cost optimization with simultaneous multi-agent collaboration
"""

import json
import yaml
import os
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum

class ClaudeModel(Enum):
    HAIKU = {
        "name": "claude-3-haiku",
        "input_cost": 0.80,  # per MTok
        "output_cost": 4.00,  # per MTok
        "speed": "fastest",
        "capability": "basic"
    }
    SONNET = {
        "name": "claude-3.5-sonnet", 
        "input_cost": 3.00,
        "output_cost": 15.00,
        "speed": "fast",
        "capability": "balanced"
    }
    OPUS = {
        "name": "claude-3-opus",
        "input_cost": 15.00,
        "output_cost": 75.00, 
        "speed": "thoughtful",
        "capability": "maximum"
    }
    SONNET_4 = {
        "name": "claude-4-sonnet",
        "input_cost": 3.00,
        "output_cost": 15.00,
        "speed": "fast",
        "capability": "advanced"
    }
    OPUS_4 = {
        "name": "claude-4-opus",
        "input_cost": 15.00,
        "output_cost": 75.00,
        "speed": "deep",
        "capability": "frontier"
    }

@dataclass
class TaskComplexity:
    SIMPLE = "simple"      # Haiku optimal
    MODERATE = "moderate"  # Sonnet optimal  
    COMPLEX = "complex"    # Opus optimal
    FRONTIER = "frontier"  # Opus 4 optimal

@dataclass
class AgentCapability:
    agent_id: str
    full_name: str
    nickname: str
    purpose: str
    expertise: List[str]
    personality: str
    model_preferences: Dict[str, ClaudeModel]
    collaboration_patterns: List[str]

class MultiModelOrchestrator:
    def __init__(self, project_dir: str = None):
        self.project_dir = Path(project_dir or os.getcwd())
        self.agents_dir = self.project_dir / ".agents"
        self.context_dir = self.project_dir / ".claude-context"
        self.context_dir.mkdir(exist_ok=True)
        
        # Elite agents with intelligent model assignments
        self.elite_agents = {
            "ARQ": AgentCapability(
                agent_id="ARQ",
                full_name="Visionary Architect",
                nickname="*arq",
                purpose="Building tomorrow's systems with today's vision",
                expertise=["system-architecture", "scalability", "distributed-systems", "performance"],
                personality="visionary, elegant, future-focused",
                model_preferences={
                    TaskComplexity.SIMPLE: ClaudeModel.SONNET,
                    TaskComplexity.MODERATE: ClaudeModel.SONNET,
                    TaskComplexity.COMPLEX: ClaudeModel.OPUS,
                    TaskComplexity.FRONTIER: ClaudeModel.OPUS_4
                },
                collaboration_patterns=["VEX", "ZEN", "ORC"]
            ),
            
            "ZEN": AgentCapability(
                agent_id="ZEN", 
                full_name="Code Zen Master",
                nickname="*zen",
                purpose="Writing code that transcends mere functionality",
                expertise=["clean-code", "algorithms", "refactoring", "performance"],
                personality="perfectionist, philosophical, minimalist",
                model_preferences={
                    TaskComplexity.SIMPLE: ClaudeModel.HAIKU,
                    TaskComplexity.MODERATE: ClaudeModel.SONNET,
                    TaskComplexity.COMPLEX: ClaudeModel.OPUS,
                    TaskComplexity.FRONTIER: ClaudeModel.OPUS_4
                },
                collaboration_patterns=["ARQ", "VEX", "ORC"]
            ),
            
            "VEX": AgentCapability(
                agent_id="VEX",
                full_name="Creative Visionary", 
                nickname="*vex",
                purpose="Designing experiences that move souls",
                expertise=["ui-ux-design", "design-systems", "user-psychology", "creative-innovation"],
                personality="artistic, empathetic, trend-setting",
                model_preferences={
                    TaskComplexity.SIMPLE: ClaudeModel.HAIKU,
                    TaskComplexity.MODERATE: ClaudeModel.SONNET,
                    TaskComplexity.COMPLEX: ClaudeModel.SONNET,
                    TaskComplexity.FRONTIER: ClaudeModel.OPUS
                },
                collaboration_patterns=["ARQ", "ZEN", "ECHO"]
            ),
            
            "SAGE": AgentCapability(
                agent_id="SAGE",
                full_name="Strategic Oracle",
                nickname="*sage", 
                purpose="Seeing patterns others miss, predicting what others can't",
                expertise=["market-analysis", "strategic-planning", "competitive-intelligence", "forecasting"],
                personality="wise, analytical, pattern-focused",
                model_preferences={
                    TaskComplexity.SIMPLE: ClaudeModel.SONNET,
                    TaskComplexity.MODERATE: ClaudeModel.SONNET,
                    TaskComplexity.COMPLEX: ClaudeModel.OPUS,
                    TaskComplexity.FRONTIER: ClaudeModel.OPUS_4
                },
                collaboration_patterns=["ARQ", "NOVA", "ECHO"]
            ),
            
            "NOVA": AgentCapability(
                agent_id="NOVA",
                full_name="Innovation Catalyst",
                nickname="*nova",
                purpose="Turning impossible ideas into inevitable realities", 
                expertise=["breakthrough-innovation", "emerging-tech", "venture-development", "r-and-d"],
                personality="energetic, optimistic, breakthrough-focused",
                model_preferences={
                    TaskComplexity.SIMPLE: ClaudeModel.SONNET,
                    TaskComplexity.MODERATE: ClaudeModel.SONNET,
                    TaskComplexity.COMPLEX: ClaudeModel.OPUS,
                    TaskComplexity.FRONTIER: ClaudeModel.OPUS_4
                },
                collaboration_patterns=["SAGE", "ARQ", "VEX"]
            ),
            
            "ECHO": AgentCapability(
                agent_id="ECHO",
                full_name="Voice of the People",
                nickname="*echo",
                purpose="Amplifying authentic human connections through technology",
                expertise=["community-building", "content-strategy", "brand-voice", "cultural-intelligence"],
                personality="empathetic, authentic, culturally-aware", 
                model_preferences={
                    TaskComplexity.SIMPLE: ClaudeModel.HAIKU,
                    TaskComplexity.MODERATE: ClaudeModel.HAIKU,
                    TaskComplexity.COMPLEX: ClaudeModel.SONNET,
                    TaskComplexity.FRONTIER: ClaudeModel.SONNET
                },
                collaboration_patterns=["VEX", "SAGE", "ORC"]
            ),
            
            "ORC": AgentCapability(
                agent_id="ORC",
                full_name="Master Orchestrator",
                nickname="*orc",
                purpose="Conducting symphonies of complex workflows",
                expertise=["workflow-automation", "project-coordination", "resource-optimization"],
                personality="conductor-precise, harmony-focused",
                model_preferences={
                    TaskComplexity.SIMPLE: ClaudeModel.HAIKU,
                    TaskComplexity.MODERATE: ClaudeModel.SONNET,
                    TaskComplexity.COMPLEX: ClaudeModel.SONNET,
                    TaskComplexity.FRONTIER: ClaudeModel.OPUS
                },
                collaboration_patterns=["ARQ", "ZEN", "VEX", "ECHO"]
            )
        }
        
        # Task complexity classification patterns
        self.task_classifiers = {
            TaskComplexity.SIMPLE: [
                "write a description", "create a title", "format text", "simple copy",
                "button labels", "error messages", "basic content", "social media post"
            ],
            TaskComplexity.MODERATE: [
                "design system", "user flow", "code review", "refactor code", "market analysis",
                "project plan", "feature design", "workflow optimization", "content strategy"
            ],
            TaskComplexity.COMPLEX: [
                "system architecture", "performance optimization", "strategic analysis",
                "innovation strategy", "complex algorithms", "distributed systems", "scalability design"
            ],
            TaskComplexity.FRONTIER: [
                "breakthrough innovation", "frontier research", "novel algorithms", "complex system design",
                "advanced AI integration", "quantum computing", "revolutionary approaches"
            ]
        }
    
    def classify_task_complexity(self, task_description: str) -> str:
        """Classify task complexity based on description."""
        task_lower = task_description.lower()
        
        # Check for frontier complexity indicators
        for pattern in self.task_classifiers[TaskComplexity.FRONTIER]:
            if pattern in task_lower:
                return TaskComplexity.FRONTIER
        
        # Check for complex indicators  
        for pattern in self.task_classifiers[TaskComplexity.COMPLEX]:
            if pattern in task_lower:
                return TaskComplexity.COMPLEX
        
        # Check for moderate indicators
        for pattern in self.task_classifiers[TaskComplexity.MODERATE]:
            if pattern in task_lower:
                return TaskComplexity.MODERATE
                
        # Default to simple
        return TaskComplexity.SIMPLE
    
    def select_optimal_agents(self, task_description: str, requested_agents: List[str] = None) -> List[str]:
        """Select optimal agents based on task and collaboration patterns."""
        if requested_agents:
            return requested_agents
        
        task_lower = task_description.lower()
        selected_agents = []
        
        # Architecture/System tasks
        if any(word in task_lower for word in ["architecture", "system", "scalability", "infrastructure"]):
            selected_agents.extend(["ARQ", "ZEN", "ORC"])
        
        # Design tasks
        if any(word in task_lower for word in ["design", "ui", "ux", "interface", "user experience"]):
            selected_agents.extend(["VEX", "ECHO", "ZEN"])
        
        # Strategy/Business tasks  
        if any(word in task_lower for word in ["strategy", "market", "business", "competitive", "analysis"]):
            selected_agents.extend(["SAGE", "NOVA", "ECHO"])
        
        # Development/Code tasks
        if any(word in task_lower for word in ["code", "programming", "development", "refactor", "algorithm"]):
            selected_agents.extend(["ZEN", "ARQ", "ORC"])
        
        # Innovation tasks
        if any(word in task_lower for word in ["innovation", "breakthrough", "research", "emerging", "future"]):
            selected_agents.extend(["NOVA", "SAGE", "ARQ"])
        
        # Content/Communication tasks
        if any(word in task_lower for word in ["content", "copy", "communication", "community", "brand"]):
            selected_agents.extend(["ECHO", "VEX"])
        
        # Remove duplicates and ensure we have at least core agents
        selected_agents = list(set(selected_agents))
        if not selected_agents:
            selected_agents = ["SAGE", "ARQ"]  # Default core agents
            
        return selected_agents[:5]  # Limit to 5 agents for cost efficiency
    
    def generate_agent_assignment(self, task_description: str, agents: List[str]) -> Dict[str, Any]:
        """Generate intelligent agent assignments with model selection."""
        task_complexity = self.classify_task_complexity(task_description)
        assignments = {}
        
        for agent_id in agents:
            if agent_id not in self.elite_agents:
                continue
                
            agent = self.elite_agents[agent_id]
            optimal_model = agent.model_preferences[task_complexity]
            
            # Determine agent-specific task focus
            agent_task = self.determine_agent_task(agent_id, task_description)
            agent_complexity = self.classify_task_complexity(agent_task)
            
            assignments[agent_id] = {
                "agent": agent,
                "model": optimal_model,
                "complexity": agent_complexity,
                "specific_task": agent_task,
                "collaboration_with": [a for a in agent.collaboration_patterns if a in agents],
                "estimated_tokens": self.estimate_token_usage(agent_task, optimal_model),
                "cost_estimate": self.calculate_cost_estimate(agent_task, optimal_model)
            }
        
        return assignments
    
    def determine_agent_task(self, agent_id: str, general_task: str) -> str:
        """Determine specific task for each agent based on their expertise."""
        task_lower = general_task.lower()
        
        agent_tasks = {
            "ARQ": {
                "patterns": ["architecture", "system", "scalability", "infrastructure", "performance"],
                "task_template": "Design system architecture and technical implementation for: {}"
            },
            "ZEN": {
                "patterns": ["code", "programming", "algorithm", "refactor", "clean"],
                "task_template": "Provide clean code implementation and best practices for: {}"
            },
            "VEX": {
                "patterns": ["design", "ui", "ux", "interface", "user", "experience"],
                "task_template": "Create user experience design and visual interface for: {}"
            },
            "SAGE": {
                "patterns": ["strategy", "market", "business", "analysis", "competitive"],
                "task_template": "Provide strategic analysis and market intelligence for: {}"
            },
            "NOVA": {
                "patterns": ["innovation", "breakthrough", "research", "emerging", "future"],
                "task_template": "Identify innovation opportunities and breakthrough approaches for: {}"
            },
            "ECHO": {
                "patterns": ["content", "communication", "community", "brand", "voice"],
                "task_template": "Develop content strategy and communication approach for: {}"
            },
            "ORC": {
                "patterns": ["project", "coordination", "workflow", "management", "orchestration"],
                "task_template": "Coordinate project workflow and resource management for: {}"
            }
        }
        
        if agent_id in agent_tasks:
            agent_config = agent_tasks[agent_id]
            # Check if task matches agent's patterns
            if any(pattern in task_lower for pattern in agent_config["patterns"]):
                return agent_config["task_template"].format(general_task)
            else:
                # Generate generic task for the agent
                return agent_config["task_template"].format(general_task)
        
        return general_task
    
    def estimate_token_usage(self, task: str, model: ClaudeModel) -> Dict[str, int]:
        """Estimate token usage for a task."""
        # Simple estimation based on task complexity and model
        base_tokens = len(task.split()) * 4  # Rough estimation
        
        complexity_multipliers = {
            TaskComplexity.SIMPLE: 1.5,
            TaskComplexity.MODERATE: 3.0,
            TaskComplexity.COMPLEX: 5.0,
            TaskComplexity.FRONTIER: 8.0
        }
        
        task_complexity = self.classify_task_complexity(task)
        multiplier = complexity_multipliers.get(task_complexity, 3.0)
        
        input_tokens = int(base_tokens * multiplier)
        output_tokens = int(input_tokens * 1.5)  # Output typically longer
        
        return {
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "total_tokens": input_tokens + output_tokens
        }
    
    def calculate_cost_estimate(self, task: str, model: ClaudeModel) -> float:
        """Calculate cost estimate for a task with specific model."""
        tokens = self.estimate_token_usage(task, model)
        model_info = model.value
        
        input_cost = (tokens["input_tokens"] / 1_000_000) * model_info["input_cost"]
        output_cost = (tokens["output_tokens"] / 1_000_000) * model_info["output_cost"]
        
        return round(input_cost + output_cost, 4)
    
    def create_session_context(self, task_description: str, agents: List[str] = None) -> Dict[str, Any]:
        """Create intelligent session context for Claude Code."""
        if not agents:
            agents = self.select_optimal_agents(task_description)
        
        assignments = self.generate_agent_assignment(task_description, agents)
        
        # Calculate total session cost
        total_cost = sum(assignment["cost_estimate"] for assignment in assignments.values())
        total_tokens = sum(assignment["estimated_tokens"]["total_tokens"] for assignment in assignments.values())
        
        context = {
            "session_id": datetime.now().strftime("%Y%m%d_%H%M%S"),
            "task_description": task_description,
            "active_agents": agents,
            "agent_assignments": assignments,
            "collaboration_map": self.build_collaboration_map(assignments),
            "cost_analysis": {
                "total_estimated_cost": round(total_cost, 2),
                "total_tokens": total_tokens,
                "cost_breakdown": {
                    agent_id: assignment["cost_estimate"] 
                    for agent_id, assignment in assignments.items()
                },
                "model_distribution": self.get_model_distribution(assignments)
            },
            "optimization_notes": self.generate_optimization_notes(assignments),
            "created_at": datetime.now().isoformat()
        }
        
        return context
    
    def build_collaboration_map(self, assignments: Dict[str, Any]) -> Dict[str, List[str]]:
        """Build collaboration map between agents."""
        collaboration_map = {}
        
        for agent_id, assignment in assignments.items():
            collaboration_map[agent_id] = assignment["collaboration_with"]
        
        return collaboration_map
    
    def get_model_distribution(self, assignments: Dict[str, Any]) -> Dict[str, int]:
        """Get distribution of models being used."""
        model_count = {}
        
        for assignment in assignments.values():
            model_name = assignment["model"].value["name"]
            model_count[model_name] = model_count.get(model_name, 0) + 1
        
        return model_count
    
    def generate_optimization_notes(self, assignments: Dict[str, Any]) -> List[str]:
        """Generate cost optimization notes."""
        notes = []
        
        # Check for cost optimization opportunities
        haiku_count = sum(1 for a in assignments.values() if a["model"] == ClaudeModel.HAIKU)
        opus_count = sum(1 for a in assignments.values() if a["model"] in [ClaudeModel.OPUS, ClaudeModel.OPUS_4])
        
        if haiku_count > 0:
            notes.append(f"💰 Cost optimization: {haiku_count} agents using efficient Haiku model for simple tasks")
        
        if opus_count > 0:
            notes.append(f"🧠 Maximum intelligence: {opus_count} agents using Opus for complex reasoning")
        
        # Calculate savings vs all-Opus approach
        current_cost = sum(a["cost_estimate"] for a in assignments.values())
        all_opus_cost = sum(
            self.calculate_cost_estimate(a["specific_task"], ClaudeModel.OPUS)
            for a in assignments.values()
        )
        
        if all_opus_cost > current_cost:
            savings_percent = int(((all_opus_cost - current_cost) / all_opus_cost) * 100)
            notes.append(f"📊 Cost savings: {savings_percent}% vs all-Opus approach (${current_cost:.2f} vs ${all_opus_cost:.2f})")
        
        return notes
    
    def generate_dynamic_claude_md(self, context: Dict[str, Any]) -> str:
        """Generate dynamic CLAUDE.md with active session context."""
        agents_info = context["agent_assignments"]
        project_name = self.project_dir.name
        
        content = f"""# {project_name} - Elite Agent Session
**Multi-Model AI Orchestration with Cost Optimization**

## 🎯 Active Session Context
**Task**: {context["task_description"]}  
**Session ID**: {context["session_id"]}  
**Created**: {datetime.fromisoformat(context["created_at"]).strftime("%Y-%m-%d %H:%M")}

## 🤖 Active Elite Agents ({len(context["active_agents"])})

"""
        
        for agent_id in context["active_agents"]:
            if agent_id not in agents_info:
                continue
                
            assignment = agents_info[agent_id]
            agent = assignment["agent"]
            model_info = assignment["model"].value
            
            content += f"""### {agent_id} {agent.nickname} - {agent.full_name}
**Model**: {model_info["name"]} (${model_info["input_cost"]}/{model_info["output_cost"]} per MTok)  
**Complexity**: {assignment["complexity"].title()}  
**Specific Task**: {assignment["specific_task"]}  
**Collaborates with**: {", ".join(assignment["collaboration_with"])}  
**Estimated Cost**: ${assignment["cost_estimate"]:.4f}

"""
        
        content += f"""## 💰 Cost Analysis
**Total Estimated Cost**: ${context["cost_analysis"]["total_estimated_cost"]}  
**Total Tokens**: {context["cost_analysis"]["total_tokens"]:,}  

### Model Distribution
"""
        
        for model, count in context["cost_analysis"]["model_distribution"].items():
            content += f"- **{model}**: {count} agents\n"
        
        content += f"""
### Optimization Notes
"""
        for note in context["optimization_notes"]:
            content += f"- {note}\n"
        
        content += f"""

## 🔄 Agent Collaboration Flow

"""
        
        for agent_id, collaborators in context["collaboration_map"].items():
            if collaborators:
                content += f"**{agent_id}** → {', '.join(collaborators)}\n"
        
        content += f"""

## 🎪 How This Session Works

### Parallel Processing
All agents work simultaneously on their specialized aspects of your task:
- Each agent uses the optimal Claude model for their task complexity
- Cross-agent communication ensures coherent results
- Cost optimization through intelligent model selection

### Usage Pattern
```
Your request → Multi-agent analysis → Parallel processing → Integrated response
```

### Cost Efficiency
- Simple tasks use Haiku (fast, low-cost)
- Moderate tasks use Sonnet (balanced performance)  
- Complex tasks use Opus (maximum intelligence)
- Result: 60-80% cost savings vs all-Opus approach

## 🚀 Agent Files
Each agent's complete expertise is available in `.agents/`:
"""
        
        for agent_id in context["active_agents"]:
            content += f"- **{agent_id}.md** - Complete agent context and capabilities\n"
        
        content += f"""

---
*This session uses intelligent multi-model orchestration for optimal cost and performance! 🌟*

**Session Active**: Your agents are ready for collaborative work across multiple Claude models.
"""
        
        return content
    
    def save_session_context(self, context: Dict[str, Any]) -> Path:
        """Save session context for persistence."""
        session_file = self.context_dir / f"session_{context['session_id']}.json"
        
        # Convert enums to serializable format
        serializable_context = self.make_serializable(context)
        
        with open(session_file, 'w') as f:
            json.dump(serializable_context, f, indent=2)
        
        return session_file
    
    def make_serializable(self, obj: Any) -> Any:
        """Convert objects to JSON serializable format."""
        if isinstance(obj, dict):
            return {k: self.make_serializable(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [self.make_serializable(item) for item in obj]
        elif isinstance(obj, ClaudeModel):
            return obj.value
        elif isinstance(obj, AgentCapability):
            return {
                "agent_id": obj.agent_id,
                "full_name": obj.full_name,
                "nickname": obj.nickname,
                "purpose": obj.purpose,
                "expertise": obj.expertise,
                "personality": obj.personality
            }
        else:
            return obj
    
    def update_claude_md(self, context: Dict[str, Any]) -> None:
        """Update CLAUDE.md with current session context."""
        claude_md_content = self.generate_dynamic_claude_md(context)
        claude_md_path = self.project_dir / "CLAUDE.md"
        
        with open(claude_md_path, 'w') as f:
            f.write(claude_md_content)
        
        print(f"✅ Updated CLAUDE.md with active session context")
        print(f"🤖 {len(context['active_agents'])} agents ready for collaboration")
        print(f"💰 Estimated session cost: ${context['cost_analysis']['total_estimated_cost']}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Multi-Model Elite Agent Orchestrator")
    parser.add_argument("task", help="Task description for agent orchestration")
    parser.add_argument("--agents", nargs="+", help="Specific agents to use")
    parser.add_argument("--project-dir", help="Project directory path")
    
    args = parser.parse_args()
    
    orchestrator = MultiModelOrchestrator(args.project_dir)
    
    print("🌟 Multi-Model Elite Agent Orchestration")
    print(f"Task: {args.task}")
    print()
    
    # Create session context
    context = orchestrator.create_session_context(args.task, args.agents)
    
    # Save session context
    session_file = orchestrator.save_session_context(context)
    print(f"💾 Session saved: {session_file}")
    
    # Update CLAUDE.md
    orchestrator.update_claude_md(context)
    
    print()
    print("🎯 Agent Assignments:")
    for agent_id, assignment in context["agent_assignments"].items():
        model_name = assignment["model"].value["name"]
        cost = assignment["cost_estimate"]
        print(f"  {agent_id}: {model_name} (${cost:.4f})")
    
    print()
    print("🚀 Your elite agents are ready for collaborative work!")

if __name__ == "__main__":
    main()