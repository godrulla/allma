# AI Agents Directory
**Created for Armando Diaz Silverio - Exxede Group**

This directory contains personalized AI agent templates designed for your portfolio of companies: Exxede Investments, ReppingDR, Prolici, and Exxede.dev, with a focus on the Dominican Republic market.

## Quick Start
1. Choose an agent from the list below
2. Copy the agent's `.md` file to your project
3. Follow the invocation instructions
4. Customize for your specific use case

## Available Agents

### 🚀 Core Business Agents
- **[Strategic Business Analyst](./strategic-business-analyst.md)** - Market analysis and business intelligence for Dominican Republic ventures
- **[Investment Research Agent](./investment-research-agent.md)** - Due diligence and investment opportunity analysis
- **[Dominican Market Specialist](./dominican-market-specialist.md)** - Local market insights and cultural adaptation

### 💻 Development & Technical Agents
- **[Full-Stack Development Agent](./fullstack-dev-agent.md)** - End-to-end web application development
- **[DevOps Automation Agent](./devops-automation-agent.md)** - Infrastructure management and deployment
- **[Code Review & Quality Agent](./code-review-agent.md)** - Code analysis and improvement recommendations
- **[API Integration Specialist](./api-integration-agent.md)** - Third-party service integration and API development

### 📊 Product & Project Management
- **[Product Strategy Agent](./product-strategy-agent.md)** - Feature planning and roadmap development
- **[Agile Project Manager](./agile-project-manager.md)** - Sprint planning and team coordination
- **[QA Testing Orchestrator](./qa-testing-agent.md)** - Comprehensive testing strategy and execution

### 🎯 Marketing & Growth
- **[Digital Marketing Strategist](./digital-marketing-agent.md)** - Campaign planning and execution
- **[Content Creation Agent](./content-creation-agent.md)** - Bilingual content for English/Spanish markets
- **[SEO & Analytics Agent](./seo-analytics-agent.md)** - Search optimization and performance tracking

### 🔍 Research & Analysis
- **[Market Research Agent](./market-research-agent.md)** - Competitive analysis and opportunity identification
- **[Data Analysis Agent](./data-analysis-agent.md)** - Business intelligence and reporting
- **[Trend Analysis Agent](./trend-analysis-agent.md)** - Industry trends and future predictions

## Integration Methods

### Method 1: Project-Level Integration
```bash
cp ~/Desktop/agents/[agent-name].md ./project-agents/
```

### Method 2: Global Access
Add to your shell profile:
```bash
export AGENTS_DIR="$HOME/Desktop/agents"
alias load-agent='cp $AGENTS_DIR/$1.md ./'
```

### Method 3: Claude Code Integration
Reference agents in your project's CLAUDE.md:
```markdown
# Available Agents
- Strategic Business Analyst: ~/Desktop/agents/strategic-business-analyst.md
- Full-Stack Developer: ~/Desktop/agents/fullstack-dev-agent.md
```

## Customization Guidelines

Each agent template includes:
- **Role Definition**: Clear responsibilities and expertise areas
- **Context Settings**: Dominican Republic market focus
- **Communication Style**: Professional yet approachable
- **Output Formats**: Structured deliverables
- **Integration Instructions**: How to invoke and use

## Best Practices

1. **Start Specific**: Choose the most specialized agent for your task
2. **Combine Agents**: Use multiple agents for complex projects
3. **Customize Context**: Add your specific business context
4. **Iterate**: Refine agent instructions based on results
5. **Document**: Keep notes on what works best for each use case

---
*Built with ❤️ for conquering the universe together*