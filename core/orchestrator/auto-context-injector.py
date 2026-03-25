#!/usr/bin/env python3
"""
Automatic Context Injection System
Seamlessly integrates elite agents into Claude Code sessions
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List

# Add current directory to path for imports
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

try:
    from multi_model_orchestrator import MultiModelOrchestrator
except ImportError:
    # Fallback if import fails
    print("Warning: MultiModelOrchestrator not available, running in basic mode", file=sys.stderr)
    MultiModelOrchestrator = None

class AutoContextInjector:
    def __init__(self, project_dir: str = None):
        self.project_dir = Path(project_dir or os.getcwd())
        self.agents_dir = self.project_dir / ".agents"
        self.context_dir = self.project_dir / ".claude-context"
        self.orchestrator = MultiModelOrchestrator(str(self.project_dir))
        
        # Ensure context directory exists
        self.context_dir.mkdir(exist_ok=True)
    
    def detect_claude_code_session(self) -> bool:
        """Detect if this is a Claude Code session."""
        # Check for Claude Code environment indicators
        return (
            os.getenv("CLAUDE_CODE_SESSION") is not None or
            os.getenv("ANTHROPIC_CLAUDE") is not None or
            self.project_dir.name.lower() in ["viber", "claude-workspace"] or
            (self.project_dir / ".claude-session").exists()
        )
    
    def should_auto_inject(self) -> bool:
        """Determine if auto-injection should occur."""
        return (
            self.agents_dir.exists() and
            any(self.agents_dir.glob("*.md")) and
            (self.detect_claude_code_session() or self.has_elite_config())
        )
    
    def has_elite_config(self) -> bool:
        """Check if project has elite agent configuration."""
        config_files = [
            ".elite-agents.yaml",
            ".elite-project.yaml",
            ".claude-context/project-intelligence.yaml"
        ]
        
        return any((self.project_dir / config).exists() for config in config_files)
    
    def get_recent_session(self) -> Dict[str, Any]:
        """Get the most recent session context."""
        session_files = list(self.context_dir.glob("session_*.json"))
        
        if not session_files:
            return None
        
        # Get most recent session
        latest_session = max(session_files, key=lambda f: f.stat().st_mtime)
        
        try:
            with open(latest_session) as f:
                return json.load(f)
        except Exception:
            return None
    
    def analyze_current_context(self) -> str:
        """Analyze current context to determine likely task."""
        context_clues = []
        
        # Check recent files
        recent_files = []
        for file_path in self.project_dir.rglob("*"):
            if file_path.is_file() and not str(file_path).startswith("."):
                try:
                    stat = file_path.stat()
                    # Files modified in last 24 hours
                    if (datetime.now().timestamp() - stat.st_mtime) < 86400:
                        recent_files.append(file_path)
                except:
                    continue
        
        # Analyze recent activity patterns
        if any("package.json" in str(f) for f in recent_files):
            context_clues.append("Node.js development")
        
        if any(str(f).endswith(('.py', '.js', '.ts')) for f in recent_files):
            context_clues.append("Active development")
        
        if any("README" in str(f) or "docs" in str(f) for f in recent_files):
            context_clues.append("Documentation work")
        
        # Check git activity
        git_dir = self.project_dir / ".git"
        if git_dir.exists():
            context_clues.append("Version controlled project")
        
        # Generate context description
        if context_clues:
            return f"Continue working on {self.project_dir.name} involving: {', '.join(context_clues[:3])}"
        else:
            return f"General development work on {self.project_dir.name} project"
    
    def create_auto_context(self) -> Dict[str, Any]:
        """Create automatic context for current session."""
        # Check for recent session
        recent_session = self.get_recent_session()
        
        if recent_session:
            # Update existing session
            task_description = recent_session.get("task_description", self.analyze_current_context())
            agents = recent_session.get("active_agents", [])
        else:
            # Create new context
            task_description = self.analyze_current_context()
            agents = None
        
        # Create context with orchestrator
        context = self.orchestrator.create_session_context(task_description, agents)
        
        # Add auto-injection metadata
        context["auto_injected"] = True
        context["injection_time"] = datetime.now().isoformat()
        context["previous_session"] = recent_session["session_id"] if recent_session else None
        
        return context
    
    def inject_context(self) -> bool:
        """Inject context into current session."""
        try:
            # Create auto context
            context = self.create_auto_context()
            
            # Save session context
            session_file = self.orchestrator.save_session_context(context)
            
            # Update CLAUDE.md with enhanced context
            self.create_enhanced_claude_md(context)
            
            # Create session marker
            self.create_session_marker(context)
            
            return True
            
        except Exception as e:
            print(f"Error injecting context: {e}", file=sys.stderr)
            return False
    
    def create_enhanced_claude_md(self, context: Dict[str, Any]) -> None:
        """Create enhanced CLAUDE.md with automatic context."""
        project_name = self.project_dir.name
        agents_info = context["agent_assignments"]
        
        # Get available agents from .agents directory
        available_agents = []
        if self.agents_dir.exists():
            for agent_file in self.agents_dir.glob("*.md"):
                available_agents.append(agent_file.stem)
        
        content = f"""# {project_name} - Elite AI Assistant
**Automatic Multi-Model Agent Integration Active**

## 🤖 Auto-Detected Context
**Current Focus**: {context["task_description"]}  
**Session**: {context["session_id"]} (Auto-injected: {datetime.fromisoformat(context["injection_time"]).strftime("%H:%M")})  
**Active Agents**: {len(context["active_agents"])} specialized agents ready

## 🧠 Claude Code Integration

### Automatic Agent Awareness
Claude Code is now automatically aware of your elite agents and will:
- **Use agent expertise** when relevant to your requests
- **Optimize costs** by selecting appropriate models for complexity
- **Coordinate multiple agents** for complex tasks
- **Remember context** across conversation sessions

