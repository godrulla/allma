#!/usr/bin/env python3
"""
Elite Global Agent System Installer
Intelligent installation system for world-class AI agents with cutting-edge expertise.
"""

import os
import json
import yaml
import shutil
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime

class EliteAgentInstaller:
    def __init__(self, agents_dir: str = None):
        self.agents_dir = Path(agents_dir or os.path.expanduser("~/Desktop/agents"))
        self.project_dir = Path.cwd()
        self.config_file = self.project_dir / ".elite-agents.yaml"
        
        # Elite agents with their nicknames and specializations
        self.elite_agents = {
            "ARQ": {
                "full_name": "Visionary Architect",
                "file": "ARQ.md",
                "nickname": "*arq",
                "purpose": "Building tomorrow's systems with today's vision",
                "expertise": ["system-architecture", "cloud-native", "scalability", "microservices"],
                "personality": "visionary, elegant, future-focused",
                "use_cases": ["complex system design", "technical architecture", "scalability planning"]
            },
            "APEX": {
                "full_name": "Mobile Web Virtuoso",
                "file": "APEX.md",
                "nickname": "*apex",
                "purpose": "Crafting experiences that feel native, perform lightning-fast, and delight users across every device",
                "expertise": ["pwa", "mobile-first", "touch-interactions", "performance", "react-native-web"],
                "personality": "device-obsessed, performance perfectionist, user-centric",
                "use_cases": ["mobile optimization", "PWA development", "touch interfaces", "mobile performance"]
            },
            "ORC": {
                "full_name": "Master Orchestrator", 
                "file": "ORC.md",
                "nickname": "*orc",
                "purpose": "Conducting symphonies of complex workflows",
                "expertise": ["workflow-automation", "project-coordination", "resource-optimization"],
                "personality": "conductor-like precision, loves harmony in chaos",
                "use_cases": ["complex project management", "workflow optimization", "team coordination"]
            },
            "ZEN": {
                "full_name": "Code Zen Master",
                "file": "ZEN.md", 
                "nickname": "*zen",
                "purpose": "Writing code that transcends mere functionality",
                "expertise": ["clean-code", "algorithms", "refactoring", "code-quality"],
                "personality": "perfectionist philosopher, minimalist, code poet",
                "use_cases": ["code quality", "refactoring", "elegant solutions", "technical mentorship"]
            },
            "VEX": {
                "full_name": "Creative Visionary",
                "file": "VEX.md",
                "nickname": "*vex", 
                "purpose": "Designing experiences that move souls",
                "expertise": ["ui-ux-design", "design-systems", "user-psychology", "creative-innovation"],
                "personality": "artistic empath, emotionally intelligent, trend-setting",
                "use_cases": ["interface design", "user experience", "creative direction", "design systems"]
            },
            "SAGE": {
                "full_name": "Strategic Oracle",
                "file": "SAGE.md",
                "nickname": "*sage",
                "purpose": "Seeing patterns others miss, predicting what others can't", 
                "expertise": ["market-analysis", "strategic-planning", "competitive-intelligence", "forecasting"],
                "personality": "wise oracle, pattern recognition master, analytical genius",
                "use_cases": ["strategic planning", "market analysis", "competitive research", "business intelligence"]
            },
            "NOVA": {
                "full_name": "Innovation Catalyst",
                "file": "NOVA.md",
                "nickname": "*nova",
                "purpose": "Turning impossible ideas into inevitable realities",
                "expertise": ["breakthrough-innovation", "emerging-tech", "venture-development", "r-and-d"],
                "personality": "energetic optimist, loves impossible challenges, embraces failure",
                "use_cases": ["innovation strategy", "breakthrough thinking", "technology scouting", "R&D planning"]
            },
            "ECHO": {
                "full_name": "Voice of the People", 
                "file": "ECHO.md",
                "nickname": "*echo",
                "purpose": "Amplifying authentic human connections through technology",
                "expertise": ["community-building", "content-strategy", "brand-voice", "cultural-intelligence"],
                "personality": "empathetic storyteller, culturally aware, authentic communicator",
                "use_cases": ["content strategy", "community building", "brand voice", "marketing campaigns"]
            },
            # Future agents (coming soon)
            "FLUX": {
                "full_name": "Transformation Expert",
                "file": "FLUX.md",
                "nickname": "*flux", 
                "purpose": "Shepherding organizations through digital evolution",
                "expertise": ["digital-transformation", "change-management", "process-optimization"],
                "personality": "adaptive, patient, inspiring, change-positive",
                "use_cases": ["digital transformation", "change management", "process optimization"],
                "coming_soon": True
            },
            "PEAK": {
                "full_name": "Performance Perfectionist",
                "file": "PEAK.md",
                "nickname": "*peak",
                "purpose": "Ensuring excellence in every detail", 
                "expertise": ["qa-automation", "performance-testing", "quality-systems"],
                "personality": "meticulous, thorough, detective-minded, quality obsessed",
                "use_cases": ["quality assurance", "testing strategies", "performance optimization"],
                "coming_soon": True
            },
            "PULSE": {
                "full_name": "Growth Hacker",
                "file": "PULSE.md", 
                "nickname": "*pulse",
                "purpose": "Finding the heartbeat of product-market fit",
                "expertise": ["growth-hacking", "product-analytics", "conversion-optimization"],
                "personality": "data-driven, experimental, results-focused, customer-obsessed", 
                "use_cases": ["growth strategies", "conversion optimization", "product analytics"],
                "coming_soon": True
            }
        }
        
        # Project type detection patterns (enhanced for elite agents)
        self.project_patterns = {
            "enterprise-architecture": ["microservices/", "services/", "docker-compose.yml", "kubernetes/", "terraform/"],
            "fintech": ["payments/", "transactions/", "wallet/", "banking/", "finance/"],
            "saas": ["dashboard/", "auth/", "billing/", "subscription/", "api/"],
            "e-commerce": ["products/", "cart/", "checkout/", "inventory/", "orders/"],
            "startup": ["mvp/", "prototype/", "seed/", "pitch/", "validation/"],
            "ai-ml": ["models/", "training/", "inference/", "ml-pipeline/", "data-science/"],
            "design-system": ["components/", "design-tokens/", "storybook/", "figma/"],
            "content-platform": ["cms/", "blog/", "content/", "editorial/", "publishing/"],
            "community-platform": ["social/", "community/", "forums/", "messaging/"],
            "innovation-lab": ["experiments/", "research/", "prototypes/", "innovation/"],
        }
        
        # Elite agent recommendations by project type
        self.elite_recommendations = {
            "enterprise-architecture": ["ARQ", "ORC", "ZEN", "PEAK"],
            "fintech": ["ARQ", "SAGE", "ZEN", "PEAK", "APEX"],
            "saas": ["ARQ", "VEX", "SAGE", "PULSE", "APEX"], 
            "e-commerce": ["VEX", "ECHO", "SAGE", "PULSE", "APEX"],
            "startup": ["SAGE", "NOVA", "VEX", "PULSE", "APEX"],
            "ai-ml": ["ARQ", "ZEN", "NOVA", "SAGE"],
            "design-system": ["VEX", "ZEN", "ORC", "APEX"],
            "content-platform": ["ECHO", "VEX", "ORC"],
            "community-platform": ["ECHO", "VEX", "SAGE", "APEX"],
            "innovation-lab": ["NOVA", "SAGE", "ARQ", "VEX"],
            "mobile-app": ["APEX", "VEX", "ZEN", "ORC"],
            "pwa": ["APEX", "VEX", "ZEN", "ARQ"],
        }
        
        # Core elite agents (always recommended)
        self.core_elite_agents = ["SAGE", "ARQ"]
    
    def detect_project_type(self) -> List[str]:
        """Detect project type(s) based on elite patterns."""
        detected_types = []
        
        for project_type, patterns in self.project_patterns.items():
            for pattern in patterns:
                if self._pattern_exists(pattern):
                    detected_types.append(project_type)
                    break
        
        return detected_types or ["general-development"]
    
    def _pattern_exists(self, pattern: str) -> bool:
        """Check if a pattern exists in the project directory."""
        if pattern.endswith('/'):
            return (self.project_dir / pattern.rstrip('/')).is_dir()
        else:
            return (self.project_dir / pattern).exists()
    
    def get_recommended_agents(self, project_types: List[str], include_core: bool = True) -> List[str]:
        """Get recommended elite agents based on project types."""
        recommended = set()
        
        if include_core:
            recommended.update(self.core_elite_agents)
        
        for project_type in project_types:
            if project_type in self.elite_recommendations:
                recommended.update(self.elite_recommendations[project_type])
        
        return list(recommended)
    
    def install_agents(self, agents: List[str], enhanced: bool = True) -> Dict[str, Any]:
        """Install elite agents with enhanced capabilities."""
        results = {
            "installed": [],
            "enhanced": [],
            "errors": [],
            "coming_soon": [],
            "config_created": False
        }
        
        project_agents_dir = self.project_dir / ".agents"
        project_agents_dir.mkdir(exist_ok=True)
        
        for agent in agents:
            try:
                if agent not in self.elite_agents:
                    results["errors"].append(f"Unknown elite agent: {agent}")
                    continue
                
                agent_info = self.elite_agents[agent]
                
                # Check if agent is coming soon
                if agent_info.get("coming_soon", False):
                    results["coming_soon"].append(f"{agent} ({agent_info['full_name']}) - Coming Soon")
                    continue
                
                source_file = self.agents_dir / agent_info["file"]
                dest_file = project_agents_dir / agent_info["file"]
                
                if source_file.exists():
                    shutil.copy2(source_file, dest_file)
                    results["installed"].append(agent)
                    
                    if enhanced:
                        enhanced_agent = self.enhance_elite_agent(agent, dest_file)
                        if enhanced_agent:
                            results["enhanced"].append(agent)
                else:
                    results["errors"].append(f"Elite agent {agent} file not found")
                    
            except Exception as e:
                results["errors"].append(f"Error installing {agent}: {str(e)}")
        
        if self.create_elite_config(agents):
            results["config_created"] = True
        
        return results
    
    def enhance_elite_agent(self, agent_name: str, agent_file: Path) -> bool:
        """Enhance elite agent with project-specific context."""
        try:
            with open(agent_file, 'r') as f:
                content = f.read()
            
            project_context = self.get_project_context()
            agent_info = self.elite_agents[agent_name]
            
            # Add elite enhancement section
            enhancement_section = self.generate_elite_enhancement(agent_info, project_context)
            enhanced_content = content + f"\n\n{enhancement_section}"
            
            with open(agent_file, 'w') as f:
                f.write(enhanced_content)
            
            return True
            
        except Exception as e:
            print(f"Error enhancing elite agent {agent_name}: {e}")
            return False
    
    def get_project_context(self) -> Dict[str, Any]:
        """Extract project context for elite agent enhancement."""
        context = {
            "project_name": self.project_dir.name,
            "project_path": str(self.project_dir),
            "detected_types": self.detect_project_type(),
            "has_git": (self.project_dir / ".git").exists(),
            "frameworks": self.detect_frameworks(),
            "complexity_level": self.assess_project_complexity(),
            "team_indicators": self.detect_team_structure(),
            "created_at": datetime.now().isoformat()
        }
        return context
    
    def detect_frameworks(self) -> List[str]:
        """Detect frameworks for elite agent customization."""
        frameworks = []
        
        # Check package.json
        package_json = self.project_dir / "package.json"
        if package_json.exists():
            try:
                with open(package_json) as f:
                    data = json.load(f)
                    deps = {**data.get("dependencies", {}), **data.get("devDependencies", {})}
                    
                    framework_mapping = {
                        "react": "React", "vue": "Vue.js", "angular": "@angular/core",
                        "next": "Next.js", "nuxt": "Nuxt.js", "svelte": "Svelte",
                        "express": "Express", "@nestjs/core": "NestJS",
                        "typescript": "TypeScript", "tailwindcss": "Tailwind CSS"
                    }
                    
                    for dep, name in framework_mapping.items():
                        if any(dep in d for d in deps.keys()):
                            frameworks.append(name)
                            
            except json.JSONDecodeError:
                pass
        
        return frameworks
    
    def assess_project_complexity(self) -> str:
        """Assess project complexity for elite agent customization."""
        complexity_indicators = 0
        
        # Check for enterprise patterns
        enterprise_patterns = [
            "microservices/", "kubernetes/", "terraform/", 
            "monitoring/", "observability/", "security/"
        ]
        
        for pattern in enterprise_patterns:
            if self._pattern_exists(pattern):
                complexity_indicators += 1
        
        # Check for multiple services
        if (self.project_dir / "services").is_dir():
            complexity_indicators += 2
            
        # Check for advanced configurations
        advanced_configs = [
            "docker-compose.yml", "Dockerfile", ".github/workflows",
            "terraform/", "ansible/", "helm/"
        ]
        
        for config in advanced_configs:
            if self._pattern_exists(config):
                complexity_indicators += 1
        
        if complexity_indicators >= 5:
            return "enterprise"
        elif complexity_indicators >= 3:
            return "advanced" 
        elif complexity_indicators >= 1:
            return "intermediate"
        else:
            return "startup"
    
    def detect_team_structure(self) -> Dict[str, Any]:
        """Detect team structure indicators."""
        team_info = {"size": "unknown", "roles": []}
        
        # Check for role-based directories
        role_directories = {
            "frontend/": "frontend-developer",
            "backend/": "backend-developer", 
            "design/": "designer",
            "docs/": "technical-writer",
            "tests/": "qa-engineer",
            "devops/": "devops-engineer"
        }
        
        for directory, role in role_directories.items():
            if self._pattern_exists(directory):
                team_info["roles"].append(role)
        
        # Estimate team size based on complexity and role diversity
        role_count = len(team_info["roles"])
        if role_count >= 4:
            team_info["size"] = "large"
        elif role_count >= 2:
            team_info["size"] = "medium" 
        else:
            team_info["size"] = "small"
        
        return team_info
    
    def generate_elite_enhancement(self, agent_info: Dict[str, Any], context: Dict[str, Any]) -> str:
        """Generate elite enhancement section."""
        sections = []
        
        sections.append("## 🚀 Elite Enhancement - Project Customization")
        sections.append(f"*Enhanced for {context['project_name']} - {datetime.now().strftime('%Y-%m-%d')}*")
        sections.append("")
        
        sections.append("### Project Intelligence")
        sections.append(f"- **Project Type**: {', '.join(context['detected_types'])}")
        sections.append(f"- **Complexity Level**: {context['complexity_level'].title()}")
        sections.append(f"- **Team Structure**: {context['team_indicators']['size'].title()} team")
        
        if context['frameworks']:
            sections.append(f"- **Technology Stack**: {', '.join(context['frameworks'])}")
        
        sections.append("")
        sections.append("### Elite Specialization")
        sections.append(f"- **Nickname**: `{agent_info['nickname']}` for instant invocation")
        sections.append(f"- **Mission**: {agent_info['purpose']}")
        sections.append(f"- **Expertise Focus**: {', '.join(agent_info['expertise'])}")
        sections.append(f"- **Personality**: {agent_info['personality']}")
        
        sections.append("")
        sections.append("### Project-Specific Adaptations")
        
        # Add context-specific adaptations
        if "enterprise" in context['complexity_level']:
            sections.append("- **Enterprise Focus**: Large-scale system considerations and enterprise patterns")
            sections.append("- **Governance**: Compliance, security, and architectural governance standards")
            
        if "fintech" in context['detected_types']:
            sections.append("- **Financial Compliance**: Banking regulations, security standards, audit trails")
            sections.append("- **Risk Management**: Financial risk assessment and mitigation strategies")
            
        if "startup" in context['complexity_level']:
            sections.append("- **Startup Optimization**: Rapid iteration, MVP focus, resource efficiency")
            sections.append("- **Scalability Planning**: Growth-ready solutions within startup constraints")
        
        sections.append("")
        sections.append("### Quick Invocation")
        sections.append(f"```bash")
        sections.append(f"# Use the elite nickname for instant access")
        sections.append(f"{agent_info['nickname']} \"Your request here\"")
        sections.append(f"```")
        
        return '\n'.join(sections)
    
    def create_elite_config(self, agents: List[str]) -> bool:
        """Create elite agent configuration file."""
        try:
            config = {
                "elite_agents": {
                    "version": "2.0",
                    "system_type": "Global Elite Agents",
                    "installed_agents": agents,
                    "project_context": self.get_project_context(),
                    "agent_details": {
                        agent: {
                            "nickname": self.elite_agents[agent]["nickname"],
                            "full_name": self.elite_agents[agent]["full_name"], 
                            "purpose": self.elite_agents[agent]["purpose"],
                            "expertise": self.elite_agents[agent]["expertise"]
                        }
                        for agent in agents if agent in self.elite_agents and not self.elite_agents[agent].get("coming_soon", False)
                    },
                    "installation_date": datetime.now().isoformat(),
                    "enhanced": True
                }
            }
            
            with open(self.config_file, 'w') as f:
                yaml.dump(config, f, default_flow_style=False, sort_keys=False)
            
            return True
            
        except Exception as e:
            print(f"Error creating elite config: {e}")
            return False
    
    def list_available_agents(self) -> Dict[str, Any]:
        """List all available elite agents."""
        available = {}
        coming_soon = {}
        
        for agent, info in self.elite_agents.items():
            agent_data = {
                "full_name": info["full_name"],
                "nickname": info["nickname"], 
                "purpose": info["purpose"],
                "expertise": info["expertise"],
                "use_cases": info["use_cases"],
                "file_exists": (self.agents_dir / info["file"]).exists()
            }
            
            if info.get("coming_soon", False):
                coming_soon[agent] = agent_data
            else:
                available[agent] = agent_data
        
        return {"available": available, "coming_soon": coming_soon}
    
    def list_installed_agents(self) -> List[Dict[str, Any]]:
        """List currently installed elite agents."""
        agents_dir = self.project_dir / ".agents"
        if not agents_dir.exists():
            return []
        
        installed = []
        for agent, info in self.elite_agents.items():
            agent_file = agents_dir / info["file"]
            if agent_file.exists():
                installed.append({
                    "code": agent,
                    "nickname": info["nickname"],
                    "full_name": info["full_name"],
                    "purpose": info["purpose"],
                    "file": info["file"]
                })
        
        return installed

