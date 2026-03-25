#!/usr/bin/env python3
"""
Nickname Agent Activator
Direct agent invocation through nickname patterns (*arq, *zen, etc.)
"""

import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple

class NicknameAgentActivator:
    def __init__(self, project_dir: str = None):
        self.project_dir = Path(project_dir or os.getcwd())
        self.agents_dir = self.project_dir / ".agents"
        
        # Agent nickname mapping
        self.agent_nicknames = {
            "*arq": "ARQ",
            "*zen": "ZEN", 
            "*vex": "VEX",
            "*sage": "SAGE",
            "*nova": "NOVA",
            "*echo": "ECHO",
            "*orc": "ORC"
        }
        
        # Model complexity mapping for cost optimization
        self.complexity_models = {
            "simple": "claude-3-haiku",
            "moderate": "claude-3.5-sonnet", 
            "complex": "claude-3-opus"
        }
    
    def detect_nickname_invocation(self, text: str) -> Optional[Tuple[str, str]]:
        """Detect nickname pattern at start of text and extract agent + remaining message."""
        text = text.strip()
        
        # Check if text starts with nickname pattern
        for nickname, agent_id in self.agent_nicknames.items():
            if text.lower().startswith(nickname.lower()):
                # Extract the remaining message after nickname
                remaining_text = text[len(nickname):].strip()
                return agent_id, remaining_text
        
        return None
    
    def load_agent_context(self, agent_id: str) -> Optional[Dict[str, Any]]:
        """Load full agent context from .agents/ file."""
        agent_file = self.agents_dir / f"{agent_id}.md"
        
        if not agent_file.exists():
            return None
        
        try:
            with open(agent_file, 'r') as f:
                content = f.read()
            
            # Parse agent metadata from the file
            agent_data = self.parse_agent_file(content, agent_id)
            agent_data["full_content"] = content
            
            return agent_data
            
        except Exception as e:
            print(f"Error loading agent {agent_id}: {e}", file=sys.stderr)
            return None
    
    def parse_agent_file(self, content: str, agent_id: str) -> Dict[str, Any]:
        """Parse agent file to extract key information."""
        lines = content.split('\n')
        
        # Extract title and subtitle
        title_match = re.search(r'^# (.+?)(?:\n|$)', content, re.MULTILINE)
        subtitle_match = re.search(r'\*\*(.+?)\*\*', content)
        philosophy_match = re.search(r'\*"(.+?)"\*', content)
        
        # Extract expertise sections
        expertise_sections = re.findall(r'### (.+?)\n(.*?)(?=\n###|\n##|\Z)', content, re.DOTALL)
        
        # Get nickname from mapping
        nickname = None
        for nick, aid in self.agent_nicknames.items():
            if aid == agent_id:
                nickname = nick
                break
        
        return {
            "agent_id": agent_id,
            "nickname": nickname,
            "title": title_match.group(1) if title_match else f"{agent_id} Agent",
            "subtitle": subtitle_match.group(1) if subtitle_match else "Elite AI Specialist",
            "philosophy": philosophy_match.group(1) if philosophy_match else "Excellence through expertise",
            "expertise_sections": expertise_sections,
            "loaded_at": datetime.now().isoformat()
        }
    
    def determine_task_complexity(self, task_text: str) -> str:
        """Analyze task complexity for model selection."""
        # Simple heuristics for complexity detection
        complex_indicators = [
            "architecture", "design", "strategy", "system", "scalability",
            "distributed", "microservices", "enterprise", "complex", "advanced"
        ]
        
        moderate_indicators = [
            "implement", "develop", "build", "create", "optimize",
            "refactor", "integrate", "api", "database", "algorithm"
        ]
        
        task_lower = task_text.lower()
        
        # Check for complex indicators
        if any(indicator in task_lower for indicator in complex_indicators):
            return "complex"
        
        # Check for moderate indicators  
        if any(indicator in task_lower for indicator in moderate_indicators):
            return "moderate"
        
        # Default to simple
        return "simple"
    
    def create_activation_context(self, agent_id: str, task_text: str, agent_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create activation context with agent persona and task assignment."""
        complexity = self.determine_task_complexity(task_text)
        model = self.complexity_models[complexity]
        
        # Estimate costs (rough estimates per 1K tokens)
        model_costs = {
            "claude-3-haiku": {"input": 0.0008, "output": 0.004},
            "claude-3.5-sonnet": {"input": 0.003, "output": 0.015}, 
            "claude-3-opus": {"input": 0.015, "output": 0.075}
        }
        
        # Estimate token usage based on complexity
        token_estimates = {
            "simple": {"input": 300, "output": 500},
            "moderate": {"input": 600, "output": 1000},
            "complex": {"input": 1200, "output": 2000}
        }
        
        tokens = token_estimates[complexity]
        cost_info = model_costs[model]
        estimated_cost = (tokens["input"] * cost_info["input"] / 1000) + (tokens["output"] * cost_info["output"] / 1000)
        
        return {
            "activation_id": f"{agent_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "agent": agent_data,
            "task": {
                "original_text": task_text,
                "complexity": complexity,
                "estimated_tokens": tokens
            },
            "model_selection": {
                "model": model,
                "reasoning": f"Selected {model} for {complexity} task complexity",
                "estimated_cost": estimated_cost
            },
            "activation_context": self.generate_activation_prompt(agent_data, task_text),
            "activated_at": datetime.now().isoformat()
        }
    
    def generate_activation_prompt(self, agent_data: Dict[str, Any], task_text: str) -> str:
        """Generate the activation prompt that embeds agent context."""
        agent_id = agent_data["agent_id"]
        nickname = agent_data["nickname"]
        title = agent_data["title"]
        philosophy = agent_data["philosophy"]
        
        prompt = f"""🤖 **AGENT ACTIVATED: {agent_id}** {nickname}

**{title}**
*{philosophy}*

**ROLE**: You are now operating as {agent_id}, embodying their complete expertise, personality, and approach. 

**TASK**: {task_text}

**AGENT CONTEXT**: 
{agent_data['full_content'][:2000]}...

**INSTRUCTIONS**:
1. Respond as {agent_id} with their unique personality and communication style
2. Apply their specialized expertise to the task
3. Use their signature output formats when applicable  
4. Maintain their philosophical approach and standards of excellence
5. Reference their specific methodologies and frameworks

**MODEL**: Using {agent_data.get('model_selection', {}).get('model', 'claude-3.5-sonnet')} for optimal cost/performance

---

{agent_id} is now fully activated and ready to assist! 🚀"""

        return prompt
    
    def activate_agent(self, text: str) -> Optional[Dict[str, Any]]:
        """Main activation function - detects nickname and activates agent."""
        detection_result = self.detect_nickname_invocation(text)
        
        if not detection_result:
            return None
        
        agent_id, task_text = detection_result
        
        # Load agent context
        agent_data = self.load_agent_context(agent_id)
        if not agent_data:
            return {
                "error": f"Agent {agent_id} not found in .agents/ directory",
                "available_agents": list(self.agent_nicknames.values())
            }
        
        # Create activation context
        activation_context = self.create_activation_context(agent_id, task_text, agent_data)
        
        # Save activation record
        self.save_activation_record(activation_context)
        
        return activation_context
    
    def save_activation_record(self, context: Dict[str, Any]) -> None:
        """Save activation record for session tracking."""
        activations_dir = self.project_dir / ".claude-context" / "activations"
        activations_dir.mkdir(parents=True, exist_ok=True)
        
        activation_file = activations_dir / f"{context['activation_id']}.json"
        
        try:
            with open(activation_file, 'w') as f:
                json.dump(context, f, indent=2)
        except Exception as e:
            print(f"Warning: Could not save activation record: {e}", file=sys.stderr)
    
    def get_available_agents(self) -> List[Dict[str, str]]:
        """Get list of available agents with nicknames."""
        available = []
        
        for nickname, agent_id in self.agent_nicknames.items():
            agent_file = self.agents_dir / f"{agent_id}.md"
            if agent_file.exists():
                agent_data = self.load_agent_context(agent_id)
                available.append({
                    "nickname": nickname,
                    "agent_id": agent_id,
                    "title": agent_data.get("title", agent_id) if agent_data else agent_id,
                    "available": True
                })
            else:
                available.append({
                    "nickname": nickname,
                    "agent_id": agent_id, 
                    "title": f"{agent_id} (Not Available)",
                    "available": False
                })
        
        return available
    
    def create_claude_md_enhancement(self) -> str:
        """Create enhanced CLAUDE.md content with activation instructions."""
        available_agents = self.get_available_agents()
        
        content = f"""
# 🤖 Direct Agent Activation System

## Nickname Invocation
Activate any elite agent directly by starting your message with their nickname:

### Available Agents
"""
        
        for agent in available_agents:
            status = "✅" if agent["available"] else "❌"
            content += f"- **{agent['nickname']}** - {agent['title']} {status}\n"
        
        content += f"""
### Usage Examples
```
*arq Design a scalable microservices architecture for 1M users
*zen Refactor this code to improve performance and readability  
*vex Create a user-friendly interface for this complex workflow
*sage Analyze the competitive landscape for our new product
*nova Research emerging AI technologies for our next innovation
*echo Develop a content strategy for our developer community
*orc Coordinate the deployment pipeline for our new service
```

### Automatic Features
- **Agent Context Loading**: Full agent expertise and personality activated
- **Cost Optimization**: Automatic model selection (Haiku/Sonnet/Opus) based on task complexity
- **Session Tracking**: Activation records saved in `.claude-context/activations/`
- **Multi-Agent Support**: Switch between agents within the same conversation

### How It Works
1. **Type nickname**: Start message with `*arq`, `*zen`, etc.
2. **Agent activates**: Full context loaded from `.agents/[AGENT].md`
3. **Optimal model selected**: Based on task complexity analysis
4. **Agent responds**: With their unique expertise and personality
5. **Session tracked**: For cost analysis and conversation continuity

---

**Ready to use!** Type any nickname at the start of your message to activate that agent's full expertise. 🚀
"""
        
        return content

def main():
    """CLI interface for testing nickname activation."""
    if len(sys.argv) < 2:
        print("Usage: python nickname-agent-activator.py 'your message here'")
        print("Example: python nickname-agent-activator.py '*arq Design a scalable API'")
        sys.exit(1)
    
    message = sys.argv[1]
    project_dir = sys.argv[2] if len(sys.argv) > 2 else None
    
    activator = NicknameAgentActivator(project_dir)
    
    # Test activation
    result = activator.activate_agent(message)
    
    if result:
        if "error" in result:
            print(f"❌ Error: {result['error']}", file=sys.stderr)
            print("Available agents:", ", ".join(result.get("available_agents", [])), file=sys.stderr)
        else:
            print(f"🤖 Agent Activated: {result['agent']['agent_id']}")
            print(f"📋 Task: {result['task']['original_text']}")
            print(f"🔧 Model: {result['model_selection']['model']} (${result['model_selection']['estimated_cost']:.4f})")
            print(f"⚡ Complexity: {result['task']['complexity']}")
            print("\n" + "="*60)
            print(result['activation_context'])
    else:
        print("No nickname detected. Available patterns:", list(activator.agent_nicknames.keys()))

if __name__ == "__main__":
    main()