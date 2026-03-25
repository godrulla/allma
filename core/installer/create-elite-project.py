#!/usr/bin/env python3
"""
Complete Elite Project Creator
Creates a fully initialized project with all elite agents and files in one command.
"""

import os
import shutil
from pathlib import Path
from datetime import datetime

def create_elite_project(project_path: str):
    """Create a complete elite project with all files and agents."""
    
    project_dir = Path(project_path)
    agents_source = Path.home() / "Desktop" / "agents"
    
    # Create project directory
    project_dir.mkdir(parents=True, exist_ok=True)
    os.chdir(project_dir)
    
    print(f"🌟 Creating Elite Project: {project_dir.name}")
    print("   Complete setup with all files and agents...")
    
    # Initialize git
    if not (project_dir / ".git").exists():
        os.system("git init")
        print("✅ Initialized git repository")
    
    # Create project structure
    (project_dir / "docs").mkdir(exist_ok=True)
    (project_dir / ".agents").mkdir(exist_ok=True)
    (project_dir / "src").mkdir(exist_ok=True)
    
    # Copy all available elite agents
    elite_agents = ["ARQ.md", "ORC.md", "ZEN.md", "VEX.md", "SAGE.md", "NOVA.md", "ECHO.md"]
    installed_agents = []
    
    for agent_file in elite_agents:
        source_file = agents_source / agent_file
        dest_file = project_dir / ".agents" / agent_file
        
        if source_file.exists():
            shutil.copy2(source_file, dest_file)
            agent_name = agent_file.replace('.md', '')
            installed_agents.append(agent_name)
            print(f"📋 Installed {agent_name} agent")
    
    # Create comprehensive CLAUDE.md
    create_claude_md(project_dir, installed_agents)
    
    # Create project configuration
    create_project_config(project_dir, installed_agents)
    
    # Create README.md
    create_readme(project_dir)
    
    # Create .gitignore
    create_gitignore(project_dir)
    
    # Create package.json for Node.js projects
    create_package_json(project_dir)
    
    print(f"🎉 Elite project created successfully!")
    print(f"📁 Location: {project_dir}")
    print(f"🤖 Installed {len(installed_agents)} elite agents")
    print(f"📋 Files created: CLAUDE.md, README.md, package.json, .gitignore")
    print()
    print("🚀 Your elite agents are ready:")
    for agent in installed_agents:
        agent_info = get_agent_info(agent)
        print(f"   {agent_info['nickname']} - {agent_info['full_name']}")
    print()
    print("💡 Next steps:")
    print("   1. cd into your project directory")
    print("   2. Start using agents by referencing .agents/*.md files")
    print("   3. Customize CLAUDE.md with your specific project context")

def get_agent_info(agent_code):
    """Get agent information by code."""
    agents = {
        "ARQ": {"nickname": "*arq", "full_name": "The Visionary Architect"},
        "ORC": {"nickname": "*orc", "full_name": "The Master Orchestrator"}, 
        "ZEN": {"nickname": "*zen", "full_name": "The Code Zen Master"},
        "VEX": {"nickname": "*vex", "full_name": "The Creative Visionary"},
        "SAGE": {"nickname": "*sage", "full_name": "The Strategic Oracle"},
        "NOVA": {"nickname": "*nova", "full_name": "The Innovation Catalyst"},
        "ECHO": {"nickname": "*echo", "full_name": "The Voice of the People"}
    }
    return agents.get(agent_code, {"nickname": f"*{agent_code.lower()}", "full_name": f"The {agent_code} Agent"})

def create_claude_md(project_dir, installed_agents):
    """Create comprehensive CLAUDE.md file."""
    
    content = f"""# {project_dir.name}

This project uses the **Elite Global Agent System** - world-class AI agents with cutting-edge expertise and memorable personalities.

## 🌟 Your Elite AI Team

Each agent combines cutting-edge expertise with memorable personality and deeper purpose beyond task completion.

### Installed Elite Agents

"""
    
    for agent in installed_agents:
        agent_info = get_agent_info(agent)
        content += f"#### {agent} {agent_info['nickname']} - {agent_info['full_name']}\n"
        content += f"**File**: `.agents/{agent}.md`\n"
        
        # Add purpose and expertise
        purposes = {
            "ARQ": "Building tomorrow's systems with today's vision",
            "ORC": "Conducting symphonies of complex workflows", 
            "ZEN": "Writing code that transcends mere functionality",
            "VEX": "Designing experiences that move souls",
            "SAGE": "Seeing patterns others miss, predicting what others can't",
            "NOVA": "Turning impossible ideas into inevitable realities",
            "ECHO": "Amplifying authentic human connections through technology"
        }
        
        if agent in purposes:
            content += f"**Purpose**: {purposes[agent]}\n"
        
        content += "\n"
    
    content += f"""## 🎯 Quick Usage

### Method 1: Copy Agent to Project Root
```bash
cp .agents/ARQ.md ./          # For immediate use with Claude Code
cp .agents/ZEN.md ./          # For clean code guidance
```

### Method 2: Reference in Conversations
```
I need help with system architecture. Please use the ARQ agent from .agents/ARQ.md to help me design a scalable microservices platform.
```

### Method 3: Agent Combination
```
Use both ARQ (.agents/ARQ.md) for architecture and ZEN (.agents/ZEN.md) for clean code implementation of my fintech API.
```

## 🔧 Project Context

**Created**: {datetime.now().strftime('%Y-%m-%d')}  
**Elite Agents**: {len(installed_agents)} world-class specialists installed  
**Purpose**: Each agent brings cutting-edge expertise with memorable personality  

## 🚀 What Makes These Agents Elite

- **World-Class Expertise**: Compete with top consulting firms and agencies
- **Memorable Personalities**: Distinct communication styles and approaches  
- **Purpose-Driven**: Deeper "why" beyond task completion
- **Cultural Intelligence**: Global awareness with local relevance
- **Cutting-Edge Knowledge**: Latest 2025 technologies and methodologies

## 🎪 Agent Specializations

- **ARQ**: Enterprise architecture, cloud-native systems, scalability planning
- **ORC**: Complex project coordination, workflow optimization, team orchestration
- **ZEN**: Clean code mastery, elegant algorithms, refactoring excellence
- **VEX**: UI/UX design, design systems, user psychology, creative innovation
- **SAGE**: Strategic planning, market intelligence, competitive analysis, forecasting
- **NOVA**: Breakthrough innovation, emerging technologies, R&D strategy
- **ECHO**: Community building, content strategy, brand voice, cultural intelligence

---

*Your elite AI team is ready to tackle any challenge with world-class expertise and memorable personalities! 🌟*
"""
    
    with open(project_dir / "CLAUDE.md", 'w') as f:
        f.write(content)
    
    print("✅ Created comprehensive CLAUDE.md")

