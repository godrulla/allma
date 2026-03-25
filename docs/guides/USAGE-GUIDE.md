# Agent Usage Guide
**Quick Reference for Exxede Group AI Agents**

## Getting Started

### Method 1: Copy to Project (Recommended)
```bash
# Copy specific agent to your project
cp ~/Desktop/agents/strategic-business-analyst.md ./

# Or copy multiple agents
cp ~/Desktop/agents/{fullstack-dev-agent,qa-testing-agent,devops-automation-agent}.md ./
```

### Method 2: Shell Alias Setup
Add to your `.bashrc` or `.zshrc`:
```bash
export AGENTS_DIR="$HOME/Desktop/agents"
alias list-agents='ls $AGENTS_DIR/*.md | xargs basename -s .md'
alias load-agent='cp $AGENTS_DIR/$1.md ./'
alias show-agent='cat $AGENTS_DIR/$1.md | head -20'
```

### Method 3: Claude Code Integration
Add to your project's `CLAUDE.md`:
```markdown
# Available Agents
Use these agent templates for specialized assistance:

## Business & Strategy
- Strategic Business Analyst: ~/Desktop/agents/strategic-business-analyst.md
- Investment Research: ~/Desktop/agents/investment-research-agent.md
- Dominican Market Specialist: ~/Desktop/agents/dominican-market-specialist.md

## Development & Technical
- Full-Stack Developer: ~/Desktop/agents/fullstack-dev-agent.md
- DevOps Automation: ~/Desktop/agents/devops-automation-agent.md
- QA Testing: ~/Desktop/agents/qa-testing-agent.md

## Product & Marketing
- Product Strategy: ~/Desktop/agents/product-strategy-agent.md
- Digital Marketing: ~/Desktop/agents/digital-marketing-agent.md
- Content Creation: ~/Desktop/agents/content-creation-agent.md
```

## Quick Reference

### Business Intelligence & Strategy
| Agent | Use For | Key Output |
|-------|---------|------------|
| Strategic Business Analyst | Market analysis, competitive intelligence | Strategic analysis reports |
| Investment Research | Due diligence, ROI analysis | Investment memos, portfolio reviews |
| Dominican Market Specialist | Local market insights, cultural guidance | Market entry assessments |
| Market Research | Competitive analysis, customer insights | Market research reports |

### Development & Technical
| Agent | Use For | Key Output |
|-------|---------|------------|
| Full-Stack Developer | Web application development | Architecture plans, implementation |
| DevOps Automation | Infrastructure, CI/CD pipelines | Infrastructure setup guides |
| QA Testing | Quality assurance, test automation | Test plans, automation frameworks |
| Agile Project Manager | Sprint planning, team coordination | Sprint plans, status reports |

### Marketing & Growth
| Agent | Use For | Key Output |
|-------|---------|------------|
| Digital Marketing | Campaign strategy, social media | Marketing strategies, campaign briefs |
| Content Creation | Bilingual content, cultural adaptation | Content strategies, creative briefs |
| Product Strategy | Product roadmaps, feature prioritization | PRDs, product roadmaps |

## Invocation Examples

### Business Strategy Session
```
Load the Strategic Business Analyst and Dominican Market Specialist agents. 

I need to analyze the opportunity for expanding our vacation rental platform to Santiago and Puerto Plata. Consider:
- Market size and competition
- Cultural preferences and user behavior
- Regulatory requirements
- Partnership opportunities
- Go-to-market strategy

Provide comprehensive analysis with implementation roadmap.
```

### Development Project Kickoff
```
Load the Full-Stack Developer, DevOps Automation, and QA Testing agents.

We're building a fintech mobile app for Dominican micro-entrepreneurs. Requirements:
- React Native app with backend API
- Payment processing integration
- Multi-language support (Spanish/English)
- Cloud deployment with CI/CD
- Comprehensive testing strategy

Provide complete technical architecture and implementation plan.
```

### Marketing Campaign Launch
```
Load the Digital Marketing and Content Creation agents.

Launch marketing campaign for ReppingDR's new cultural merchandise line targeting:
- Dominican diaspora in US
- Caribbean pride and cultural identity
- Social media and influencer partnerships
- Bilingual content strategy
- Q4 holiday season timing

Develop complete campaign strategy with culturally resonant content.
```

## Agent Combination Strategies

### Complete Project Development
1. **Strategic Business Analyst** → Market validation
2. **Product Strategy** → Feature roadmap
3. **Full-Stack Developer** → Technical implementation
4. **QA Testing** → Quality assurance
5. **DevOps Automation** → Deployment
6. **Digital Marketing** → Launch strategy

### Market Entry Analysis
1. **Market Research** → Competitive landscape
2. **Dominican Market Specialist** → Cultural insights
3. **Strategic Business Analyst** → Strategic recommendations
4. **Investment Research** → Financial modeling

### Content Marketing Campaign
1. **Market Research** → Audience insights
2. **Content Creation** → Creative development
3. **Digital Marketing** → Distribution strategy
4. **Dominican Market Specialist** → Cultural validation

## Customization Tips

### Context Enhancement
Always provide specific context:
- Which Exxede company (Investments, ReppingDR, Prolici, Exxede.dev)
- Target market (DR, Caribbean, US Hispanic, broader LatAm)
- Timeline and budget constraints
- Existing assets and capabilities

### Cultural Adaptation
For Caribbean/Dominican market focus:
- Specify regional preferences (Punta Cana vs Santiago)
- Include cultural events and seasonality
- Consider infrastructure limitations
- Account for relationship-based business culture

### Integration with Existing Projects
- Reference existing technology stack
- Align with current business objectives
- Consider resource constraints
- Build on established partnerships

## Best Practices

### Agent Selection
- **Single Focus**: Use one specialized agent for specific tasks
- **Multi-Agent**: Combine complementary agents for complex projects
- **Sequential**: Use agents in logical sequence for workflow

### Communication Style
- **Be Specific**: Provide detailed context and requirements
- **Set Expectations**: Clear timelines and deliverable formats
- **Iterate**: Refine requirements based on initial recommendations

### Documentation
- Save agent outputs for future reference
- Build institutional knowledge base
- Share insights across team members
- Update agents based on learnings

## Troubleshooting

### Agent Not Responding as Expected
- Check if context is specific enough
- Verify agent specialization matches need
- Consider using different agent or combination
- Provide more detailed background information

### Output Format Issues
- Request specific format (report, checklist, roadmap)
- Specify length and detail level requirements
- Ask for section-by-section breakdown
- Request executive summary for complex outputs

### Cultural Context Missing
- Always specify target market explicitly
- Include Dominican Market Specialist for local insights
- Reference specific cultural considerations
- Validate recommendations with local knowledge

---
*Master these agents to unlock the full potential of AI-assisted business development for the Exxede Group*