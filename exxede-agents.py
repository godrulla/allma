#!/usr/bin/env python3
"""
Exxede Agent System - Unified Management Interface
Enhanced enterprise-grade CLI with universal functionality.

Author: Armando Diaz Silverio, CEO of Exxede Investments
Version: 4.0 - Universal CLI Integration with Enterprise Features
"""

import os
import sys
import asyncio
from pathlib import Path

# Add core modules to path
AGENTS_DIR = Path(__file__).parent
sys.path.insert(0, str(AGENTS_DIR))
sys.path.insert(0, str(AGENTS_DIR / "core"))

# Try to use the new universal CLI system
try:
    from core.cli.universal_cli import ExxedeAgentsCLI
    UNIVERSAL_CLI_AVAILABLE = True
except ImportError as e:
    # Fallback to legacy system
    UNIVERSAL_CLI_AVAILABLE = False
    
    # Import legacy dependencies
    import json
    import yaml
    import shutil
    import argparse
    import importlib.util
    from datetime import datetime
    from typing import Dict, List, Optional, Any, Tuple
    
    sys.path.insert(0, str(AGENTS_DIR / "core" / "installer"))
    sys.path.insert(0, str(AGENTS_DIR / "core" / "orchestrator"))
    sys.path.insert(0, str(AGENTS_DIR / "core" / "testing"))