def main():
    parser = argparse.ArgumentParser(description="Elite Global Agent System")
    parser.add_argument("--init", action="store_true", help="Initialize elite agents for current project")
    parser.add_argument("--agents", nargs="+", help="Specific elite agents to install")
    parser.add_argument("--list", action="store_true", help="List available elite agents")
    parser.add_argument("--installed", action="store_true", help="List installed elite agents")
    parser.add_argument("--show", help="Show details for specific agent")
    parser.add_argument("--agents-dir", help="Custom agents directory path")
    
    args = parser.parse_args()
    
    installer = EliteAgentInstaller(args.agents_dir)
    
    if args.list:
        agent_info = installer.list_available_agents()
        
        print("🌟 Available Elite Agents:")
        for agent, info in agent_info["available"].items():
            status = "✅" if info["file_exists"] else "❌"
            print(f"  {status} {agent} ({info['nickname']}) - {info['full_name']}")
            print(f"      Purpose: {info['purpose']}")
            print(f"      Use for: {', '.join(info['use_cases'])}")
            print()
        
        if agent_info["coming_soon"]:
            print("🚀 Coming Soon:")
            for agent, info in agent_info["coming_soon"].items():
                print(f"  ⏳ {agent} ({info['nickname']}) - {info['full_name']}")
                print(f"      Purpose: {info['purpose']}")
                print()
        return
    
    if args.installed:
        installed = installer.list_installed_agents()
        if installed:
            print("🎯 Installed Elite Agents:")
            for agent in installed:
                print(f"  • {agent['code']} ({agent['nickname']}) - {agent['full_name']}")
        else:
            print("No elite agents installed in this project")
        return
    
    if args.show:
        agent_code = args.show.upper()
        if agent_code in installer.elite_agents:
            info = installer.elite_agents[agent_code]
            print(f"🌟 {agent_code} - {info['full_name']}")
            print(f"Nickname: {info['nickname']}")
            print(f"Purpose: {info['purpose']}")
            print(f"Expertise: {', '.join(info['expertise'])}")
            print(f"Use Cases: {', '.join(info['use_cases'])}")
            print(f"Personality: {info['personality']}")
            if info.get("coming_soon", False):
                print("Status: Coming Soon")
        else:
            print(f"Unknown elite agent: {agent_code}")
        return
    
    if args.init or args.agents:
        if args.agents:
            agents_to_install = [a.upper() for a in args.agents]
        else:
            project_types = installer.detect_project_type()
            if project_types:
                print(f"🔍 Detected project types: {', '.join(project_types)}")
                agents_to_install = installer.get_recommended_agents(project_types)
                print(f"💡 Recommended elite agents: {', '.join(agents_to_install)}")
            else:
                print("Using core elite agents for general development")
                agents_to_install = installer.core_elite_agents
        
        print(f"🚀 Installing elite agents: {', '.join(agents_to_install)}")
        results = installer.install_agents(agents_to_install, enhanced=True)
        
        if results["installed"]:
            print(f"✅ Successfully installed: {', '.join(results['installed'])}")
        if results["enhanced"]:
            print(f"🧠 Enhanced with project intelligence: {', '.join(results['enhanced'])}")
        if results["coming_soon"]:
            print(f"⏳ Coming soon: {', '.join(results['coming_soon'])}")
        if results["errors"]:
            print(f"❌ Errors: {', '.join(results['errors'])}")
        if results["config_created"]:
            print("📝 Created .elite-agents.yaml configuration")

if __name__ == "__main__":
    main()