### Current Agent Assignment
"""
        
        for agent_id in context["active_agents"]:
            if agent_id not in agents_info:
                continue
                
            assignment = agents_info[agent_id]
            agent = assignment["agent"]
            model_info = assignment["model"].value
            
            content += f"""
**{agent_id} ({agent.nickname})** - *{agent.full_name}*  
Model: {model_info["name"]} | Focus: {assignment["specific_task"][:60]}...  
Cost: ${assignment["cost_estimate"]:.4f} | Collaborates with: {", ".join(assignment["collaboration_with"])}
"""
        
        content += f"""

### Cost Optimization Active
- **Total Session Cost**: ${context["cost_analysis"]["total_estimated_cost"]}
- **Token Estimate**: {context["cost_analysis"]["total_tokens"]:,} tokens
- **Model Mix**: {len(context["cost_analysis"]["model_distribution"])} different models for optimal efficiency
- **Savings**: ~{int(((0.16 - context["cost_analysis"]["total_estimated_cost"]) / 0.16) * 100) if context["cost_analysis"]["total_estimated_cost"] < 0.16 else 0}% vs single-model approach

## 🎯 Available Expertise

### Elite Agents Ready ({len(available_agents)})
"""
        
        agent_descriptions = {
            "ARQ": "🏗️ System Architecture & Scalability Design",
            "ZEN": "🧘 Clean Code & Algorithm Optimization", 
            "VEX": "🎨 UI/UX Design & User Experience",
            "SAGE": "🔮 Strategic Analysis & Market Intelligence",
            "NOVA": "🚀 Innovation & Breakthrough Thinking",
            "ECHO": "🎤 Content Strategy & Community Building",
            "ORC": "🎼 Project Coordination & Workflow Optimization"
        }
        
        for agent in available_agents:
            description = agent_descriptions.get(agent, f"💡 {agent} Specialist")
            content += f"- **{agent}** - {description} | File: `.agents/{agent}.md`\n"
        
        content += f"""

## 🔄 How This Works

### Seamless Integration
When you make requests, Claude Code automatically:
1. **Analyzes task complexity** and selects optimal agents
2. **Chooses cost-effective models** (Haiku/Sonnet/Opus) per agent
3. **Coordinates multiple agents** for comprehensive responses
4. **Learns from interactions** to improve future recommendations

### No Manual Management Needed
- ✅ Agents activate automatically based on your requests
- ✅ Cost optimization happens transparently  
- ✅ Context persists across sessions
- ✅ Expertise scales with project complexity

### Example Usage Patterns
```
You: "Help me optimize this React component"
→ ZEN (Haiku) provides clean code practices
→ VEX (Haiku) suggests UX improvements  
→ Cost: ~$0.01, Response: <30 seconds

You: "Design a scalable architecture for 1M users"  
→ ARQ (Opus) creates comprehensive architecture
→ ZEN (Sonnet) provides implementation patterns
→ ORC (Sonnet) creates deployment strategy
→ Cost: ~$0.05, Response: High-quality system design
```

## 📊 Session Intelligence

### Learning & Adaptation
- **Project Context**: Understands your project type and tech stack
- **Usage Patterns**: Learns which agents are most effective for your tasks
- **Cost Optimization**: Continuously improves cost/performance ratio
- **Quality Tracking**: Measures agent effectiveness and adjusts accordingly

### Memory & Continuity  
- **Persistent Context**: Remembers architectural decisions and patterns
- **Cross-Session Learning**: Builds on previous conversations and solutions
- **Project Evolution**: Adapts as your project grows and changes
- **Team Alignment**: Maintains consistency across different development aspects

---

## 🚀 Your Elite AI Team is Active!

**No setup required** - your agents are already integrated and ready to assist with world-class expertise, intelligent cost optimization, and seamless collaboration.

*Ask anything related to your project and watch your elite AI team automatically coordinate to provide the best possible assistance!* ✨
"""
        
        # Write enhanced CLAUDE.md
        claude_md_path = self.project_dir / "CLAUDE.md"
        with open(claude_md_path, 'w') as f:
            f.write(content)
    
    def create_session_marker(self, context: Dict[str, Any]) -> None:
        """Create session marker for Claude Code detection."""
        marker_file = self.project_dir / ".claude-session"
        
        marker_data = {
            "session_active": True,
            "session_id": context["session_id"],
            "auto_injected": True,
            "agents_count": len(context["active_agents"]),
            "estimated_cost": context["cost_analysis"]["total_estimated_cost"],
            "created": datetime.now().isoformat()
        }
        
        with open(marker_file, 'w') as f:
            json.dump(marker_data, f, indent=2)
    
    def run_auto_injection(self) -> None:
        """Run the complete auto-injection process."""
        if not self.should_auto_inject():
            return
        
        print("🤖 Elite Agent Auto-Integration Active", file=sys.stderr)
        
        if self.inject_context():
            recent_session = self.get_recent_session()
            agent_count = len(recent_session.get("active_agents", [])) if recent_session else 0
            estimated_cost = recent_session.get("cost_analysis", {}).get("total_estimated_cost", 0) if recent_session else 0
            
            print(f"✅ {agent_count} agents ready | Est. cost: ${estimated_cost:.3f}", file=sys.stderr)
            print("💡 Your elite AI team is automatically integrated and ready!", file=sys.stderr)
        else:
            print("⚠️ Auto-integration failed - agents available manually", file=sys.stderr)

def main():
    """Main entry point for auto-context injection."""
    project_dir = sys.argv[1] if len(sys.argv) > 1 else None
    
    injector = AutoContextInjector(project_dir)
    injector.run_auto_injection()

if __name__ == "__main__":
    main()