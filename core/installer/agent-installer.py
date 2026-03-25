#!/usr/bin/env python3
"""
Exxede Agent Installation System
Automatically detects project type and installs relevant AI agents with enhanced training.
"""

import os
import json
import yaml
import shutil
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime

class AgentInstaller:
    def __init__(self, agents_dir: str = None):
        self.agents_dir = Path(agents_dir or os.path.expanduser("~/Desktop/agents"))
        self.project_dir = Path.cwd()
        self.config_file = self.project_dir / ".exxede-agents.yaml"
        self.training_dir = self.agents_dir / "training"
        self.enhancements_dir = self.agents_dir / "enhancements"
        
        # Project type detection patterns
        self.project_patterns = {
            "nextjs": ["next.config.js", "next.config.ts", "pages/", "app/"],
            "react": ["package.json", "src/App.js", "src/App.tsx", "public/index.html"],
            "vue": ["vue.config.js", "src/main.js", "src/App.vue"],
            "nodejs-api": ["package.json", "server.js", "app.js", "index.js"],
            "python-api": ["requirements.txt", "app.py", "main.py", "pyproject.toml"],
            "mobile-app": ["package.json", "android/", "ios/", "App.tsx", "App.js"],
            "marketing-site": ["index.html", "assets/", "css/", "js/"],
            "ecommerce": ["package.json", "products/", "cart/", "checkout/"],
            "fintech": ["package.json", "payments/", "transactions/", "wallet/"],
            "tourism": ["bookings/", "reservations/", "tours/", "hotels/"],
            "saas": ["package.json", "dashboard/", "auth/", "billing/"],
            "data-analysis": ["requirements.txt", "notebooks/", "data/", "analysis/"],
            "devops": ["docker-compose.yml", "Dockerfile", "terraform/", "k8s/"],
            "content-site": ["content/", "blog/", "posts/", "_posts/"],
        }
        
        # Agent recommendations by project type
        self.agent_recommendations = {
            "nextjs": ["fullstack-dev-agent", "devops-automation-agent", "qa-testing-agent", "product-strategy-agent"],
            "react": ["fullstack-dev-agent", "qa-testing-agent", "devops-automation-agent"],
            "vue": ["fullstack-dev-agent", "qa-testing-agent", "devops-automation-agent"],
            "nodejs-api": ["fullstack-dev-agent", "devops-automation-agent", "qa-testing-agent"],
            "python-api": ["fullstack-dev-agent", "devops-automation-agent", "qa-testing-agent"],
            "mobile-app": ["fullstack-dev-agent", "qa-testing-agent", "product-strategy-agent", "digital-marketing-agent"],
            "marketing-site": ["digital-marketing-agent", "content-creation-agent", "devops-automation-agent"],
            "ecommerce": ["fullstack-dev-agent", "product-strategy-agent", "digital-marketing-agent", "qa-testing-agent", "dominican-market-specialist"],
            "fintech": ["fullstack-dev-agent", "investment-research-agent", "qa-testing-agent", "devops-automation-agent", "dominican-market-specialist"],
            "tourism": ["digital-marketing-agent", "content-creation-agent", "dominican-market-specialist", "product-strategy-agent"],
            "saas": ["fullstack-dev-agent", "product-strategy-agent", "devops-automation-agent", "qa-testing-agent", "digital-marketing-agent"],
            "data-analysis": ["market-research-agent", "investment-research-agent", "strategic-business-analyst"],
            "devops": ["devops-automation-agent", "qa-testing-agent"],
            "content-site": ["content-creation-agent", "digital-marketing-agent", "devops-automation-agent"],
        }
        
        # Business context agents (always recommended for Exxede projects)
        self.core_business_agents = ["strategic-business-analyst", "dominican-market-specialist"]
    
    def detect_project_type(self) -> List[str]:
        """Detect project type(s) based on file patterns."""
        detected_types = []
        
        for project_type, patterns in self.project_patterns.items():
            for pattern in patterns:
                if self._pattern_exists(pattern):
                    detected_types.append(project_type)
                    break
        
        return detected_types
    
    def _pattern_exists(self, pattern: str) -> bool:
        """Check if a pattern exists in the project directory."""
        if pattern.endswith('/'):
            # Directory pattern
            return (self.project_dir / pattern.rstrip('/')).is_dir()
        else:
            # File pattern
            return (self.project_dir / pattern).exists()
    
    def get_recommended_agents(self, project_types: List[str], include_core: bool = True) -> List[str]:
        """Get recommended agents based on project types."""
        recommended = set()
        
        # Add core business agents for all Exxede projects
        if include_core:
            recommended.update(self.core_business_agents)
        
        # Add project-specific agents
        for project_type in project_types:
            if project_type in self.agent_recommendations:
                recommended.update(self.agent_recommendations[project_type])
        
        return list(recommended)
    
    def install_agents(self, agents: List[str], enhanced: bool = True) -> Dict[str, Any]:
        """Install agents with optional enhancement."""
        results = {
            "installed": [],
            "enhanced": [],
            "errors": [],
            "config_created": False
        }
        
        # Create project agents directory
        project_agents_dir = self.project_dir / ".agents"
        project_agents_dir.mkdir(exist_ok=True)
        
        for agent in agents:
            try:
                # Copy base agent
                source_file = self.agents_dir / f"{agent}.md"
                dest_file = project_agents_dir / f"{agent}.md"
                
                if source_file.exists():
                    shutil.copy2(source_file, dest_file)
                    results["installed"].append(agent)
                    
                    # Apply enhancements if requested
                    if enhanced:
                        enhanced_agent = self.enhance_agent(agent, dest_file)
                        if enhanced_agent:
                            results["enhanced"].append(agent)
                else:
                    results["errors"].append(f"Agent {agent} not found")
                    
            except Exception as e:
                results["errors"].append(f"Error installing {agent}: {str(e)}")
        
        # Create or update configuration
        if self.create_project_config(agents):
            results["config_created"] = True
        
        return results
    
    def enhance_agent(self, agent_name: str, agent_file: Path) -> bool:
        """Enhance agent with project-specific context and training."""
        try:
            # Read base agent content
            with open(agent_file, 'r') as f:
                content = f.read()
            
            # Get project context
            project_context = self.get_project_context()
            
            # Get agent training data
            training_data = self.get_agent_training(agent_name)
            
            # Apply enhancements
            enhanced_content = self.apply_enhancements(content, project_context, training_data)
            
            # Write enhanced agent
            with open(agent_file, 'w') as f:
                f.write(enhanced_content)
            
            return True
            
        except Exception as e:
            print(f"Error enhancing {agent_name}: {e}")
            return False
    
    def get_project_context(self) -> Dict[str, Any]:
        """Extract project context for agent enhancement."""
        context = {
            "project_name": self.project_dir.name,
            "project_path": str(self.project_dir),
            "detected_types": self.detect_project_type(),
            "has_git": (self.project_dir / ".git").exists(),
            "package_manager": self.detect_package_manager(),
            "frameworks": self.detect_frameworks(),
            "databases": self.detect_databases(),
            "deployment_targets": self.detect_deployment_targets(),
            "created_at": datetime.now().isoformat()
        }
        return context
    
    def detect_package_manager(self) -> Optional[str]:
        """Detect package manager being used."""
        if (self.project_dir / "package-lock.json").exists():
            return "npm"
        elif (self.project_dir / "yarn.lock").exists():
            return "yarn"
        elif (self.project_dir / "pnpm-lock.yaml").exists():
            return "pnpm"
        elif (self.project_dir / "requirements.txt").exists():
            return "pip"
        elif (self.project_dir / "Pipfile").exists():
            return "pipenv"
        elif (self.project_dir / "pyproject.toml").exists():
            return "poetry"
        return None
    
    def detect_frameworks(self) -> List[str]:
        """Detect frameworks and libraries in use."""
        frameworks = []
        
        # Check package.json for JavaScript frameworks
        package_json = self.project_dir / "package.json"
        if package_json.exists():
            try:
                with open(package_json) as f:
                    data = json.load(f)
                    deps = {**data.get("dependencies", {}), **data.get("devDependencies", {})}
                    
                    if "next" in deps:
                        frameworks.append("Next.js")
                    if "react" in deps:
                        frameworks.append("React")
                    if "vue" in deps:
                        frameworks.append("Vue.js")
                    if "express" in deps:
                        frameworks.append("Express")
                    if "@nestjs/core" in deps:
                        frameworks.append("NestJS")
                    if "tailwindcss" in deps:
                        frameworks.append("Tailwind CSS")
                        
            except json.JSONDecodeError:
                pass
        
        # Check for Python frameworks
        requirements_file = self.project_dir / "requirements.txt"
        if requirements_file.exists():
            try:
                with open(requirements_file) as f:
                    content = f.read().lower()
                    if "fastapi" in content:
                        frameworks.append("FastAPI")
                    if "django" in content:
                        frameworks.append("Django")
                    if "flask" in content:
                        frameworks.append("Flask")
                        
            except Exception:
                pass
        
        return frameworks
    
    def detect_databases(self) -> List[str]:
        """Detect database technologies in use."""
        databases = []
        
        # Check for database files
        if (self.project_dir / "prisma").exists():
            databases.append("Prisma")
        if any(self.project_dir.glob("*.db")):
            databases.append("SQLite")
        if (self.project_dir / "docker-compose.yml").exists():
            try:
                with open(self.project_dir / "docker-compose.yml") as f:
                    content = f.read().lower()
                    if "postgres" in content:
                        databases.append("PostgreSQL")
                    if "mysql" in content:
                        databases.append("MySQL")
                    if "mongo" in content:
                        databases.append("MongoDB")
                    if "redis" in content:
                        databases.append("Redis")
            except Exception:
                pass
        
        return databases
    
    def detect_deployment_targets(self) -> List[str]:
        """Detect deployment targets and platforms."""
        targets = []
        
        if (self.project_dir / "vercel.json").exists():
            targets.append("Vercel")
        if (self.project_dir / "netlify.toml").exists():
            targets.append("Netlify")
        if (self.project_dir / "Dockerfile").exists():
            targets.append("Docker")
        if (self.project_dir / ".github" / "workflows").exists():
            targets.append("GitHub Actions")
        if (self.project_dir / "terraform").exists():
            targets.append("Terraform")
        if (self.project_dir / "k8s").exists() or (self.project_dir / "kubernetes").exists():
            targets.append("Kubernetes")
        
        return targets
    
    def get_agent_training(self, agent_name: str) -> Dict[str, Any]:
        """Load training data for specific agent."""
        training_file = self.training_dir / f"{agent_name}.yaml"
        
        if training_file.exists():
            try:
                with open(training_file) as f:
                    return yaml.safe_load(f) or {}
            except Exception:
                pass
        
        return {}
    
    def apply_enhancements(self, content: str, project_context: Dict[str, Any], training_data: Dict[str, Any]) -> str:
        """Apply enhancements to agent content."""
        enhanced_content = content
        
        # Add project-specific context section
        context_section = self.generate_context_section(project_context)
        enhanced_content += f"\n\n## Project Context\n{context_section}"
        
        # Add training enhancements
        if training_data:
            training_section = self.generate_training_section(training_data)
            enhanced_content += f"\n\n## Enhanced Training\n{training_section}"
        
        # Add project-specific examples
        examples_section = self.generate_examples_section(project_context)
        enhanced_content += f"\n\n## Project-Specific Examples\n{examples_section}"
        
        return enhanced_content
    
    def generate_context_section(self, context: Dict[str, Any]) -> str:
        """Generate project context section."""
        sections = []
        
        sections.append(f"**Project Name**: {context['project_name']}")
        sections.append(f"**Project Types**: {', '.join(context['detected_types'])}")
        
        if context.get('frameworks'):
            sections.append(f"**Frameworks**: {', '.join(context['frameworks'])}")
        
        if context.get('databases'):
            sections.append(f"**Databases**: {', '.join(context['databases'])}")
        
        if context.get('deployment_targets'):
            sections.append(f"**Deployment**: {', '.join(context['deployment_targets'])}")
        
        if context.get('package_manager'):
            sections.append(f"**Package Manager**: {context['package_manager']}")
        
        return '\n'.join(sections)
    
    def generate_training_section(self, training_data: Dict[str, Any]) -> str:
        """Generate training enhancements section."""
        sections = []
        
        if 'specializations' in training_data:
            sections.append("### Enhanced Specializations")
            for spec in training_data['specializations']:
                sections.append(f"- {spec}")
        
        if 'context_prompts' in training_data:
            sections.append("\n### Context-Aware Prompts")
            for prompt in training_data['context_prompts']:
                sections.append(f"- {prompt}")
        
        if 'best_practices' in training_data:
            sections.append("\n### Additional Best Practices")
            for practice in training_data['best_practices']:
                sections.append(f"- {practice}")
        
        return '\n'.join(sections)
    
    def generate_examples_section(self, context: Dict[str, Any]) -> str:
        """Generate project-specific examples."""
        examples = []
        
        project_types = context.get('detected_types', [])
        
        if 'nextjs' in project_types:
            examples.append("### Next.js Specific Usage")
            examples.append("```")
            examples.append("I need help optimizing this Next.js application for:")
            examples.append("- Server-side rendering performance")
            examples.append("- API route implementation")
            examples.append("- Dynamic routing and internationalization")
            examples.append("```")
        
        if 'fintech' in project_types:
            examples.append("### Fintech Context")
            examples.append("```")
            examples.append("Focus on Dominican Republic financial regulations:")
            examples.append("- Central Bank compliance requirements")
            examples.append("- Payment processing integrations")
            examples.append("- KYC/AML implementation")
            examples.append("```")
        
        if 'tourism' in project_types:
            examples.append("### Tourism Industry Focus")
            examples.append("```")
            examples.append("Consider Punta Cana tourism market:")
            examples.append("- Seasonal booking patterns")
            examples.append("- Multi-language support")
            examples.append("- Tour operator integrations")
            examples.append("```")
        
        return '\n'.join(examples) if examples else "No specific examples for detected project types."
    
    def create_project_config(self, agents: List[str]) -> bool:
        """Create project configuration file."""
        try:
            config = {
                "exxede_agents": {
                    "version": "1.0",
                    "installed_agents": agents,
                    "project_context": self.get_project_context(),
                    "installation_date": datetime.now().isoformat(),
                    "auto_update": True,
                    "enhanced": True
                }
            }
            
            with open(self.config_file, 'w') as f:
                yaml.dump(config, f, default_flow_style=False, sort_keys=False)
            
            return True
            
        except Exception as e:
            print(f"Error creating config: {e}")
            return False
    
    def list_installed_agents(self) -> List[str]:
        """List currently installed agents."""
        agents_dir = self.project_dir / ".agents"
        if not agents_dir.exists():
            return []
        
        return [f.stem for f in agents_dir.glob("*.md")]
    
    def update_agents(self) -> Dict[str, Any]:
        """Update installed agents with latest versions."""
        results = {"updated": [], "errors": []}
        
        installed = self.list_installed_agents()
        for agent in installed:
            try:
                source_file = self.agents_dir / f"{agent}.md"
                dest_file = self.project_dir / ".agents" / f"{agent}.md"
                
                if source_file.exists():
                    # Backup current version
                    backup_file = dest_file.with_suffix(".md.backup")
                    shutil.copy2(dest_file, backup_file)
                    
                    # Update with enhanced version
                    shutil.copy2(source_file, dest_file)
                    self.enhance_agent(agent, dest_file)
                    results["updated"].append(agent)
                else:
                    results["errors"].append(f"Source agent {agent} not found")
                    
            except Exception as e:
                results["errors"].append(f"Error updating {agent}: {str(e)}")
        
        return results

