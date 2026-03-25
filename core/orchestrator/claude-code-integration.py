#!/usr/bin/env python3
"""
Complete Claude Code Integration System
Seamless elite agent integration with automatic context injection
"""

import json
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List

# Import nickname activator
sys.path.insert(0, str(Path(__file__).parent))
try:
    from nickname_agent_activator import NicknameAgentActivator
except ImportError:
    try:
        # Try with hyphen in filename
        import importlib.util
        spec = importlib.util.spec_from_file_location("nickname_agent_activator", Path(__file__).parent / "nickname-agent-activator.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        NicknameAgentActivator = module.NicknameAgentActivator
    except Exception:
        NicknameAgentActivator = None

class ClaudeCodeIntegration:
    def __init__(self, project_dir: str = None):
        self.project_dir = Path(project_dir or os.getcwd())
        self.agents_dir = self.project_dir / ".agents"
        self.context_dir = self.project_dir / ".claude-context"
        
        # Initialize nickname activator if available
        self.activator = NicknameAgentActivator(str(self.project_dir)) if NicknameAgentActivator else None
        
        # Elite agent information
        self.elite_agents = {
            "ARQ": {
                "full_name": "Visionary Architect",
                "nickname": "*arq",
                "purpose": "Building tomorrow's systems with today's vision",
                "expertise": ["system-architecture", "scalability", "cloud-native", "performance"],
                "icon": "🏗️",
                "optimal_for": ["architecture", "system design", "scalability", "infrastructure"]
            },
            "ZEN": {
                "full_name": "Code Zen Master", 
                "nickname": "*zen",
                "purpose": "Writing code that transcends mere functionality",
                "expertise": ["clean-code", "algorithms", "refactoring", "best-practices"],
                "icon": "🧘",
                "optimal_for": ["code quality", "refactoring", "algorithms", "programming"]
            },
            "VEX": {
                "full_name": "Creative Visionary",
                "nickname": "*vex", 
                "purpose": "Designing experiences that move souls",
                "expertise": ["ui-ux-design", "design-systems", "user-psychology", "creative-innovation"],
                "icon": "🎨",
                "optimal_for": ["design", "ui", "ux", "user experience", "interface"]
            },
            "SAGE": {
                "full_name": "Strategic Oracle",
                "nickname": "*sage",
                "purpose": "Seeing patterns others miss, predicting what others can't",
                "expertise": ["market-analysis", "strategic-planning", "competitive-intelligence", "forecasting"],
                "icon": "🔮",
                "optimal_for": ["strategy", "market analysis", "business", "competitive research"]
            },
            "NOVA": {
                "full_name": "Innovation Catalyst",
                "nickname": "*nova",
                "purpose": "Turning impossible ideas into inevitable realities",
                "expertise": ["breakthrough-innovation", "emerging-tech", "venture-development", "r-and-d"],
                "icon": "🚀", 
                "optimal_for": ["innovation", "research", "breakthrough thinking", "emerging tech"]
            },
            "ECHO": {
                "full_name": "Voice of the People",
                "nickname": "*echo",
                "purpose": "Amplifying authentic human connections through technology",
                "expertise": ["community-building", "content-strategy", "brand-voice", "cultural-intelligence"],
                "icon": "🎤",
                "optimal_for": ["content", "community", "marketing", "communication", "brand"]
            },
            "ORC": {
                "full_name": "Master Orchestrator",
                "nickname": "*orc",
                "purpose": "Conducting symphonies of complex workflows",
                "expertise": ["workflow-automation", "project-coordination", "resource-optimization"],
                "icon": "🎼",
                "optimal_for": ["project management", "workflow", "coordination", "orchestration"]
            }
        }
    
    def detect_available_agents(self) -> List[str]:
        """Detect which agents are available in the project."""
        available_agents = []
        
        if not self.agents_dir.exists():
            return available_agents
        
        for agent_file in self.agents_dir.glob("*.md"):
            agent_id = agent_file.stem
            if agent_id in self.elite_agents:
                available_agents.append(agent_id)
        
        return available_agents
    
    def analyze_project_context(self) -> Dict[str, Any]:
        """Analyze project to determine context and needs."""
        context = {
            "project_name": self.project_dir.name,
            "project_type": "general",
            "technologies": [],
            "complexity": "moderate",
            "focus_areas": []
        }
        
        # Analyze package.json for Node.js projects
        package_json = self.project_dir / "package.json"
        if package_json.exists():
            try:
                with open(package_json) as f:
                    data = json.load(f)
                    context["project_type"] = "nodejs"
                    
                    # Check dependencies for frameworks
                    deps = {**data.get("dependencies", {}), **data.get("devDependencies", {})}
                    
                    if "react" in deps or "next" in deps:
                        context["technologies"].append("React")
                        context["focus_areas"].extend(["frontend", "ui", "components"])
                    
                    if "express" in deps or "@nestjs/core" in deps:
                        context["technologies"].append("Backend API")
                        context["focus_areas"].extend(["backend", "api", "server"])
                        
                    if "typescript" in deps:
                        context["technologies"].append("TypeScript")
                        context["focus_areas"].append("type-safety")
                        
            except:
                pass
        
        # Check for Python projects
        python_files = list(self.project_dir.glob("*.py"))
        requirements_txt = self.project_dir / "requirements.txt"
        
        if python_files or requirements_txt.exists():
            context["project_type"] = "python"
            context["technologies"].append("Python")
            context["focus_areas"].extend(["backend", "scripting"])
        
        # Check for infrastructure files
        if (self.project_dir / "docker-compose.yml").exists():
            context["technologies"].append("Docker")
            context["focus_areas"].append("containerization")
            context["complexity"] = "advanced"
        
        if (self.project_dir / "terraform").exists():
            context["technologies"].append("Terraform")
            context["focus_areas"].append("infrastructure")
            context["complexity"] = "complex"
        
        # Determine focus areas based on project name and structure
        project_name_lower = context["project_name"].lower()
        
        if any(word in project_name_lower for word in ["chat", "message", "viber", "communication"]):
            context["focus_areas"].extend(["real-time", "messaging", "communication"])
        
        if any(word in project_name_lower for word in ["api", "backend", "service"]):
            context["focus_areas"].extend(["api", "backend", "scalability"])
            
        if any(word in project_name_lower for word in ["app", "ui", "frontend"]):
            context["focus_areas"].extend(["frontend", "ui", "user-experience"])
        
        return context
    
    def recommend_agents(self, context: Dict[str, Any], available_agents: List[str]) -> List[str]:
        """Recommend agents based on project context."""
        recommended = set()
        focus_areas = context.get("focus_areas", [])
        
        # Always include SAGE for strategic guidance
        if "SAGE" in available_agents:
            recommended.add("SAGE")
        
        # Recommend based on focus areas
        for focus in focus_areas:
            for agent_id, agent_info in self.elite_agents.items():
                if agent_id not in available_agents:
                    continue
                    
                optimal_areas = agent_info.get("optimal_for", [])
                if any(area in focus for area in optimal_areas):
                    recommended.add(agent_id)
        
        # Ensure we have core agents
        priority_agents = ["ARQ", "ZEN", "VEX", "SAGE"]
        for agent in priority_agents:
            if agent in available_agents and len(recommended) < 4:
                recommended.add(agent)
        
        return list(recommended)[:5]  # Limit to 5 agents
    
    def generate_activation_section(self, available_agents: List[str]) -> str:
        """Generate the nickname activation section for CLAUDE.md"""
        content = f"""## 🤖 **DIRECT AGENT ACTIVATION SYSTEM** 

**CRITICAL**: When the user starts a message with agent nicknames (`*arq`, `*zen`, `*vex`, `*sage`, `*nova`, `*echo`, `*orc`), immediately activate the corresponding agent by loading their complete context from the `.agents/` directory.

### Agent Activation Protocol
1. **Detect Pattern**: If user message starts with `*arq`, `*zen`, `*vex`, `*sage`, `*nova`, `*echo`, or `*orc`
2. **Load Agent Context**: Read the complete `.agents/[AGENT].md` file 
3. **Embody Agent**: Adopt their personality, expertise, communication style, and methods
4. **Apply Optimization**: Use appropriate Claude model (Haiku/Sonnet/Opus) based on task complexity
5. **Respond as Agent**: Provide response using their unique approach and signature formats

### Available Agent Nicknames
"""
        
        # Add available agents
        for agent_id in available_agents:
            if agent_id in self.elite_agents:
                agent_info = self.elite_agents[agent_id]
                content += f"- **`{agent_info['nickname']}`** → Load `.agents/{agent_id}.md` - {agent_info['full_name']} ({', '.join(agent_info['optimal_for'][:2])})\n"
        
        content += f"""
### Activation Examples
```
User: "*arq Design a scalable microservices architecture"
→ Load .agents/ARQ.md, embody ARQ persona, respond with architectural expertise

User: "*zen Refactor this React component for better performance" 
→ Load .agents/ZEN.md, embody ZEN persona, respond with clean code principles

User: "*vex Create an intuitive user interface for this dashboard"
→ Load .agents/VEX.md, embody VEX persona, respond with UX design expertise
```

### Model Selection Rules
- **Simple tasks** (basic questions, simple implementations) → claude-3-haiku  
- **Moderate tasks** (feature development, analysis) → claude-3.5-sonnet
- **Complex tasks** (architecture, strategy, innovation) → claude-3-opus

"""
        return content
    
    def create_enhanced_claude_md(self, available_agents: List[str], recommended_agents: List[str], context: Dict[str, Any]) -> str:
        """Create enhanced CLAUDE.md with automatic integration."""
        project_name = context["project_name"]
        
        # Generate nickname activation section
        activation_section = self.generate_activation_section(available_agents) if self.activator else ""
        
        content = f"""# {project_name} - Elite AI Integration Active
**Automatic Multi-Model Agent Orchestration**

{activation_section}

## 🤖 Intelligent Agent Integration

Claude Code now has **automatic access** to your elite AI agents! No manual setup required - agents activate based on your requests with intelligent cost optimization.

### 🎯 Project Intelligence
- **Project Type**: {context["project_type"].title()}
- **Technologies**: {", ".join(context["technologies"]) if context["technologies"] else "General development"}
- **Complexity**: {context["complexity"].title()}
- **Focus Areas**: {", ".join(context["focus_areas"]) if context["focus_areas"] else "General development"}

### 🌟 Available Elite Agents ({len(available_agents)})

"""
        
        # Show recommended agents first
        content += "#### 🎯 Recommended for This Project\n"
        for agent_id in recommended_agents:
            if agent_id in self.elite_agents:
                agent = self.elite_agents[agent_id]
                content += f"**{agent['icon']} {agent_id}** ({agent['nickname']}) - {agent['full_name']}\n"
                content += f"*{agent['purpose']}*\n\n"
        
        # Show other available agents
        other_agents = [a for a in available_agents if a not in recommended_agents]
        if other_agents:
            content += "#### 💡 Additional Specialists Available\n"
            for agent_id in other_agents:
                if agent_id in self.elite_agents:
                    agent = self.elite_agents[agent_id]
                    content += f"**{agent['icon']} {agent_id}** ({agent['nickname']}) - {agent['full_name']}\n"
                    content += f"*{agent['purpose']}*\n\n"
        
        content += f"""## ⚡ How It Works

### Automatic Intelligence
When you make any request, Claude Code automatically:
1. **Analyzes your request** to determine optimal agents and complexity
2. **Selects cost-effective models**:
   - 🏃‍♂️ **Haiku** ($0.80/$4 per MTok) for simple tasks
   - ⚖️ **Sonnet** ($3/$15 per MTok) for balanced work
   - 🧠 **Opus** ($15/$75 per MTok) for complex reasoning
3. **Coordinates multiple agents** for comprehensive responses
4. **Optimizes costs** automatically (typically 60-80% savings)

### Example Usage Patterns
"""

        # Generate examples based on available agents
        if "ARQ" in available_agents and "ZEN" in available_agents:
            content += """
```
You: "Help me design a scalable API architecture"
→ ARQ (Opus): Comprehensive architecture design
→ ZEN (Sonnet): Clean code implementation patterns  
→ Cost: ~$0.05, Quality: Enterprise-grade
```
"""
        
        if "VEX" in available_agents:
            content += """
```
You: "Improve the user experience of my login form"
→ VEX (Haiku): Quick UX improvements and suggestions
→ Cost: ~$0.01, Speed: <30 seconds
```
"""
        
        if "SAGE" in available_agents:
            content += """
```
You: "Analyze the competitive landscape for our product"
→ SAGE (Sonnet): Strategic analysis and market insights
→ Cost: ~$0.02, Depth: Professional consulting level
```
"""
        
        content += f"""

### Cost Optimization Examples
- **Simple request** (content, basic code): ~$0.01-0.02 (Haiku)
- **Moderate request** (feature design, refactoring): ~$0.02-0.05 (Sonnet)  
- **Complex request** (system architecture, strategy): ~$0.05-0.15 (Opus)
- **Multi-agent coordination**: Intelligent model mixing for optimal cost/quality

## 🔧 Agent Expertise Matrix

| Request Type | Primary Agent | Model | Typical Cost |
|--------------|---------------|-------|--------------|"""

        # Create expertise matrix
        expertise_examples = {
            "ARQ": ("System architecture design", "Opus", "$0.05-0.15"),
            "ZEN": ("Code refactoring & optimization", "Sonnet", "$0.02-0.05"),
            "VEX": ("UI/UX design & user flows", "Haiku", "$0.01-0.03"),
            "SAGE": ("Strategic & market analysis", "Sonnet", "$0.02-0.08"),
            "NOVA": ("Innovation & breakthrough ideas", "Opus", "$0.03-0.10"),
            "ECHO": ("Content & communication strategy", "Haiku", "$0.01-0.02"),
            "ORC": ("Project coordination & planning", "Sonnet", "$0.02-0.05")
        }
        
        for agent_id in available_agents:
            if agent_id in expertise_examples:
                example, model, cost = expertise_examples[agent_id]
                content += f"\n| {example} | {agent_id} | {model} | {cost} |"
        
        content += f"""

## 🚀 No Setup Required!

### ✅ Ready Now
- **Agent files**: Located in `.agents/` directory
- **Auto-detection**: Active based on your project type
- **Cost optimization**: Automatic model selection
- **Multi-agent coordination**: Seamless collaboration

### 🎯 Just Start Asking
Ask anything related to:
- **{context["project_name"]} development** and architecture
- **Code quality** and best practices  
- **User experience** and design
- **Strategic planning** and market analysis
- **Innovation opportunities** and emerging tech
- **Content creation** and communication

### 💡 Pro Tips
- **Be specific** about complexity for optimal model selection
- **Combine domains** (e.g., "design and implement...") for multi-agent responses
- **Ask follow-ups** - agents remember context across conversation
- **Request explanations** of agent reasoning and cost optimization

---

## 🌟 Your Elite AI Team is Standing By!

**No commands needed.** **No manual selection required.**  
Just ask your questions and watch world-class AI agents automatically coordinate to give you the best possible assistance with intelligent cost optimization! ✨

*Current session: Elite agents ready with automatic model optimization active.*
"""
        
        return content
    
    def should_integrate(self) -> bool:
        """Determine if integration should occur."""
        return (
            self.agents_dir.exists() and 
            len(self.detect_available_agents()) > 0
        )
    
    def integrate(self) -> bool:
        """Run complete Claude Code integration."""
        if not self.should_integrate():
            return False
        
        try:
            # Detect available agents
            available_agents = self.detect_available_agents()
            
            # Analyze project context
            context = self.analyze_project_context()
            
            # Recommend agents
            recommended_agents = self.recommend_agents(context, available_agents)
            
            # Create enhanced CLAUDE.md
            claude_md_content = self.create_enhanced_claude_md(available_agents, recommended_agents, context)
            claude_md_path = self.project_dir / "CLAUDE.md"
            
            with open(claude_md_path, 'w') as f:
                f.write(claude_md_content)
            
            # Create integration marker
            self.create_integration_marker(available_agents, recommended_agents, context)
            
            # Ensure context directory exists
            self.context_dir.mkdir(exist_ok=True)
            
            return True
            
        except Exception as e:
            print(f"Integration error: {e}", file=sys.stderr)
            return False
    
    def create_integration_marker(self, available_agents: List[str], recommended_agents: List[str], context: Dict[str, Any]) -> None:
        """Create integration marker file."""
        marker_data = {
            "integration_active": True,
            "available_agents": available_agents,
            "recommended_agents": recommended_agents,
            "project_context": context,
            "integrated_at": datetime.now().isoformat(),
            "version": "2.0"
        }
        
        marker_file = self.project_dir / ".claude-integration.json"
        with open(marker_file, 'w') as f:
            json.dump(marker_data, f, indent=2)
    
    def print_status(self, available_agents: List[str], recommended_agents: List[str]) -> None:
        """Print integration status."""
        print("🤖 Elite Agent Integration Active", file=sys.stderr)
        print(f"✅ {len(available_agents)} agents available | {len(recommended_agents)} recommended for this project", file=sys.stderr)
        print("💡 Claude Code now has automatic access to world-class AI expertise!", file=sys.stderr)

def main():
    """Main integration function."""
    project_dir = sys.argv[1] if len(sys.argv) > 1 else None
    
    integration = ClaudeCodeIntegration(project_dir)
    
    if integration.integrate():
        available_agents = integration.detect_available_agents()
        context = integration.analyze_project_context()
        recommended_agents = integration.recommend_agents(context, available_agents)
        
        integration.print_status(available_agents, recommended_agents)
    else:
        print("⚠️ No elite agents found - integration skipped", file=sys.stderr)

if __name__ == "__main__":
    main()