def create_project_config(project_dir, installed_agents):
    """Create elite project configuration."""
    
    config_content = f"""# Elite Project Configuration
project:
  name: {project_dir.name}
  created: {datetime.now().isoformat()}
  type: elite_global_agents
  version: "2.0"

agents:
  installed: {len(installed_agents)}
  available:"""
    
    for agent in installed_agents:
        agent_info = get_agent_info(agent)
        config_content += f"""
    {agent}:
      nickname: {agent_info['nickname']}
      full_name: {agent_info['full_name']}
      file: .agents/{agent}.md"""
    
    config_content += f"""

usage:
  method_1: "Copy agent files to project root for immediate use"
  method_2: "Reference .agents/*.md files in Claude conversations" 
  method_3: "Combine multiple agents for complex challenges"

philosophy: "World-class expertise with memorable personalities and deeper purpose"
"""
    
    with open(project_dir / ".elite-project.yaml", 'w') as f:
        f.write(config_content)
    
    print("✅ Created .elite-project.yaml configuration")

def create_readme(project_dir):
    """Create comprehensive README.md."""
    
    content = f"""# {project_dir.name}

A project powered by the **Elite Global Agent System** - world-class AI agents with cutting-edge expertise.

## 🚀 Quick Start

This project includes elite AI agents in the `.agents/` directory. Each agent brings world-class expertise with memorable personality.

### Using Your Elite Agents

1. **Copy agents to project root**:
   ```bash
   cp .agents/ARQ.md ./    # For system architecture
   cp .agents/ZEN.md ./    # For clean code
   ```

2. **Reference in Claude Code**: See `CLAUDE.md` for agent details

3. **Combine agents** for complex challenges

## 🌟 Available Agents

- **ARQ** - Visionary system architect
- **ZEN** - Code zen master  
- **VEX** - Creative design visionary
- **SAGE** - Strategic oracle
- **NOVA** - Innovation catalyst
- **ORC** - Master orchestrator
- **ECHO** - Voice of the people

## 🔧 Development

```bash
# Install dependencies (if applicable)
npm install

# Start development
npm run dev
```

## 📚 Documentation

- **CLAUDE.md** - Complete agent documentation and usage guide
- **.agents/** - Individual agent files with cutting-edge expertise

---

*Built with elite AI agents for world-class results! 🌟*
"""
    
    with open(project_dir / "README.md", 'w') as f:
        f.write(content)
    
    print("✅ Created README.md")

def create_gitignore(project_dir):
    """Create comprehensive .gitignore."""
    
    content = """# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Production builds
dist/
build/
.next/
out/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE and editor files
.vscode/
.idea/
*.swp
*.swo
*~

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
logs/
*.log

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# Dependency directories
jspm_packages/

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Temporary folders
tmp/
temp/

# Elite agent backups (keep originals in .agents/)
*-backup.md
"""
    
    with open(project_dir / ".gitignore", 'w') as f:
        f.write(content)
    
    print("✅ Created .gitignore")

def create_package_json(project_dir):
    """Create basic package.json for Node.js projects."""
    
    content = f'''{{
  "name": "{project_dir.name}",
  "version": "1.0.0",
  "description": "A project powered by Elite Global Agent System",
  "main": "index.js",
  "scripts": {{
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "echo \\"Error: no test specified\\" && exit 1"
  }},
  "keywords": [
    "elite-agents",
    "ai-assisted-development",
    "world-class-expertise"
  ],
  "author": "Created with Elite Global Agent System",
  "license": "MIT",
  "devDependencies": {{
    "nodemon": "^3.0.1"
  }},
  "elite_agents": {{
    "system": "Global Elite Agents v2.0",
    "created": "{datetime.now().isoformat()}",
    "agents_directory": ".agents/",
    "documentation": "CLAUDE.md"
  }}
}}'''
    
    with open(project_dir / "package.json", 'w') as f:
        f.write(content)
    
    print("✅ Created package.json")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 2:
        print("Usage: python3 create-elite-project.py <project-path>")
        print("Example: python3 create-elite-project.py ~/Desktop/my-elite-project")
        sys.exit(1)
    
    project_path = sys.argv[1]
    create_elite_project(project_path)