def main():
    parser = argparse.ArgumentParser(description="Exxede Agent Installation System")
    parser.add_argument("--init", action="store_true", help="Initialize agents for current project")
    parser.add_argument("--agents", nargs="+", help="Specific agents to install")
    parser.add_argument("--list", action="store_true", help="List available agents")
    parser.add_argument("--installed", action="store_true", help="List installed agents")
    parser.add_argument("--update", action="store_true", help="Update installed agents")
    parser.add_argument("--no-enhance", action="store_true", help="Skip enhancement step")
    parser.add_argument("--agents-dir", help="Custom agents directory path")
    
    args = parser.parse_args()
    
    installer = AgentInstaller(args.agents_dir)
    
    if args.list:
        # List available agents
        if installer.agents_dir.exists():
            agents = [f.stem for f in installer.agents_dir.glob("*.md") if not f.name.startswith(("README", "USAGE"))]
            print("Available agents:")
            for agent in sorted(agents):
                print(f"  - {agent}")
        else:
            print("Agents directory not found")
        return
    
    if args.installed:
        # List installed agents
        installed = installer.list_installed_agents()
        if installed:
            print("Installed agents:")
            for agent in sorted(installed):
                print(f"  - {agent}")
        else:
            print("No agents installed in this project")
        return
    
    if args.update:
        # Update installed agents
        print("Updating installed agents...")
        results = installer.update_agents()
        
        if results["updated"]:
            print(f"Updated agents: {', '.join(results['updated'])}")
        if results["errors"]:
            print(f"Errors: {', '.join(results['errors'])}")
        return
    
    if args.init or args.agents:
        # Install agents
        if args.agents:
            agents_to_install = args.agents
        else:
            # Auto-detect project type and recommend agents
            project_types = installer.detect_project_type()
            if project_types:
                print(f"Detected project types: {', '.join(project_types)}")
                agents_to_install = installer.get_recommended_agents(project_types)
                print(f"Recommended agents: {', '.join(agents_to_install)}")
            else:
                print("Could not detect project type. Installing core business agents.")
                agents_to_install = installer.core_business_agents
        
        print(f"Installing agents: {', '.join(agents_to_install)}")
        results = installer.install_agents(agents_to_install, not args.no_enhance)
        
        print(f"Successfully installed: {', '.join(results['installed'])}")
        if results["enhanced"]:
            print(f"Enhanced with project context: {', '.join(results['enhanced'])}")
        if results["errors"]:
            print(f"Errors: {', '.join(results['errors'])}")
        if results["config_created"]:
            print("Created .exxede-agents.yaml configuration file")

if __name__ == "__main__":
    main()