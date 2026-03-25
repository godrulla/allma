# Exxede Agent Installation System
**Intelligent Agent Management with Enhanced Training**

## 🚀 Quick Start

### One-Time Installation
```bash
cd ~/Desktop/agents
./install.sh
# Restart your terminal or source your shell config
```

### Initialize a New Project
```bash
cd my-project
init-exxede-project
```

### Manual Agent Management
```bash
# List available agents
agents --list

# Auto-detect and install recommended agents
agents --init

# Install specific agents
agents --agents strategic-business-analyst fullstack-dev-agent

# Update installed agents with latest enhancements
agents --update
```

## 🧠 Enhanced Agent Training System

### What Makes This Special

1. **Project Context Awareness**: Agents automatically adapt to your project type
2. **Enhanced Training Data**: Each agent has specialized knowledge for Caribbean/DR markets
3. **Cultural Intelligence**: Built-in understanding of Dominican business practices
4. **Technical Optimization**: Agents understand Caribbean infrastructure limitations

### Training Data Examples

Each agent receives specialized training like:

**Strategic Business Analyst**:
- Dominican Republic Free Trade Zone regulations
- Hurricane season business continuity planning
- Caribbean tourism industry seasonal analysis
- CAFTA-DR trade agreement implications

**Full-Stack Developer**:
- Caribbean-optimized web performance
- Spanish/English multi-language architecture
- Dominican payment gateway integrations
- Hurricane-resistant infrastructure design

**Digital Marketing Specialist**:
- Caribbean social media trends and platforms
- Dominican influencer landscape
- Bilingual SEO optimization strategies
- Cultural calendar integration for campaigns

## 🔧 System Architecture

### Directory Structure
```
~/Desktop/agents/
├── README.md                    # Main documentation
├── USAGE-GUIDE.md              # Quick reference
├── SYSTEM-GUIDE.md             # This file
├── agent-installer.py          # Core installation system
├── install.sh                  # Global system installer
├── training/                   # Agent training data
│   ├── strategic-business-analyst.yaml
│   ├── fullstack-dev-agent.yaml
│   ├── digital-marketing-agent.yaml
│   └── dominican-market-specialist.yaml
├── enhancements/               # Context enhancements
└── [agent-files].md           # Individual agent templates
```

### Project Structure (After Installation)
```
your-project/
├── .agents/                    # Installed and enhanced agents
│   ├── strategic-business-analyst.md
│   ├── fullstack-dev-agent.md
│   └── [other-agents].md
├── .exxede-agents.yaml        # Project configuration
└── CLAUDE.md                  # Updated with agent references
```

## 🎯 Project Type Detection

The system automatically detects project types and recommends agents:

### Web Applications
- **Next.js Projects**: Detects `next.config.js`, recommends fullstack-dev, devops, qa-testing
- **React Projects**: Detects React patterns, recommends frontend-focused agents
- **API Projects**: Detects API patterns, recommends backend and devops agents

### Business Types
- **E-commerce**: Detects product/cart patterns, adds marketing and market-specialist agents
- **Fintech**: Detects payment patterns, adds investment-research and compliance agents
- **Tourism**: Detects booking patterns, adds tourism-focused marketing agents

### Always Included
- **Strategic Business Analyst**: For all Exxede projects
- **Dominican Market Specialist**: For market intelligence and cultural guidance

## 🎨 Agent Enhancement Process

### 1. Context Injection
Each agent receives project-specific context:
```yaml
project_context:
  project_name: "my-fintech-app"
  detected_types: ["fintech", "nextjs"]
  frameworks: ["Next.js", "React", "Tailwind CSS"]
  databases: ["PostgreSQL", "Redis"]
  deployment: ["Vercel", "GitHub Actions"]
```

### 2. Training Data Application
Agents get enhanced with specialized knowledge:
- Market-specific insights
- Technical optimizations
- Cultural considerations
- Best practices

### 3. Example Generation
Project-specific usage examples:
- Framework-specific code patterns
- Market-specific strategies
- Cultural adaptation guidelines

## 🛠️ Commands Reference

### Global Commands (Available Anywhere)
```bash
# Agent management
agents --list                   # List available agents
agents --init                   # Auto-install for current project
agents --update                 # Update installed agents
agents --installed             # Show installed agents

# Project initialization
init-exxede-project [name]     # Complete project setup
```

### Direct Python Script
```bash
# Advanced usage with Python script
python3 ~/Desktop/agents/agent-installer.py --init
python3 ~/Desktop/agents/agent-installer.py --agents strategic-business-analyst
python3 ~/Desktop/agents/agent-installer.py --no-enhance --agents fullstack-dev-agent
```

## 📋 Configuration Files

### Global Configuration (`~/.exxede-agent-config.yaml`)
```yaml
version: "1.0"
default_agents:
  - strategic-business-analyst
  - dominican-market-specialist

enhancements:
  enabled: true
  include_project_context: true
  include_training_data: true

business_context:
  companies:
    - name: "Exxede Investments"
      focus: "Investment and business development"
  markets:
    primary: "Dominican Republic"
    secondary: ["Caribbean", "Latin America"]
```

### Project Configuration (`.exxede-agents.yaml`)
```yaml
exxede_agents:
  version: "1.0"
  installed_agents:
    - strategic-business-analyst
    - fullstack-dev-agent
  project_context:
    project_name: "my-app"
    detected_types: ["nextjs"]
    frameworks: ["Next.js", "React"]
  installation_date: "2025-01-07T..."
  auto_update: true
  enhanced: true
```

## 🔍 Troubleshooting

### Common Issues

**Python dependencies missing**:
```bash
pip3 install --user pyyaml
```

**Agents not found after installation**:
```bash
# Check if agents directory exists
ls ~/Desktop/agents/

# Verify installation
which exxede-agents
```

**Commands not available after installation**:
```bash
# Restart terminal or source config
source ~/.zshrc  # or ~/.bashrc
```

### Reset Installation
```bash
# Remove global config
rm ~/.exxede-agent-config.yaml

# Remove from PATH (edit manually)
nano ~/.zshrc  # Remove Exxede Agent System lines

# Reinstall
cd ~/Desktop/agents
./install.sh
```

## 🎯 Best Practices

### Project Setup Workflow
1. Create new project directory
2. Run `init-exxede-project`
3. Review installed agents in `.agents/` directory
4. Customize `CLAUDE.md` with project-specific context
5. Start using agents by copying or referencing them

### Agent Usage Patterns
1. **Single Agent**: Copy specific agent to project root for focused assistance
2. **Multi-Agent**: Reference multiple agents from `.agents/` directory
3. **Enhanced Context**: Use the enhanced versions for better project integration

### Maintenance
- Run `agents --update` monthly to get latest enhancements
- Review training data in `~/Desktop/agents/training/` for insights
- Update project context when major changes occur

## 🌟 Advanced Features

### Custom Training Data
Create custom training files in `~/Desktop/agents/training/` for specialized agents.

### Context Enhancement
The system automatically enhances agents with:
- Project technology stack awareness
- Dominican Republic market focus
- Exxede Group business context
- Cultural adaptation guidelines

### Integration with Claude Code
Agents integrate seamlessly with Claude Code through `CLAUDE.md` references and context injection.

---
*Built to help Armando and the Exxede Group achieve world-class AI assistance with deep Caribbean market intelligence*