class ExxedeAgentSystem:
    """Unified Exxede Agent System Management."""
    
    def __init__(self):
        self.base_dir = Path(__file__).parent
        self.agents_dir = self.base_dir / "agents"
        self.config_dir = self.base_dir / "config"
        self.core_dir = self.base_dir / "core"
        self.utils_dir = self.base_dir / "utils"
        self.docs_dir = self.base_dir / "docs"
        
        # Agent categories
        self.elite_dir = self.agents_dir / "elite"
        self.specialized_dir = self.agents_dir / "specialized"
        self.legacy_dir = self.agents_dir / "legacy"
        
        # Load system configuration
        self.config = self.load_system_config()
        
        # Elite agents metadata
        self.elite_agents = {
            "ARQ": {"nickname": "*arq", "full_name": "Visionary Architect", "purpose": "Building tomorrow's systems with today's vision"},
            "APEX": {"nickname": "*apex", "full_name": "Mobile Web Virtuoso", "purpose": "Crafting experiences that feel native, perform lightning-fast"},
            "ZEN": {"nickname": "*zen", "full_name": "Code Zen Master", "purpose": "Writing code that transcends mere functionality"},
            "VEX": {"nickname": "*vex", "full_name": "Creative Visionary", "purpose": "Designing experiences that move souls"},
            "SAGE": {"nickname": "*sage", "full_name": "Strategic Oracle", "purpose": "Seeing patterns others miss, predicting what others can't"},
            "NOVA": {"nickname": "*nova", "full_name": "Innovation Catalyst", "purpose": "Turning impossible ideas into inevitable realities"},
            "ECHO": {"nickname": "*echo", "full_name": "Voice of the People", "purpose": "Amplifying authentic human connections through technology"},
            "ORC": {"nickname": "*orc", "full_name": "Master Orchestrator", "purpose": "Conducting symphonies of complex workflows"}
        }
    
    def load_system_config(self) -> Dict[str, Any]:
        """Load system configuration."""
        config_file = self.config_dir / "system.yaml"
        if config_file.exists():
            try:
                with open(config_file) as f:
                    return yaml.safe_load(f) or {}
            except Exception:
                pass
        return self.create_default_config()
    
    def create_default_config(self) -> Dict[str, Any]:
        """Create default system configuration."""
        return {
            "system": {
                "version": "3.0",
                "name": "Exxede Agent System",
                "reorganized": datetime.now().isoformat()
            },
            "categories": {
                "elite": "World-class agents with cutting-edge expertise",
                "specialized": "Task-specific agents for particular domains",
                "legacy": "Previous versions and deprecated agents"
            },
            "default_recommendations": {
                "fintech": ["SAGE", "ARQ", "ZEN"],
                "saas": ["ARQ", "VEX", "SAGE"],
                "ecommerce": ["VEX", "ECHO", "SAGE"],
                "startup": ["SAGE", "NOVA", "VEX"],
                "enterprise": ["ARQ", "ORC", "ZEN"]
            }
        }
    
    def save_system_config(self):
        """Save system configuration."""
        config_file = self.config_dir / "system.yaml"
        config_file.parent.mkdir(exist_ok=True)
        with open(config_file, 'w') as f:
            yaml.dump(self.config, f, default_flow_style=False, sort_keys=False)
    
    def list_agents(self, category: str = "all") -> Dict[str, List[Dict[str, Any]]]:
        """List available agents by category."""
        agents = {"elite": [], "specialized": [], "legacy": []}
        
        # List elite agents
        if category in ["all", "elite"]:
            for agent_file in self.elite_dir.glob("*.md"):
                agent_code = agent_file.stem
                agent_info = self.elite_agents.get(agent_code, {
                    "nickname": f"*{agent_code.lower()}",
                    "full_name": f"{agent_code} Agent",
                    "purpose": "Elite agent"
                })
                agents["elite"].append({
                    "code": agent_code,
                    "file": str(agent_file),
                    "category": "elite",
                    **agent_info
                })
        
        # List specialized agents
        if category in ["all", "specialized"]:
            for agent_file in self.specialized_dir.glob("*.md"):
                agent_name = agent_file.stem
                agents["specialized"].append({
                    "name": agent_name,
                    "file": str(agent_file),
                    "category": "specialized",
                    "display_name": agent_name.replace("-", " ").title()
                })
        
        # List legacy agents
        if category in ["all", "legacy"]:
            for agent_file in self.legacy_dir.glob("*.md"):
                agent_name = agent_file.stem
                agents["legacy"].append({
                    "name": agent_name,
                    "file": str(agent_file),
                    "category": "legacy",
                    "display_name": agent_name.replace("-", " ").title()
                })
        
        return agents
    
    def install_agents(self, project_dir: str, agents: List[str] = None, 
                      category: str = None, auto_detect: bool = True) -> Dict[str, Any]:
        """Install agents to a project."""
        # Import and use the consolidated installer
        try:
            from agent_installer import AgentInstaller
            installer = AgentInstaller(str(self.base_dir))
            installer.project_dir = Path(project_dir)
            
            if not agents and auto_detect:
                # Auto-detect project type and recommend agents
                project_types = installer.detect_project_type()
                agents = installer.get_recommended_agents(project_types)
            
            if not agents:
                agents = ["SAGE", "ARQ"]  # Default core agents
            
            return installer.install_agents(agents, enhanced=True)
            
        except ImportError:
            return {"error": "Agent installer not available", "installed": [], "errors": []}
    
    def create_project(self, project_path: str, project_type: str = "general") -> Dict[str, Any]:
        """Create a new project with agents."""
        try:
            import importlib.util
            spec = importlib.util.spec_from_file_location(
                "create_elite_project", 
                self.core_dir / "installer" / "create-elite-project.py"
            )
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            
            module.create_elite_project(project_path)
            return {"success": True, "project_path": project_path}
        except Exception as e:
            return {"error": f"Failed to create project: {str(e)}"}
    
    def orchestrate_session(self, task_description: str, agents: List[str] = None) -> Dict[str, Any]:
        """Create multi-model orchestration session."""
        try:
            from multi_model_orchestrator import MultiModelOrchestrator
            orchestrator = MultiModelOrchestrator()
            context = orchestrator.create_session_context(task_description, agents)
            return {"success": True, "context": context}
        except Exception as e:
            return {"error": f"Orchestration failed: {str(e)}"}
    
    def activate_agent(self, command: str) -> Dict[str, Any]:
        """Activate agent by nickname."""
        try:
            spec = importlib.util.spec_from_file_location(
                "nickname_agent_activator", 
                self.core_dir / "orchestrator" / "nickname-agent-activator.py"
            )
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            
            activator = module.NicknameAgentActivator()
            return activator.activate_agent(command)
        except Exception as e:
            return {"error": f"Agent activation failed: {str(e)}"}
    
    def test_agents(self) -> Dict[str, Any]:
        """Test all agent activations."""
        try:
            import importlib.util
            spec = importlib.util.spec_from_file_location(
                "test_all_agents", 
                self.core_dir / "testing" / "test-all-agents.py"
            )
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            
            module.test_all_agents()
            return {"success": True, "message": "All agents tested"}
        except Exception as e:
            return {"error": f"Testing failed: {str(e)}"}
    
    def migrate_legacy_setup(self, legacy_dir: str) -> Dict[str, Any]:
        """Migrate from legacy setup to new structure."""
        legacy_path = Path(legacy_dir)
        results = {"migrated": [], "errors": [], "backed_up": []}
        
        # Backup existing setup
        backup_dir = legacy_path.parent / f"{legacy_path.name}_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        shutil.copytree(legacy_path, backup_dir)
        results["backed_up"].append(str(backup_dir))
        
        # Migrate agents
        for agent_file in legacy_path.glob("*.md"):
            if agent_file.stem in self.elite_agents:
                dest = self.elite_dir / agent_file.name
            else:
                dest = self.specialized_dir / agent_file.name
            
            try:
                shutil.copy2(agent_file, dest)
                results["migrated"].append(f"{agent_file.name} -> {dest.parent.name}")
            except Exception as e:
                results["errors"].append(f"Failed to migrate {agent_file.name}: {str(e)}")
        
        return results
    
    def validate_system(self) -> Dict[str, Any]:
        """Validate system integrity."""
        issues = []
        
        # Check directory structure
        required_dirs = [
            self.agents_dir, self.elite_dir, self.specialized_dir,
            self.config_dir, self.core_dir, self.utils_dir
        ]
        
        for dir_path in required_dirs:
            if not dir_path.exists():
                issues.append(f"Missing directory: {dir_path}")
        
        # Check elite agents
        for agent_code in self.elite_agents:
            agent_file = self.elite_dir / f"{agent_code}.md"
            if not agent_file.exists():
                issues.append(f"Missing elite agent: {agent_code}")
        
        # Check core scripts
        core_scripts = [
            "core/installer/agent-installer.py",
            "core/orchestrator/multi-model-orchestrator.py",
            "core/testing/test-all-agents.py"
        ]
        
        for script_path in core_scripts:
            if not (self.base_dir / script_path).exists():
                issues.append(f"Missing core script: {script_path}")
        
        return {
            "valid": len(issues) == 0,
            "issues": issues,
            "agent_counts": {
                "elite": len(list(self.elite_dir.glob("*.md"))),
                "specialized": len(list(self.specialized_dir.glob("*.md"))),
                "legacy": len(list(self.legacy_dir.glob("*.md")))
            }
        }
    
    def get_system_status(self) -> Dict[str, Any]:
        """Get comprehensive system status."""
        agents = self.list_agents()
        validation = self.validate_system()
        
        return {
            "system": self.config["system"],
            "structure": {
                "elite_agents": len(agents["elite"]),
                "specialized_agents": len(agents["specialized"]),
                "legacy_agents": len(agents["legacy"])
            },
            "validation": validation,
            "last_updated": datetime.now().isoformat()
        }


