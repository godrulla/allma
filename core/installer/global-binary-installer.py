#!/usr/bin/env python3
"""
Global Binary Installation System for Exxede Agent System
Enterprise-grade installation and configuration management
"""

import os
import sys
import shutil
import subprocess
import platform
import json
import yaml
from pathlib import Path
from typing import Dict, List, Optional, Any
import tempfile
import urllib.request
import hashlib
import tarfile
import zipfile
from dataclasses import dataclass
from enum import Enum

class InstallationMode(Enum):
    USER = "user"
    SYSTEM = "system"
    PORTABLE = "portable"

class Platform(Enum):
    LINUX = "linux"
    MACOS = "macos"
    WINDOWS = "windows"

@dataclass
class BinaryConfig:
    name: str
    version: str
    description: str
    executable_path: str
    dependencies: List[str]
    shell_completion: bool = True
    man_page: bool = True
    desktop_entry: bool = False

class GlobalBinaryInstaller:
    """Enterprise-grade binary installer for Exxede Agent System."""
    
    def __init__(self, mode: InstallationMode = InstallationMode.USER):
        self.mode = mode
        self.platform = self._detect_platform()
        self.home_dir = Path.home()
        self.script_dir = Path(__file__).parent.parent.parent
        
        # Installation paths based on mode
        if mode == InstallationMode.USER:
            self.bin_dir = self.home_dir / ".local" / "bin"
            self.config_dir = self.home_dir / ".config" / "exxede"
            self.data_dir = self.home_dir / ".local" / "share" / "exxede"
            self.man_dir = self.home_dir / ".local" / "share" / "man" / "man1"
            self.completion_dir = self.home_dir / ".local" / "share" / "bash-completion" / "completions"
        elif mode == InstallationMode.SYSTEM:
            self.bin_dir = Path("/usr/local/bin")
            self.config_dir = Path("/etc/exxede")
            self.data_dir = Path("/usr/local/share/exxede")
            self.man_dir = Path("/usr/local/share/man/man1")
            self.completion_dir = Path("/usr/local/share/bash-completion/completions")
        else:  # PORTABLE
            portable_dir = self.script_dir / "portable"
            self.bin_dir = portable_dir / "bin"
            self.config_dir = portable_dir / "config"
            self.data_dir = portable_dir / "data"
            self.man_dir = portable_dir / "man"
            self.completion_dir = portable_dir / "completions"
        
        # Ensure directories exist
        for directory in [self.bin_dir, self.config_dir, self.data_dir, self.man_dir, self.completion_dir]:
            directory.mkdir(parents=True, exist_ok=True)
    
    def _detect_platform(self) -> Platform:
        """Detect the current platform."""
        system = platform.system().lower()
        if system == "linux":
            return Platform.LINUX
        elif system == "darwin":
            return Platform.MACOS
        elif system == "windows":
            return Platform.WINDOWS
        else:
            raise OSError(f"Unsupported platform: {system}")
    
    def install_main_binary(self) -> bool:
        """Install the main exxede-agents binary."""
        print("🔧 Installing main exxede-agents binary...")
        
        # Create the main executable script
        main_script = self._create_main_executable()
        binary_path = self.bin_dir / "exxede-agents"
        
        # Write and make executable
        with open(binary_path, 'w') as f:
            f.write(main_script)
        
        binary_path.chmod(0o755)
        
        # Create convenient aliases
        aliases = ["exxede", "agents", "xa"]  # xa = eXxede Agents
        for alias in aliases:
            alias_path = self.bin_dir / alias
            if not alias_path.exists():
                if self.platform == Platform.WINDOWS:
                    # Create batch file for Windows
                    with open(f"{alias_path}.bat", 'w') as f:
                        f.write(f'@echo off\n"{binary_path}" %*\n')
                else:
                    # Create symlink for Unix-like systems
                    alias_path.symlink_to(binary_path)
        
        print(f"✅ Installed main binary at: {binary_path}")
        return True
    
    def _create_main_executable(self) -> str:
        """Create the main executable script."""
        return f'''#!/usr/bin/env python3
"""
Exxede Agent System - Global Binary
Enterprise-grade AI agent management platform
"""

import sys
import os
from pathlib import Path

# Add the core modules to Python path
EXXEDE_HOME = Path("{self.script_dir}")
sys.path.insert(0, str(EXXEDE_HOME))

try:
    from core.installer.agent_installer import main as installer_main
    from core.orchestrator.multi_model_orchestrator import MultiModelOrchestrator
    from core.orchestrator.parallel_agent_manager import ParallelAgentManager
except ImportError as e:
    print(f"❌ Error importing Exxede modules: {{e}}")
    print(f"💡 Try running from the Exxede directory: {EXXEDE_HOME}")
    sys.exit(1)

def main():
    """Main entry point for exxede-agents command."""
    import argparse
    
    parser = argparse.ArgumentParser(
        prog="exxede-agents",
        description="Exxede Agent System - Enterprise AI Management Platform",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  exxede-agents status                    # Show system status
  exxede-agents install ARQ              # Install specific agent
  exxede-agents list --json             # List agents in JSON format
  exxede-agents create                   # Create new project
  exxede-agents parallel "design app"   # Run parallel agents
  exxede-agents validate                # System validation
  
For more information, visit: https://github.com/exxede/agent-system
        """
    )
    
    parser.add_argument("--version", action="version", version="Exxede Agent System v2.0.0")
    
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Status command
    status_parser = subparsers.add_parser("status", help="Show system status")
    
    # Install command  
    install_parser = subparsers.add_parser("install", help="Install specific agent")
    install_parser.add_argument("agent", nargs="?", help="Agent name to install")
    install_parser.add_argument("--all", action="store_true", help="Install all agents")
    
    # List command
    list_parser = subparsers.add_parser("list", help="List available agents")
    list_parser.add_argument("--json", action="store_true", help="Output as JSON")
    list_parser.add_argument("--category", choices=["elite", "specialized"], help="Filter by category")
    
    # Create command
    create_parser = subparsers.add_parser("create", help="Create new project")
    create_parser.add_argument("--name", help="Project name")
    
    # Parallel command
    parallel_parser = subparsers.add_parser("parallel", help="Run parallel agents")
    parallel_parser.add_argument("task", help="Task description")
    parallel_parser.add_argument("--agents", nargs="+", help="Specific agents to use")
    parallel_parser.add_argument("--max-concurrent", type=int, default=4, help="Max concurrent tasks")
    
    # Validate command
    validate_parser = subparsers.add_parser("validate", help="Run system validation")
    
    # Test command
    test_parser = subparsers.add_parser("test", help="Run system tests")
    
    args = parser.parse_args()
    
    # Handle commands
    if args.command == "status":
        show_system_status()
    elif args.command == "install":
        handle_install(args)
    elif args.command == "list":
        handle_list(args)
    elif args.command == "create":
        handle_create(args)
    elif args.command == "parallel":
        handle_parallel(args)
    elif args.command == "validate":
        handle_validate()
    elif args.command == "test":
        handle_test()
    else:
        # Default behavior - delegate to original installer
        installer_main()

def show_system_status():
    """Show comprehensive system status."""
    print("🌟 Exxede Agent System Status")
    print("=" * 50)
    
    # Check system health
    health_score = 0
    total_checks = 0
    
    # Check Python version
    python_version = sys.version_info
    total_checks += 1
    if python_version >= (3, 8):
        print(f"✅ Python {python_version.major}.{python_version.minor}.{python_version.micro}")
        health_score += 1
    else:
        print(f"❌ Python {python_version.major}.{python_version.minor}.{python_version.micro} (3.8+ required)")
    
    # Check core modules
    core_modules = ["yaml", "json", "pathlib", "asyncio"]
    for module in core_modules:
        total_checks += 1
        try:
            __import__(module)
            print(f"✅ Module: {module}")
            health_score += 1
        except ImportError:
            print(f"❌ Module: {module} (missing)")
    
    # Check agent files
    agents_dir = Path("{self.script_dir}") / "agents"
    elite_agents = len(list((agents_dir / "elite").glob("*.md"))) if (agents_dir / "elite").exists() else 0
    specialized_agents = len(list((agents_dir / "specialized").glob("*.md"))) if (agents_dir / "specialized").exists() else 0
    
    total_checks += 2
    if elite_agents >= 8:
        print(f"✅ Elite agents: {elite_agents}/8")
        health_score += 1
    else:
        print(f"❌ Elite agents: {elite_agents}/8")
    
    if specialized_agents >= 9:
        print(f"✅ Specialized agents: {specialized_agents}/9")
        health_score += 1
    else:
        print(f"❌ Specialized agents: {specialized_agents}/9")
    
    # Overall health
    health_percentage = (health_score / total_checks) * 100
    print(f"\\n📊 System Health: {health_percentage:.1f}% ({health_score}/{total_checks})")
    
    if health_percentage >= 90:
        print("🎉 System is operating at optimal performance!")
    elif health_percentage >= 70:
        print("⚠️  System is functional but may need attention")
    else:
        print("🚨 System issues detected - run 'exxede-agents validate' for details")

def handle_install(args):
    """Handle install command."""
    if args.all:
        print("📦 Installing all agents...")
    elif args.agent:
        print(f"📦 Installing agent: {args.agent}")
    else:
        print("❌ Please specify an agent to install or use --all")
        return
    
    # Delegate to installer
    installer_main()

def handle_list(args):
    """Handle list command."""
    agents_dir = Path("{self.script_dir}") / "agents"
    
    elite_agents = []
    specialized_agents = []
    
    # Scan elite agents
    elite_dir = agents_dir / "elite"
    if elite_dir.exists():
        for agent_file in elite_dir.glob("*.md"):
            elite_agents.append(agent_file.stem.upper())
    
    # Scan specialized agents
    specialized_dir = agents_dir / "specialized"
    if specialized_dir.exists():
        for agent_file in specialized_dir.glob("*.md"):
            specialized_agents.append(agent_file.stem.replace("-", " ").title())
    
    if args.json:
        data = {
            "elite": elite_agents,
            "specialized": specialized_agents,
            "total": len(elite_agents) + len(specialized_agents)
        }
        print(json.dumps(data, indent=2))
    else:
        print("🤖 Exxede Agent System - Available Agents")
        print("=" * 50)
        
        if not args.category or args.category == "elite":
            print(f"\\n🌟 Elite Agents ({len(elite_agents)}):")
            for agent in sorted(elite_agents):
                print(f"  • {agent}")
        
        if not args.category or args.category == "specialized":
            print(f"\\n🎯 Specialized Agents ({len(specialized_agents)}):")
            for agent in sorted(specialized_agents):
                print(f"  • {agent}")
        
        print(f"\\n📊 Total: {len(elite_agents) + len(specialized_agents)} agents available")

def handle_create(args):
    """Handle create command."""
    project_name = args.name or os.path.basename(os.getcwd())
    print(f"🏗️  Creating Exxede project: {project_name}")
    
    # Delegate to project creator
    try:
        from core.installer.create_elite_project import main as create_main
        create_main()
    except ImportError:
        print("❌ Project creator not found")

def handle_parallel(args):
    """Handle parallel execution command."""
    print(f"🚀 Executing parallel agents for: {args.task}")
    print(f"📊 Max concurrent: {args.max_concurrent}")
    
    if args.agents:
        print(f"🤖 Using agents: {', '.join(args.agents)}")
    else:
        print("🎯 Auto-selecting optimal agents...")
    
    # Note: This would integrate with the ParallelAgentManager
    print("⚠️  Parallel execution requires async runtime - use Python API")

def handle_validate():
    """Handle system validation."""
    print("🔍 Running comprehensive system validation...")
    
    try:
        from core.testing.system_validator import main as validate_main
        validate_main()
    except ImportError:
        print("❌ System validator not found")

def handle_test():
    """Handle system testing."""
    print("🧪 Running system tests...")
    
    try:
        from core.testing.test_all_agents import main as test_main
        test_main()
    except ImportError:
        print("❌ Test suite not found")

if __name__ == "__main__":
    main()
'''
    
    def install_shell_completion(self) -> bool:
        """Install shell completion for bash and zsh."""
        print("🔧 Installing shell completion...")
        
        # Bash completion
        bash_completion = self._create_bash_completion()
        bash_file = self.completion_dir / "exxede-agents"
        
        with open(bash_file, 'w') as f:
            f.write(bash_completion)
        
        # Zsh completion
        if self.platform in [Platform.LINUX, Platform.MACOS]:
            zsh_dir = self.home_dir / ".oh-my-zsh" / "completions"
            if zsh_dir.exists():
                zsh_file = zsh_dir / "_exxede-agents"
                zsh_completion = self._create_zsh_completion()
                with open(zsh_file, 'w') as f:
                    f.write(zsh_completion)
                print("✅ Installed zsh completion")
        
        print(f"✅ Installed bash completion at: {bash_file}")
        return True
    
    def _create_bash_completion(self) -> str:
        """Create bash completion script."""
        return '''#!/bin/bash
# Bash completion for exxede-agents

_exxede_agents_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="status install list create parallel validate test --help --version"
    
    case "${prev}" in
        install)
            local agents="ARQ ZEN VEX SAGE NOVA ECHO ORC APEX strategic-business-analyst fullstack-dev-agent dominican-market-specialist devops-automation-agent digital-marketing-agent investment-research-agent market-research-agent product-strategy-agent qa-testing-agent content-creation-agent"
            COMPREPLY=( $(compgen -W "${agents}" -- ${cur}) )
            return 0
            ;;
        list)
            COMPREPLY=( $(compgen -W "--json --category" -- ${cur}) )
            return 0
            ;;
        --category)
            COMPREPLY=( $(compgen -W "elite specialized" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _exxede_agents_completion exxede-agents
complete -F _exxede_agents_completion exxede
complete -F _exxede_agents_completion agents
complete -F _exxede_agents_completion xa
'''
    
    def _create_zsh_completion(self) -> str:
        """Create zsh completion script."""
        return '''#compdef exxede-agents exxede agents xa

_exxede_agents() {
    local context state line
    typeset -A opt_args

    _arguments -C \
        '1: :->commands' \
        '*: :->args' \
        && return 0

    case $state in
        commands)
            local commands=(
                'status:Show system status'
                'install:Install specific agent'
                'list:List available agents'
                'create:Create new project'
                'parallel:Run parallel agents'
                'validate:Run system validation'
                'test:Run system tests'
                '--help:Show help message'
                '--version:Show version'
            )
            _describe 'command' commands
            ;;
        args)
            case $words[2] in
                install)
                    local agents=(
                        'ARQ:Visionary Architect'
                        'ZEN:Code Zen Master'
                        'VEX:Creative Visionary'
                        'SAGE:Strategic Oracle'
                        'NOVA:Innovation Catalyst'
                        'ECHO:Voice of the People'
                        'ORC:Master Orchestrator'
                        'APEX:Peak Performance'
                        'strategic-business-analyst:Strategic Business Analyst'
                        'fullstack-dev-agent:Full-Stack Developer'
                        'dominican-market-specialist:Dominican Market Specialist'
                    )
                    _describe 'agent' agents
                    ;;
                list)
                    _arguments \
                        '--json[Output as JSON]' \
                        '--category[Filter by category]:category:(elite specialized)'
                    ;;
                parallel)
                    _arguments \
                        '--agents[Specific agents]:agents:' \
                        '--max-concurrent[Max concurrent tasks]:number:'
                    ;;
            esac
            ;;
    esac
}

_exxede_agents "$@"
'''
    
    def install_man_pages(self) -> bool:
        """Install man pages for the system."""
        print("📖 Installing man pages...")
        
        # Main man page
        main_man = self._create_main_man_page()
        man_file = self.man_dir / "exxede-agents.1"
        
        with open(man_file, 'w') as f:
            f.write(main_man)
        
        # Create aliases for man pages
        aliases = ["exxede.1", "agents.1", "xa.1"]
        for alias in aliases:
            alias_path = self.man_dir / alias
            if not alias_path.exists():
                alias_path.symlink_to(man_file)
        
        print(f"✅ Installed man page at: {man_file}")
        return True
    
    def _create_main_man_page(self) -> str:
        """Create the main man page."""
        return '''.TH EXXEDE-AGENTS 1 "2024" "Exxede Agent System v2.0.0" "User Commands"
.SH NAME
exxede-agents \\- Enterprise-grade AI agent management platform
.SH SYNOPSIS
.B exxede-agents
.I COMMAND
.RI [ OPTIONS ]
.SH DESCRIPTION
.B exxede-agents
is an enterprise-grade AI agent management platform designed for the Exxede Group companies. It provides intelligent multi-model orchestration, cost optimization, and parallel processing capabilities for AI-powered development workflows.

The system includes elite AI personalities and specialized domain agents optimized for Caribbean and Latin American markets, with deep focus on Dominican Republic business culture and requirements.

.SH COMMANDS
.TP
.B status
Show comprehensive system status including health metrics and agent availability.

.TP
.B install [AGENT]
Install a specific agent or use --all to install all available agents.

.TP
.B list [--json] [--category CATEGORY]
List available agents. Use --json for structured output or --category to filter by elite/specialized agents.

.TP
.B create [--name NAME]
Create a new Exxede project with optimal agent selection and configuration.

.TP
.B parallel TASK [--agents AGENTS] [--max-concurrent N]
Execute multiple agents in parallel for a given task description.

.TP
.B validate
Run comprehensive system validation and health checks.

.TP
.B test
Execute the full test suite for system validation.

.SH ELITE AGENTS
.TP
.B ARQ
Visionary Architect - System design, strategic architecture, scalability
.TP
.B ZEN
Code Zen Master - Clean code, algorithms, refactoring, performance
.TP
.B VEX
Creative Visionary - UI/UX design, design systems, user psychology
.TP
.B SAGE
Strategic Oracle - Market analysis, strategic planning, competitive intelligence
.TP
.B NOVA
Innovation Catalyst - Breakthrough innovation, emerging tech, R&D
.TP
.B ECHO
Voice of the People - Community building, content strategy, cultural intelligence
.TP
.B ORC
Master Orchestrator - Workflow automation, project coordination
.TP
.B APEX
Peak Performance - Excellence optimization, mastery development

.SH SPECIALIZED AGENTS
The system includes 9+ specialized agents for domain-specific expertise including full-stack development, DevOps automation, digital marketing, investment research, QA testing, content creation, product strategy, market research, and Dominican Republic market intelligence.

.SH CONFIGURATION
Global configuration is stored in:
.TP
.B ~/.config/exxede/config.yaml
Main configuration file
.TP
.B ~/.local/share/exxede/
Data and cache directory
.TP
.B ~/.exxede-agent-config.yaml
Legacy global configuration

.SH EXAMPLES
.TP
Initialize a new project:
.B exxede-agents create --name "fintech-app"

.TP
List all elite agents:
.B exxede-agents list --category elite

.TP
Install specific agent:
.B exxede-agents install ARQ

.TP
Run parallel agents:
.B exxede-agents parallel "design a mobile app for tourism"

.TP
Check system status:
.B exxede-agents status

.SH FILES
.TP
.I ~/.local/bin/exxede-agents
Main executable binary
.TP
.I ~/.config/exxede/
Configuration directory
.TP
.I ~/.local/share/exxede/
Data and cache directory

.SH ENVIRONMENT
.TP
.B EXXEDE_HOME
Override default installation directory
.TP
.B EXXEDE_CONFIG
Override default configuration file location

.SH EXIT STATUS
.TP
.B 0
Success
.TP
.B 1
General error
.TP
.B 2
Invalid command or arguments

.SH BUGS
Report bugs to: https://github.com/exxede/agent-system/issues

.SH AUTHOR
Created by Armando Diaz Silverio for the Exxede Group companies.

.SH SEE ALSO
.BR python3 (1),
.BR git (1),
.BR claude (1)

For complete documentation, visit: https://docs.exxede.dev/agent-system
'''
    
    def create_desktop_entry(self) -> bool:
        """Create desktop entry for GUI applications (Linux)."""
        if self.platform != Platform.LINUX:
            return True
        
        print("🖥️  Creating desktop entry...")
        
        desktop_dir = self.home_dir / ".local" / "share" / "applications"
        desktop_dir.mkdir(parents=True, exist_ok=True)
        
        desktop_content = f'''[Desktop Entry]
Version=1.0
Type=Application
Name=Exxede Agent System
Comment=Enterprise AI Agent Management Platform
Exec={self.bin_dir}/exxede-agents
Icon=utilities-terminal
Terminal=true
Categories=Development;Utility;
Keywords=AI;Agent;Development;Exxede;
StartupNotify=true
'''
        
        desktop_file = desktop_dir / "exxede-agents.desktop"
        with open(desktop_file, 'w') as f:
            f.write(desktop_content)
        
        desktop_file.chmod(0o755)
        print(f"✅ Created desktop entry at: {desktop_file}")
        return True
    
    def update_shell_profile(self) -> bool:
        """Update shell profile with PATH and aliases."""
        print("🔧 Updating shell profile...")
        
        # Detect shell configuration files
        shell_configs = []
        if (self.home_dir / ".bashrc").exists():
            shell_configs.append(self.home_dir / ".bashrc")
        if (self.home_dir / ".zshrc").exists():
            shell_configs.append(self.home_dir / ".zshrc")
        if (self.home_dir / ".profile").exists():
            shell_configs.append(self.home_dir / ".profile")
        
        if not shell_configs:
            # Create .profile as fallback
            shell_configs = [self.home_dir / ".profile"]
        
        for config_file in shell_configs:
            self._update_single_shell_config(config_file)
        
        return True
    
    def _update_single_shell_config(self, config_file: Path) -> None:
        """Update a single shell configuration file."""
        # Read existing content
        content = ""
        if config_file.exists():
            with open(config_file, 'r') as f:
                content = f.read()
        
        # Check if already configured
        if "# Exxede Agent System" in content:
            print(f"⚠️  {config_file.name} already configured")
            return
        
        # Add configuration
        config_addition = f'''

# Exxede Agent System Configuration
export EXXEDE_HOME="{self.script_dir}"
export PATH="{self.bin_dir}:$PATH"

# Exxede Agent Aliases
alias agents='exxede-agents'
alias xa='exxede-agents'
alias exxede='exxede-agents'
alias agents-status='exxede-agents status'
alias agents-list='exxede-agents list'
alias agents-install='exxede-agents install'
alias agents-validate='exxede-agents validate'

# Quick project initialization
alias init-exxede='exxede-agents create'
alias parallel-agents='exxede-agents parallel'

# Exxede development shortcuts
export EXXEDE_CONFIG_DIR="{self.config_dir}"
export EXXEDE_DATA_DIR="{self.data_dir}"
'''
        
        with open(config_file, 'a') as f:
            f.write(config_addition)
        
        print(f"✅ Updated {config_file.name}")
    
    def create_global_config(self) -> bool:
        """Create global system configuration."""
        print("⚙️  Creating global configuration...")
        
        config = {
            "version": "2.0.0",
            "installation": {
                "mode": self.mode.value,
                "platform": self.platform.value,
                "installed_at": str(Path.cwd()),
                "bin_dir": str(self.bin_dir),
                "config_dir": str(self.config_dir),
                "data_dir": str(self.data_dir)
            },
            "system": {
                "max_workers": 8,
                "default_timeout": 300,
                "cost_optimization": True,
                "parallel_processing": True,
                "shared_context": True
            },
            "business_context": {
                "owner": "Armando Diaz Silverio",
                "companies": [
                    {"name": "Exxede Investments", "focus": "Investment and business development"},
                    {"name": "ReppingDR", "focus": "Cultural merchandise and Dominican pride"},
                    {"name": "Prolici", "focus": "Business services and consulting"},
                    {"name": "Exxede.dev", "focus": "Technology development and digital solutions"}
                ],
                "markets": {
                    "primary": "Dominican Republic",
                    "secondary": ["Caribbean", "Latin America", "US Hispanic Market"],
                    "headquarters": "Punta Cana, Dominican Republic"
                },
                "preferences": {
                    "languages": ["English", "Spanish"],
                    "cultural_focus": "Caribbean and Latin American markets",
                    "business_approach": "Relationship-focused, long-term value creation"
                }
            },
            "default_agents": {
                "elite": ["ARQ", "SAGE", "ZEN"],
                "specialized": ["strategic-business-analyst", "dominican-market-specialist"]
            },
            "orchestration": {
                "multi_model": True,
                "cost_optimization": True,
                "parallel_execution": True,
                "shared_context": True,
                "performance_monitoring": True
            }
        }
        
        config_file = self.config_dir / "config.yaml"
        with open(config_file, 'w') as f:
            yaml.dump(config, f, default_flow_style=False, indent=2)
        
        print(f"✅ Created global configuration at: {config_file}")
        return True
    
    def install_dependencies(self) -> bool:
        """Install required dependencies."""
        print("📦 Installing dependencies...")
        
        dependencies = [
            "pyyaml",
            "aiohttp",
            "asyncio",
            "concurrent.futures"
        ]
        
        for dep in dependencies:
            try:
                __import__(dep.replace("-", "_"))
                print(f"✅ {dep} (already installed)")
            except ImportError:
                try:
                    subprocess.run([
                        sys.executable, "-m", "pip", "install", "--user", dep
                    ], check=True, capture_output=True)
                    print(f"✅ {dep} (installed)")
                except subprocess.CalledProcessError:
                    print(f"⚠️  {dep} (failed to install)")
        
        return True
    
    def validate_installation(self) -> bool:
        """Validate the installation."""
        print("🔍 Validating installation...")
        
        checks = [
            ("Main binary", self.bin_dir / "exxede-agents"),
            ("Configuration", self.config_dir / "config.yaml"),
            ("Shell completion", self.completion_dir / "exxede-agents"),
            ("Man page", self.man_dir / "exxede-agents.1")
        ]
        
        all_good = True
        for name, path in checks:
            if path.exists():
                print(f"✅ {name}: {path}")
            else:
                print(f"❌ {name}: {path} (missing)")
                all_good = False
        
        # Test binary execution
        try:
            result = subprocess.run([
                str(self.bin_dir / "exxede-agents"), "--version"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                print("✅ Binary execution test passed")
            else:
                print(f"❌ Binary execution failed: {result.stderr}")
                all_good = False
        except Exception as e:
            print(f"❌ Binary execution test failed: {e}")
            all_good = False
        
        return all_good
    
    def full_install(self) -> bool:
        """Perform complete installation."""
        print("🚀 Starting Exxede Agent System Global Installation")
        print("=" * 60)
        print(f"Mode: {self.mode.value}")
        print(f"Platform: {self.platform.value}")
        print(f"Target directory: {self.bin_dir}")
        print()
        
        steps = [
            ("Installing main binary", self.install_main_binary),
            ("Installing shell completion", self.install_shell_completion),
            ("Installing man pages", self.install_man_pages),
            ("Creating desktop entry", self.create_desktop_entry),
            ("Updating shell profile", self.update_shell_profile),
            ("Creating global config", self.create_global_config),
            ("Installing dependencies", self.install_dependencies),
            ("Validating installation", self.validate_installation)
        ]
        
        success_count = 0
        for step_name, step_func in steps:
            try:
                if step_func():
                    success_count += 1
                else:
                    print(f"❌ {step_name} failed")
            except Exception as e:
                print(f"❌ {step_name} failed: {e}")
        
        print()
        print("📊 Installation Summary")
        print(f"Completed: {success_count}/{len(steps)} steps")
        
        if success_count == len(steps):
            print("🎉 Installation completed successfully!")
            print()
            print("🔄 Next steps:")
            print("1. Restart your terminal or run: source ~/.bashrc")
            print("2. Try: exxede-agents status")
            print("3. Create a project: exxede-agents create")
            print("4. Read the docs: man exxede-agents")
            return True
        else:
            print("⚠️  Installation completed with issues")
            print("Run the installer again or check the documentation")
            return False
    
    def uninstall(self) -> bool:
        """Uninstall the system."""
        print("🗑️  Uninstalling Exxede Agent System...")
        
        # Remove binaries
        binaries = ["exxede-agents", "exxede", "agents", "xa"]
        for binary in binaries:
            binary_path = self.bin_dir / binary
            if binary_path.exists():
                binary_path.unlink()
                print(f"✅ Removed: {binary_path}")
            
            # Windows batch files
            bat_path = Path(f"{binary_path}.bat")
            if bat_path.exists():
                bat_path.unlink()
                print(f"✅ Removed: {bat_path}")
        
        # Remove completion files
        completion_files = [
            self.completion_dir / "exxede-agents",
            self.home_dir / ".oh-my-zsh" / "completions" / "_exxede-agents"
        ]
        for comp_file in completion_files:
            if comp_file.exists():
                comp_file.unlink()
                print(f"✅ Removed: {comp_file}")
        
        # Remove man pages
        man_pages = ["exxede-agents.1", "exxede.1", "agents.1", "xa.1"]
        for man_page in man_pages:
            man_path = self.man_dir / man_page
            if man_path.exists():
                man_path.unlink()
                print(f"✅ Removed: {man_path}")
        
        # Remove desktop entry
        desktop_file = self.home_dir / ".local" / "share" / "applications" / "exxede-agents.desktop"
        if desktop_file.exists():
            desktop_file.unlink()
            print(f"✅ Removed: {desktop_file}")
        
        # Note: We don't remove shell config modifications automatically
        # as they might contain other user customizations
        print()
        print("⚠️  Note: Shell configuration modifications were not removed")
        print("   You may want to manually remove Exxede lines from:")
        print("   ~/.bashrc, ~/.zshrc, ~/.profile")
        
        print("✅ Uninstallation completed")
        return True


def main():
    """Main entry point for global installer."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Exxede Agent System Global Binary Installer",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        "--mode",
        choices=["user", "system", "portable"],
        default="user",
        help="Installation mode (default: user)"
    )
    
    parser.add_argument(
        "--uninstall",
        action="store_true",
        help="Uninstall the system"
    )
    
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate existing installation"
    )
    
    args = parser.parse_args()
    
    try:
        installer = GlobalBinaryInstaller(InstallationMode(args.mode))
        
        if args.uninstall:
            return installer.uninstall()
        elif args.validate:
            return installer.validate_installation()
        else:
            return installer.full_install()
    
    except KeyboardInterrupt:
        print("\n❌ Installation cancelled by user")
        return False
    except Exception as e:
        print(f"❌ Installation failed: {e}")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)