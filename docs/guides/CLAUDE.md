See global instructions at `~/.claude/CLAUDE.md` for toolchain, memory system, and preferences.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the **Exxede Agent System** - a comprehensive collection of specialized AI agent templates designed for Armando Diaz Silverio and the Exxede Group companies (Exxede Investments, ReppingDR, Prolici, Exxede.dev) with deep focus on Dominican Republic and Caribbean markets.

## Core Architecture

### Agent System Structure
- **Agent Templates**: Individual `.md` files containing specialized AI assistant configurations
- **Installation System**: Python-based installer with intelligent project detection
- **Training Data**: YAML files with specialized knowledge for Caribbean/Dominican markets
- **Enhancement Engine**: Automatic project context injection and agent customization

### Key Components
- **`agent-installer.py`**: Core installation and management system (528 lines)
- **`install.sh`**: Global system setup with shell integration
- **`training/`**: Enhanced training data for market-specific knowledge
- **Individual Agent Files**: 20+ specialized agents for different business functions

## Common Development Commands

### Agent System Management
```bash
# Global installation (one-time setup)
./install.sh

# Project initialization
init-exxede-project [project-name]

# Agent management
agents --list                    # List available agents
agents --init                    # Auto-detect and install recommended agents  
agents --agents [agent-names]    # Install specific agents
agents --installed              # Show installed agents
agents --update                 # Update installed agents

# Direct Python usage
python3 agent-installer.py --init
python3 agent-installer.py --agents strategic-business-analyst fullstack-dev-agent
```

### Testing
```bash
# Test all agents and installation system
python3 test-all-agents.py
```

## Project Type Detection & Auto-Installation

The system automatically detects project types and recommends relevant agents:

### Supported Project Types
- **Next.js/React**: Fullstack dev, DevOps, QA testing
- **Fintech**: Investment research, compliance, QA testing
- **Tourism**: Marketing, Dominican market specialist, content creation
- **E-commerce**: Product strategy, marketing, market specialist
- **API Projects**: Backend development, DevOps, QA
- **Data Analysis**: Market research, strategic analysis

### Core Business Agents (Always Included)
- `strategic-business-analyst`: Market analysis and business intelligence
- `dominican-market-specialist`: Local market insights and cultural adaptation

## Agent Categories

### Business & Strategy
- `strategic-business-analyst.md`: Market analysis, competitive intelligence
- `investment-research-agent.md`: Due diligence, ROI analysis
- `dominican-market-specialist.md`: Local market expertise
- `market-research-agent.md`: Competitive analysis, customer insights

### Development & Technical  
- `fullstack-dev-agent.md`: End-to-end web application development
- `devops-automation-agent.md`: Infrastructure, CI/CD pipelines
- `qa-testing-agent.md`: Quality assurance, test automation
- `agile-project-manager.md`: Sprint planning, team coordination

### Marketing & Growth
- `digital-marketing-agent.md`: Campaign strategy, social media
- `content-creation-agent.md`: Bilingual content, cultural adaptation
- `product-strategy-agent.md`: Feature planning, roadmap development

## Enhanced Training System

Each agent receives specialized training data from `training/*.yaml` files:

### Training Data Includes
- **Caribbean Market Intelligence**: Tourism patterns, cultural preferences
- **Dominican Republic Business Context**: Regulations, payment systems, cultural practices
- **Technical Optimizations**: Caribbean infrastructure considerations, multi-language support
- **Cultural Intelligence**: Business relationship patterns, seasonal considerations

### Example Enhancement Process
1. **Project Detection**: Automatically identifies frameworks, databases, deployment targets
2. **Context Injection**: Adds project-specific technical stack information
3. **Training Application**: Applies specialized Caribbean/Dominican market knowledge
4. **Cultural Adaptation**: Includes local business practices and preferences

## Integration Methods

### Method 1: Project-Level Installation (Recommended)
```bash
cd your-project
init-exxede-project
# Creates .agents/ directory with enhanced agents
# Updates CLAUDE.md with agent references
```

### Method 2: Manual Agent Copy
```bash
cp ~/Desktop/agents/strategic-business-analyst.md ./
```

### Method 3: CLAUDE.md Reference
```markdown
## Available Agents
- Strategic Business Analyst: ~/Desktop/agents/strategic-business-analyst.md
- Full-Stack Developer: ~/Desktop/agents/fullstack-dev-agent.md
```

## Project Configuration

After installation, projects contain:
- **`.agents/`**: Enhanced agent templates with project context
- **`.exxede-agents.yaml`**: Project configuration and installed agent tracking
- **Updated `CLAUDE.md`**: References to installed agents

## Business Context Integration

All agents include enhanced context for:
- **Exxede Group Companies**: Investment focus, cultural merchandise, business services, technology development
- **Geographic Focus**: Punta Cana headquarters, Dominican Republic primary market, Caribbean secondary
- **Cultural Intelligence**: Relationship-based business culture, bilingual operations, seasonal patterns
- **Technical Considerations**: Hurricane-resistant infrastructure, Caribbean connectivity optimization

## Best Practices

### Agent Selection Strategy
- **Single Agent**: Copy specific agent for focused assistance
- **Multi-Agent**: Use multiple agents for complex projects  
- **Sequential Workflow**: Strategic → Product → Development → Marketing

### Context Enhancement
- Always specify target market (DR, Caribbean, US Hispanic)
- Include relevant Exxede company context
- Reference existing technology stack
- Consider cultural and infrastructure constraints

### Maintenance
- Run `agents --update` monthly for latest enhancements
- Review training data for market insights updates
- Update project context when major changes occur

## File Structure Post-Installation
```
project/
├── .agents/                    # Enhanced agent templates
│   ├── strategic-business-analyst.md
│   ├── fullstack-dev-agent.md
│   └── [other-agents].md
├── .exxede-agents.yaml        # Project configuration
└── CLAUDE.md                  # Updated with agent references
```

This system represents a sophisticated AI agent management platform designed specifically for Caribbean market business development with deep technical integration capabilities.