def main():
    """Main CLI interface with universal CLI integration."""
    # Use universal CLI if available
    if UNIVERSAL_CLI_AVAILABLE:
        try:
            cli = ExxedeAgentsCLI()
            return asyncio.run(cli.run())
        except Exception as e:
            print(f"❌ Universal CLI error: {e}")
            print("📦 Falling back to legacy CLI...")
    
    # Legacy CLI fallback
    parser = argparse.ArgumentParser(
        description="Exxede Agent System - Unified Management Interface (Legacy Mode)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Legacy Mode Examples:
  %(prog)s list                          # List all agents
  %(prog)s list --category elite         # List only elite agents
  %(prog)s install /path/to/project      # Auto-install agents for project
  %(prog)s install /path/to/project --agents ARQ ZEN VEX
  %(prog)s create /path/to/new-project   # Create new project with agents
  %(prog)s orchestrate "Design a scalable API"
  %(prog)s activate "*arq design microservices"
  %(prog)s test                          # Test all agent activations
  %(prog)s migrate /old/agents/dir       # Migrate legacy setup
  %(prog)s status                        # Show system status
  %(prog)s validate                      # Validate system integrity

Note: For enhanced features, ensure universal CLI dependencies are installed.
        """
    )
    
    parser.add_argument("command", choices=[
        "list", "install", "create", "orchestrate", "activate", 
        "test", "migrate", "status", "validate"
    ], help="Command to execute")
    
    parser.add_argument("target", nargs="?", help="Target path or task description")
    parser.add_argument("--category", choices=["elite", "specialized", "legacy"], 
                       help="Agent category filter")
    parser.add_argument("--agents", nargs="+", help="Specific agents to use")
    parser.add_argument("--type", help="Project type for recommendations")
    parser.add_argument("--no-enhance", action="store_true", help="Skip enhancement")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    
    args = parser.parse_args()
    
    system = ExxedeAgentSystem()
    result = {}
    
    try:
        if args.command == "list":
            result = system.list_agents(args.category or "all")
            if not args.json:
                print("🌟 Exxede Agent System - Available Agents")
                print("=" * 50)
                for category, agents in result.items():
                    if agents:
                        print(f"\n{category.upper()} AGENTS ({len(agents)}):")
                        for agent in agents:
                            if category == "elite":
                                print(f"  {agent['code']} ({agent['nickname']}) - {agent['full_name']}")
                                print(f"    Purpose: {agent['purpose']}")
                            else:
                                print(f"  {agent['name']} - {agent['display_name']}")
                        print()
        
        elif args.command == "install":
            if not args.target:
                parser.error("install requires a target project directory")
            result = system.install_agents(args.target, args.agents, args.category)
            if not args.json:
                print(f"🚀 Installing agents to: {args.target}")
                if result.get("installed"):
                    print(f"✅ Installed: {', '.join(result['installed'])}")
                if result.get("errors"):
                    print(f"❌ Errors: {', '.join(result['errors'])}")
        
        elif args.command == "create":
            if not args.target:
                parser.error("create requires a target project path")
            result = system.create_project(args.target, args.type or "general")
            if not args.json:
                if result.get("success"):
                    print(f"🎉 Created project: {result['project_path']}")
                else:
                    print(f"❌ Error: {result.get('error')}")
        
        elif args.command == "orchestrate":
            if not args.target:
                parser.error("orchestrate requires a task description")
            result = system.orchestrate_session(args.target, args.agents)
            if not args.json:
                if result.get("success"):
                    context = result["context"]
                    print(f"🎯 Orchestration created for: {args.target}")
                    print(f"💰 Estimated cost: ${context['cost_analysis']['total_estimated_cost']}")
                    print(f"🤖 Active agents: {', '.join(context['active_agents'])}")
                else:
                    print(f"❌ Error: {result.get('error')}")
        
        elif args.command == "activate":
            if not args.target:
                parser.error("activate requires a command")
            result = system.activate_agent(args.target)
            if not args.json:
                if result and "error" not in result:
                    print(f"🚀 Activated: {result['agent']['agent_id']}")
                    print(f"💰 Cost: ${result['model_selection']['estimated_cost']:.4f}")
                else:
                    print(f"❌ Error: {result.get('error') if result else 'Activation failed'}")
        
        elif args.command == "test":
            result = system.test_agents()
            if not args.json:
                if result.get("success"):
                    print("✅ All agent tests completed")
                else:
                    print(f"❌ Testing failed: {result.get('error')}")
        
        elif args.command == "migrate":
            if not args.target:
                parser.error("migrate requires a legacy directory path")
            result = system.migrate_legacy_setup(args.target)
            if not args.json:
                print(f"🔄 Migration from: {args.target}")
                print(f"📁 Backup created: {result['backed_up'][0] if result['backed_up'] else 'None'}")
                print(f"✅ Migrated: {len(result['migrated'])} files")
                if result["errors"]:
                    print(f"❌ Errors: {len(result['errors'])}")
        
        elif args.command == "status":
            result = system.get_system_status()
            if not args.json:
                print("📊 Exxede Agent System Status")
                print("=" * 40)
                print(f"Version: {result['system']['version']}")
                print(f"Elite Agents: {result['structure']['elite_agents']}")
                print(f"Specialized Agents: {result['structure']['specialized_agents']}")
                print(f"System Valid: {'✅' if result['validation']['valid'] else '❌'}")
                if result['validation']['issues']:
                    print("Issues:")
                    for issue in result['validation']['issues']:
                        print(f"  - {issue}")
        
        elif args.command == "validate":
            result = system.validate_system()
            if not args.json:
                print("🔍 System Validation")
                print("=" * 30)
                print(f"Status: {'✅ Valid' if result['valid'] else '❌ Issues Found'}")
                print(f"Elite Agents: {result['agent_counts']['elite']}")
                print(f"Specialized Agents: {result['agent_counts']['specialized']}")
                if result['issues']:
                    print("\nIssues Found:")
                    for issue in result['issues']:
                        print(f"  - {issue}")
        
        if args.json:
            print(json.dumps(result, indent=2, default=str))
            
    except Exception as e:
        if args.json:
            print(json.dumps({"error": str(e)}, indent=2))
        else:
            print(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()