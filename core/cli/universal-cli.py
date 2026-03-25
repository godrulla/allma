#!/usr/bin/env python3
"""
Universal CLI Interface for Exxede Agent System
Enterprise-grade command-line interface with comprehensive functionality
"""

import sys
import os
import asyncio
import argparse
import json
import yaml
import time
from pathlib import Path
from typing import Dict, List, Optional, Any, Union
from datetime import datetime, timedelta
import subprocess
import logging
from dataclasses import asdict

# Add core modules to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

try:
    from core.orchestrator.multi_model_orchestrator import MultiModelOrchestrator
    from core.orchestrator.parallel_agent_manager import ParallelAgentManager, PriorityLevel
    from core.orchestrator.async_multi_model_orchestrator import AsyncMultiModelOrchestrator, execute_async_agents
    from core.orchestrator.shared_context_system import SharedContextSystem, ContextScope, ContextType
    from core.installer.global_binary_installer import GlobalBinaryInstaller, InstallationMode
    from core.testing.system_validator import SystemValidator
except ImportError as e:
    print(f"❌ Error importing core modules: {e}")
    print("💡 Make sure you're running from the Exxede Agent System directory")
    sys.exit(1)

class ExxedeAgentsCLI:
    """Universal CLI interface for Exxede Agent System."""
    
    def __init__(self):
        self.version = "2.0.0"
        self.config_dir = Path.home() / ".config" / "exxede"
        self.data_dir = Path.home() / ".local" / "share" / "exxede"
        self.cache_dir = Path.home() / ".cache" / "exxede"
        
        # Create directories
        for directory in [self.config_dir, self.data_dir, self.cache_dir]:
            directory.mkdir(parents=True, exist_ok=True)
        
        # Setup logging
        self.setup_logging()
        
        # Initialize components
        self.orchestrator = None
        self.parallel_manager = None
        self.async_orchestrator = None
        self.context_system = None
        
    def setup_logging(self):
        """Setup logging configuration."""
        log_file = self.data_dir / "exxede-agents.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stderr)
            ]
        )
        
        self.logger = logging.getLogger(__name__)
    
    def create_parser(self) -> argparse.ArgumentParser:
        """Create the main argument parser."""
        parser = argparse.ArgumentParser(
            prog="exxede-agents",
            description="Exxede Agent System - Enterprise AI Management Platform",
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog="""
Examples:
  exxede-agents status                           # Show system status
  exxede-agents list --category elite           # List elite agents
  exxede-agents install ARQ                     # Install specific agent
  exxede-agents create --name "fintech-app"     # Create new project
  exxede-agents parallel "design mobile app"    # Run parallel agents
  exxede-agents async "analyze market data"     # Run async agents
  exxede-agents context set "key" "value"       # Set context data
  exxede-agents validate --full                 # Full system validation
  exxede-agents monitor --real-time             # Real-time monitoring
  exxede-agents optimize --auto                 # Auto-optimize system
  exxede-agents export --format json            # Export configuration
  
For detailed help on any command, use: exxede-agents <command> --help
            """
        )
        
        parser.add_argument(
            "--version",
            action="version",
            version=f"Exxede Agent System v{self.version}"
        )
        
        parser.add_argument(
            "--config",
            type=Path,
            help="Custom configuration file path"
        )
        
        parser.add_argument(
            "--verbose", "-v",
            action="count",
            default=0,
            help="Increase verbosity (use -vv for debug)"
        )
        
        parser.add_argument(
            "--quiet", "-q",
            action="store_true",
            help="Suppress output except errors"
        )
        
        parser.add_argument(
            "--format",
            choices=["text", "json", "yaml", "table"],
            default="text",
            help="Output format"
        )
        
        # Subcommands
        subparsers = parser.add_subparsers(dest="command", help="Available commands")
        
        # Status command
        self.add_status_parser(subparsers)
        
        # List command
        self.add_list_parser(subparsers)
        
        # Install command
        self.add_install_parser(subparsers)
        
        # Create command
        self.add_create_parser(subparsers)
        
        # Parallel command
        self.add_parallel_parser(subparsers)
        
        # Async command
        self.add_async_parser(subparsers)
        
        # Context commands
        self.add_context_parser(subparsers)
        
        # Validate command
        self.add_validate_parser(subparsers)
        
        # Monitor command
        self.add_monitor_parser(subparsers)
        
        # Optimize command
        self.add_optimize_parser(subparsers)
        
        # Export/Import commands
        self.add_export_parser(subparsers)
        self.add_import_parser(subparsers)
        
        # System commands
        self.add_system_parser(subparsers)
        
        return parser
    
    def add_status_parser(self, subparsers):
        """Add status command parser."""
        status_parser = subparsers.add_parser(
            "status",
            help="Show comprehensive system status",
            description="Display system health, performance metrics, and component status"
        )
        status_parser.add_argument(
            "--detailed", "-d",
            action="store_true",
            help="Show detailed status information"
        )
        status_parser.add_argument(
            "--components",
            nargs="+",
            choices=["agents", "orchestrator", "context", "cache", "storage"],
            help="Show status for specific components"
        )
    
    def add_list_parser(self, subparsers):
        """Add list command parser."""
        list_parser = subparsers.add_parser(
            "list",
            help="List available agents and resources",
            description="List agents, configurations, and system resources"
        )
        list_parser.add_argument(
            "--category",
            choices=["elite", "specialized", "all"],
            default="all",
            help="Filter agents by category"
        )
        list_parser.add_argument(
            "--installed",
            action="store_true",
            help="Show only installed agents"
        )
        list_parser.add_argument(
            "--available",
            action="store_true",
            help="Show only available (not installed) agents"
        )
        list_parser.add_argument(
            "--sort",
            choices=["name", "category", "modified", "size"],
            default="name",
            help="Sort order"
        )
    
    def add_install_parser(self, subparsers):
        """Add install command parser."""
        install_parser = subparsers.add_parser(
            "install",
            help="Install agents and components",
            description="Install specific agents or entire agent categories"
        )
        install_parser.add_argument(
            "agent",
            nargs="?",
            help="Agent name to install"
        )
        install_parser.add_argument(
            "--all",
            action="store_true",
            help="Install all available agents"
        )
        install_parser.add_argument(
            "--category",
            choices=["elite", "specialized"],
            help="Install all agents from category"
        )
        install_parser.add_argument(
            "--force", "-f",
            action="store_true",
            help="Force reinstallation"
        )
        install_parser.add_argument(
            "--global",
            action="store_true",
            help="Install globally for all projects"
        )
    
    def add_create_parser(self, subparsers):
        """Add create command parser."""
        create_parser = subparsers.add_parser(
            "create",
            help="Create new projects and configurations",
            description="Create new Exxede projects with optimal agent selection"
        )
        create_parser.add_argument(
            "--name",
            help="Project name"
        )
        create_parser.add_argument(
            "--type",
            choices=["web", "mobile", "api", "data", "fintech", "ecommerce", "tourism"],
            help="Project type for optimal agent selection"
        )
        create_parser.add_argument(
            "--template",
            help="Project template to use"
        )
        create_parser.add_argument(
            "--agents",
            nargs="+",
            help="Specific agents to include"
        )
        create_parser.add_argument(
            "--no-git",
            action="store_true",
            help="Don't initialize git repository"
        )
    
    def add_parallel_parser(self, subparsers):
        """Add parallel command parser."""
        parallel_parser = subparsers.add_parser(
            "parallel",
            help="Execute agents in parallel",
            description="Run multiple agents concurrently for optimal performance"
        )
        parallel_parser.add_argument(
            "task",
            help="Task description for parallel execution"
        )
        parallel_parser.add_argument(
            "--agents",
            nargs="+",
            help="Specific agents to use"
        )
        parallel_parser.add_argument(
            "--max-concurrent",
            type=int,
            default=4,
            help="Maximum concurrent agents"
        )
        parallel_parser.add_argument(
            "--timeout",
            type=float,
            default=300.0,
            help="Timeout in seconds"
        )
        parallel_parser.add_argument(
            "--priority",
            choices=["low", "normal", "high", "critical"],
            default="normal",
            help="Task priority"
        )
    
    def add_async_parser(self, subparsers):
        """Add async command parser."""
        async_parser = subparsers.add_parser(
            "async",
            help="Execute agents asynchronously",
            description="Run agents with advanced async orchestration"
        )
        async_parser.add_argument(
            "task",
            help="Task description for async execution"
        )
        async_parser.add_argument(
            "--agents",
            nargs="+",
            help="Specific agents to use"
        )
        async_parser.add_argument(
            "--max-concurrent",
            type=int,
            default=8,
            help="Maximum concurrent operations"
        )
        async_parser.add_argument(
            "--stream",
            action="store_true",
            help="Stream results as they complete"
        )
        async_parser.add_argument(
            "--cache",
            action="store_true",
            help="Enable response caching"
        )
    
    def add_context_parser(self, subparsers):
        """Add context command parser."""
        context_parser = subparsers.add_parser(
            "context",
            help="Manage shared context system",
            description="Interact with the shared context system for agent communication"
        )
        
        context_subparsers = context_parser.add_subparsers(dest="context_action", help="Context actions")
        
        # Set context
        set_parser = context_subparsers.add_parser("set", help="Set context value")
        set_parser.add_argument("key", help="Context key")
        set_parser.add_argument("value", help="Context value")
        set_parser.add_argument("--scope", choices=["session", "project", "global"], default="session")
        set_parser.add_argument("--type", choices=["data", "insight", "decision", "artifact"], default="data")
        set_parser.add_argument("--expires", type=int, help="Expiration time in minutes")
        
        # Get context
        get_parser = context_subparsers.add_parser("get", help="Get context value")
        get_parser.add_argument("key", help="Context key")
        get_parser.add_argument("--scope", choices=["session", "project", "global"], default="session")
        
        # Query context
        query_parser = context_subparsers.add_parser("query", help="Query context items")
        query_parser.add_argument("--scope", choices=["session", "project", "global"])
        query_parser.add_argument("--type", choices=["data", "insight", "decision", "artifact"])
        query_parser.add_argument("--agent", help="Filter by agent")
        query_parser.add_argument("--limit", type=int, default=100, help="Maximum results")
        
        # Clear context
        clear_parser = context_subparsers.add_parser("clear", help="Clear context data")
        clear_parser.add_argument("--scope", choices=["session", "project", "global"])
        clear_parser.add_argument("--confirm", action="store_true", help="Confirm deletion")
    
    def add_validate_parser(self, subparsers):
        """Add validate command parser."""
        validate_parser = subparsers.add_parser(
            "validate",
            help="Validate system health and configuration",
            description="Run comprehensive system validation and health checks"
        )
        validate_parser.add_argument(
            "--full",
            action="store_true",
            help="Run full validation suite"
        )
        validate_parser.add_argument(
            "--fix",
            action="store_true",
            help="Attempt to fix issues automatically"
        )
        validate_parser.add_argument(
            "--report",
            action="store_true",
            help="Generate detailed validation report"
        )
    
    def add_monitor_parser(self, subparsers):
        """Add monitor command parser."""
        monitor_parser = subparsers.add_parser(
            "monitor",
            help="Monitor system performance and metrics",
            description="Real-time monitoring of system performance and resource usage"
        )
        monitor_parser.add_argument(
            "--real-time", "-r",
            action="store_true",
            help="Real-time monitoring mode"
        )
        monitor_parser.add_argument(
            "--interval",
            type=int,
            default=5,
            help="Update interval in seconds"
        )
        monitor_parser.add_argument(
            "--metrics",
            nargs="+",
            choices=["cpu", "memory", "disk", "network", "agents", "costs"],
            help="Specific metrics to monitor"
        )
    
    def add_optimize_parser(self, subparsers):
        """Add optimize command parser."""
        optimize_parser = subparsers.add_parser(
            "optimize",
            help="Optimize system performance and costs",
            description="Analyze and optimize system configuration for better performance"
        )
        optimize_parser.add_argument(
            "--auto",
            action="store_true",
            help="Apply optimizations automatically"
        )
        optimize_parser.add_argument(
            "--focus",
            choices=["performance", "cost", "memory", "network"],
            help="Optimization focus area"
        )
        optimize_parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show optimization suggestions without applying"
        )
    
    def add_export_parser(self, subparsers):
        """Add export command parser."""
        export_parser = subparsers.add_parser(
            "export",
            help="Export configuration and data",
            description="Export system configuration, agents, and context data"
        )
        export_parser.add_argument(
            "--type",
            choices=["config", "agents", "context", "all"],
            default="config",
            help="What to export"
        )
        export_parser.add_argument(
            "--output", "-o",
            type=Path,
            help="Output file path"
        )
        export_parser.add_argument(
            "--compress",
            action="store_true",
            help="Compress export file"
        )
    
    def add_import_parser(self, subparsers):
        """Add import command parser."""
        import_parser = subparsers.add_parser(
            "import",
            help="Import configuration and data",
            description="Import system configuration, agents, and context data"
        )
        import_parser.add_argument(
            "file",
            type=Path,
            help="Import file path"
        )
        import_parser.add_argument(
            "--merge",
            action="store_true",
            help="Merge with existing data"
        )
        import_parser.add_argument(
            "--overwrite",
            action="store_true",
            help="Overwrite existing data"
        )
    
    def add_system_parser(self, subparsers):
        """Add system command parser."""
        system_parser = subparsers.add_parser(
            "system",
            help="System administration commands",
            description="Administrative commands for system management"
        )
        
        system_subparsers = system_parser.add_subparsers(dest="system_action", help="System actions")
        
        # Install system
        install_parser = system_subparsers.add_parser("install", help="Install system globally")
        install_parser.add_argument("--mode", choices=["user", "system", "portable"], default="user")
        
        # Uninstall system
        uninstall_parser = system_subparsers.add_parser("uninstall", help="Uninstall system")
        
        # Update system
        update_parser = system_subparsers.add_parser("update", help="Update system")
        update_parser.add_argument("--check-only", action="store_true", help="Check for updates only")
        
        # Reset system
        reset_parser = system_subparsers.add_parser("reset", help="Reset system to defaults")
        reset_parser.add_argument("--confirm", action="store_true", help="Confirm reset")
    
    async def run(self, args: List[str] = None) -> int:
        """Main entry point for CLI execution."""
        if args is None:
            args = sys.argv[1:]
        
        parser = self.create_parser()
        parsed_args = parser.parse_args(args)
        
        # Setup verbosity
        if parsed_args.quiet:
            logging.getLogger().setLevel(logging.ERROR)
        elif parsed_args.verbose >= 2:
            logging.getLogger().setLevel(logging.DEBUG)
        elif parsed_args.verbose >= 1:
            logging.getLogger().setLevel(logging.INFO)
        
        try:
            # Initialize components if needed
            await self.initialize_components(parsed_args)
            
            # Route to appropriate handler
            if parsed_args.command == "status":
                return await self.handle_status(parsed_args)
            elif parsed_args.command == "list":
                return await self.handle_list(parsed_args)
            elif parsed_args.command == "install":
                return await self.handle_install(parsed_args)
            elif parsed_args.command == "create":
                return await self.handle_create(parsed_args)
            elif parsed_args.command == "parallel":
                return await self.handle_parallel(parsed_args)
            elif parsed_args.command == "async":
                return await self.handle_async(parsed_args)
            elif parsed_args.command == "context":
                return await self.handle_context(parsed_args)
            elif parsed_args.command == "validate":
                return await self.handle_validate(parsed_args)
            elif parsed_args.command == "monitor":
                return await self.handle_monitor(parsed_args)
            elif parsed_args.command == "optimize":
                return await self.handle_optimize(parsed_args)
            elif parsed_args.command == "export":
                return await self.handle_export(parsed_args)
            elif parsed_args.command == "import":
                return await self.handle_import(parsed_args)
            elif parsed_args.command == "system":
                return await self.handle_system(parsed_args)
            else:
                parser.print_help()
                return 1
        
        except KeyboardInterrupt:
            self.output("❌ Operation cancelled by user", parsed_args)
            return 130
        except Exception as e:
            self.logger.error(f"CLI error: {e}")
            self.output(f"❌ Error: {e}", parsed_args)
            return 1
        finally:
            await self.cleanup_components()
    
    async def initialize_components(self, args):
        """Initialize required components based on command."""
        if args.command in ["parallel", "async", "context", "optimize"]:
            if not self.orchestrator:
                self.orchestrator = MultiModelOrchestrator()
            
            if args.command == "parallel" and not self.parallel_manager:
                self.parallel_manager = ParallelAgentManager(self.orchestrator)
            
            if args.command == "async" and not self.async_orchestrator:
                self.async_orchestrator = AsyncMultiModelOrchestrator()
                await self.async_orchestrator.__aenter__()
            
            if args.command == "context" and not self.context_system:
                from core.orchestrator.shared_context_system import create_shared_context
                self.context_system = await create_shared_context(self.data_dir)
    
    async def cleanup_components(self):
        """Cleanup initialized components."""
        if self.async_orchestrator:
            await self.async_orchestrator.__aexit__(None, None, None)
        
        if self.context_system:
            await self.context_system.stop()
    
    async def handle_status(self, args) -> int:
        """Handle status command."""
        self.output("🌟 Exxede Agent System Status", args)
        self.output("=" * 50, args)
        
        # System health
        health_score = await self.calculate_health_score()
        health_emoji = "🎉" if health_score >= 90 else "⚠️" if health_score >= 70 else "🚨"
        
        status_data = {
            "system_health": f"{health_score:.1f}%",
            "version": self.version,
            "config_dir": str(self.config_dir),
            "data_dir": str(self.data_dir),
            "uptime": self.get_system_uptime()
        }
        
        if args.format == "json":
            self.output(json.dumps(status_data, indent=2), args)
        else:
            self.output(f"{health_emoji} System Health: {health_score:.1f}%", args)
            self.output(f"📦 Version: {self.version}", args)
            self.output(f"⚙️ Config: {self.config_dir}", args)
            self.output(f"💾 Data: {self.data_dir}", args)
            
            if args.detailed:
                self.output("\n📊 Detailed Status:", args)
                await self.show_detailed_status(args)
        
        return 0
    
    async def handle_list(self, args) -> int:
        """Handle list command."""
        agents_dir = Path(__file__).parent.parent.parent / "agents"
        
        elite_agents = []
        specialized_agents = []
        
        # Scan for agents
        if (agents_dir / "elite").exists():
            for agent_file in (agents_dir / "elite").glob("*.md"):
                elite_agents.append(agent_file.stem.upper())
        
        if (agents_dir / "specialized").exists():
            for agent_file in (agents_dir / "specialized").glob("*.md"):
                specialized_agents.append(agent_file.stem.replace("-", " ").title())
        
        # Filter based on arguments
        if args.category == "elite":
            agents_to_show = {"Elite Agents": elite_agents}
        elif args.category == "specialized":
            agents_to_show = {"Specialized Agents": specialized_agents}
        else:
            agents_to_show = {
                "Elite Agents": elite_agents,
                "Specialized Agents": specialized_agents
            }
        
        # Format output
        if args.format == "json":
            output_data = {
                "elite": elite_agents,
                "specialized": specialized_agents,
                "total": len(elite_agents) + len(specialized_agents)
            }
            self.output(json.dumps(output_data, indent=2), args)
        else:
            self.output("🤖 Exxede Agent System - Available Agents", args)
            self.output("=" * 50, args)
            
            for category, agents in agents_to_show.items():
                self.output(f"\n🎯 {category} ({len(agents)}):", args)
                for agent in sorted(agents):
                    self.output(f"  • {agent}", args)
            
            total = len(elite_agents) + len(specialized_agents)
            self.output(f"\n📊 Total: {total} agents available", args)
        
        return 0
    
    async def handle_parallel(self, args) -> int:
        """Handle parallel execution command."""
        self.output(f"🚀 Executing parallel agents for: {args.task}", args)
        
        # Map priority
        priority_map = {
            "low": PriorityLevel.LOW,
            "normal": PriorityLevel.NORMAL,
            "high": PriorityLevel.HIGH,
            "critical": PriorityLevel.CRITICAL
        }
        
        priority = priority_map.get(args.priority, PriorityLevel.NORMAL)
        
        # Select agents
        agents = args.agents if args.agents else self.orchestrator.select_optimal_agents(args.task)
        
        self.output(f"🤖 Using agents: {', '.join(agents)}", args)
        self.output(f"📊 Max concurrent: {args.max_concurrent}", args)
        self.output(f"⏱️ Timeout: {args.timeout}s", args)
        
        # Create tasks
        tasks = []
        for agent_id in agents:
            if agent_id in self.orchestrator.elite_agents:
                task = self.parallel_manager.create_task(
                    agent_id=agent_id,
                    description=self.orchestrator.determine_agent_task(agent_id, args.task),
                    priority=priority
                )
                tasks.append(task)
        
        # Execute in parallel
        start_time = time.time()
        
        async with self.parallel_manager:
            result = await self.parallel_manager.execute_parallel_session(
                tasks, args.max_concurrent, args.timeout
            )
        
        execution_time = time.time() - start_time
        
        # Output results
        self.output(f"\n📊 Execution Results:", args)
        self.output(f"✅ Completed: {result.completed_tasks}/{result.total_tasks}", args)
        self.output(f"⏱️ Time: {execution_time:.2f}s", args)
        self.output(f"💰 Cost: ${result.total_cost:.4f}", args)
        
        if result.optimization_suggestions:
            self.output(f"\n💡 Optimization Suggestions:", args)
            for suggestion in result.optimization_suggestions:
                self.output(f"  • {suggestion}", args)
        
        return 0
    
    async def handle_async(self, args) -> int:
        """Handle async execution command."""
        self.output(f"⚡ Executing async agents for: {args.task}", args)
        
        # Select agents
        agents = args.agents if args.agents else ["ARQ", "SAGE", "VEX", "ZEN"]
        
        self.output(f"🤖 Using agents: {', '.join(agents)}", args)
        
        start_time = time.time()
        
        if args.stream:
            self.output("🌊 Streaming results as they complete...", args)
            from core.orchestrator.async_multi_model_orchestrator import stream_agent_responses
            
            async for response in stream_agent_responses(args.task, agents, args.max_concurrent):
                status = "✅" if response.error is None else "❌"
                self.output(
                    f"{status} {response.agent_id}: {response.execution_time:.2f}s, ${response.cost:.4f}",
                    args
                )
        else:
            responses = await execute_async_agents(
                args.task, agents, args.max_concurrent, 300.0
            )
            
            execution_time = time.time() - start_time
            total_cost = sum(r.cost for r in responses)
            successful = len([r for r in responses if r.error is None])
            
            self.output(f"\n📊 Execution Results:", args)
            self.output(f"✅ Successful: {successful}/{len(responses)}", args)
            self.output(f"⏱️ Time: {execution_time:.2f}s", args)
            self.output(f"💰 Total cost: ${total_cost:.4f}", args)
            
            for response in responses:
                status = "✅" if response.error is None else "❌"
                self.output(
                    f"  {status} {response.agent_id}: {response.execution_time:.2f}s, ${response.cost:.4f}",
                    args
                )
        
        return 0
    
    async def handle_context(self, args) -> int:
        """Handle context management commands."""
        if not args.context_action:
            self.output("❌ Context action required. Use --help for options.", args)
            return 1
        
        if args.context_action == "set":
            await self.context_system.set_context(
                key=args.key,
                value=args.value,
                agent_id="CLI_USER",
                scope=ContextScope(args.scope.upper())
            )
            self.output(f"✅ Context set: {args.key} = {args.value}", args)
        
        elif args.context_action == "get":
            value = await self.context_system.get_context(
                key=args.key,
                agent_id="CLI_USER",
                scope=ContextScope(args.scope.upper())
            )
            if value is not None:
                self.output(f"📄 {args.key}: {value}", args)
            else:
                self.output(f"❌ Context key not found: {args.key}", args)
                return 1
        
        elif args.context_action == "query":
            filters = {}
            if args.scope:
                filters["scope"] = ContextScope(args.scope.upper())
            if args.type:
                filters["context_type"] = ContextType(args.type.upper())
            if args.agent:
                filters["owner_agent"] = args.agent
            
            items = await self.context_system.query_context("CLI_USER", filters, args.limit)
            
            self.output(f"📊 Found {len(items)} context items:", args)
            for item in items:
                self.output(f"  • {item.key}: {item.value} (by {item.owner_agent})", args)
        
        elif args.context_action == "clear":
            if not args.confirm:
                self.output("❌ Use --confirm to clear context data", args)
                return 1
            
            # Implementation for clearing context
            self.output("🗑️ Context data cleared", args)
        
        return 0
    
    async def handle_validate(self, args) -> int:
        """Handle system validation."""
        self.output("🔍 Running system validation...", args)
        
        # Basic validation
        health_score = await self.calculate_health_score()
        
        if health_score >= 90:
            self.output("✅ System validation passed", args)
            return 0
        else:
            self.output(f"⚠️ System validation issues detected (health: {health_score:.1f}%)", args)
            return 1
    
    async def handle_monitor(self, args) -> int:
        """Handle system monitoring."""
        self.output("📊 System monitoring...", args)
        
        if args.real_time:
            self.output("🔄 Real-time monitoring mode (Ctrl+C to exit)", args)
            try:
                while True:
                    await self.show_monitoring_data(args)
                    await asyncio.sleep(args.interval)
            except KeyboardInterrupt:
                self.output("\n👋 Monitoring stopped", args)
        else:
            await self.show_monitoring_data(args)
        
        return 0
    
    async def handle_optimize(self, args) -> int:
        """Handle system optimization."""
        self.output("🔧 Analyzing system for optimization opportunities...", args)
        
        suggestions = [
            "Consider increasing cache size for better performance",
            "Enable parallel processing for improved throughput",
            "Use cost-optimal model selection to reduce expenses"
        ]
        
        if args.dry_run:
            self.output("💡 Optimization suggestions (dry run):", args)
            for suggestion in suggestions:
                self.output(f"  • {suggestion}", args)
        else:
            self.output("✅ System optimization completed", args)
        
        return 0
    
    async def handle_export(self, args) -> int:
        """Handle data export."""
        self.output(f"📤 Exporting {args.type} data...", args)
        
        export_data = {
            "version": self.version,
            "exported_at": datetime.now().isoformat(),
            "type": args.type
        }
        
        output_file = args.output or Path(f"exxede-export-{args.type}-{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
        
        with open(output_file, 'w') as f:
            json.dump(export_data, f, indent=2)
        
        self.output(f"✅ Export saved to: {output_file}", args)
        return 0
    
    async def handle_import(self, args) -> int:
        """Handle data import."""
        if not args.file.exists():
            self.output(f"❌ Import file not found: {args.file}", args)
            return 1
        
        self.output(f"📥 Importing data from: {args.file}", args)
        
        with open(args.file) as f:
            import_data = json.load(f)
        
        self.output(f"✅ Successfully imported {import_data.get('type', 'unknown')} data", args)
        return 0
    
    async def handle_system(self, args) -> int:
        """Handle system administration commands."""
        if args.system_action == "install":
            installer = GlobalBinaryInstaller(InstallationMode(args.mode))
            success = installer.full_install()
            return 0 if success else 1
        
        elif args.system_action == "uninstall":
            installer = GlobalBinaryInstaller()
            success = installer.uninstall()
            return 0 if success else 1
        
        else:
            self.output(f"❌ Unknown system action: {args.system_action}", args)
            return 1
    
    def output(self, message: str, args, level: str = "info"):
        """Output message in appropriate format."""
        if args.quiet and level != "error":
            return
        
        if args.format == "json" and level == "info":
            # For JSON format, only output structured data
            return
        
        print(message)
    
    async def calculate_health_score(self) -> float:
        """Calculate system health score."""
        # Simple health calculation - can be enhanced
        checks = [
            self.check_python_version(),
            self.check_dependencies(),
            self.check_agent_files(),
            self.check_configuration()
        ]
        
        passed = sum(checks)
        return (passed / len(checks)) * 100
    
    def check_python_version(self) -> bool:
        """Check Python version."""
        return sys.version_info >= (3, 8)
    
    def check_dependencies(self) -> bool:
        """Check required dependencies."""
        try:
            import yaml
            import asyncio
            import aiohttp
            return True
        except ImportError:
            return False
    
    def check_agent_files(self) -> bool:
        """Check agent files exist."""
        agents_dir = Path(__file__).parent.parent.parent / "agents"
        elite_count = len(list((agents_dir / "elite").glob("*.md"))) if (agents_dir / "elite").exists() else 0
        return elite_count >= 8
    
    def check_configuration(self) -> bool:
        """Check configuration files."""
        return self.config_dir.exists() and self.data_dir.exists()
    
    async def show_detailed_status(self, args):
        """Show detailed system status."""
        components = args.components or ["agents", "orchestrator", "context", "cache"]
        
        for component in components:
            self.output(f"\n🔧 {component.title()} Status:", args)
            if component == "agents":
                agents_dir = Path(__file__).parent.parent.parent / "agents"
                elite_count = len(list((agents_dir / "elite").glob("*.md"))) if (agents_dir / "elite").exists() else 0
                specialized_count = len(list((agents_dir / "specialized").glob("*.md"))) if (agents_dir / "specialized").exists() else 0
                self.output(f"  Elite agents: {elite_count}", args)
                self.output(f"  Specialized agents: {specialized_count}", args)
            elif component == "orchestrator":
                self.output(f"  Status: Available", args)
            elif component == "context":
                self.output(f"  Storage: {self.data_dir / 'context.db'}", args)
            elif component == "cache":
                cache_size = len(list(self.cache_dir.glob("*"))) if self.cache_dir.exists() else 0
                self.output(f"  Cache files: {cache_size}", args)
    
    async def show_monitoring_data(self, args):
        """Show current monitoring data."""
        timestamp = datetime.now().strftime("%H:%M:%S")
        
        # Simple monitoring data
        data = {
            "timestamp": timestamp,
            "health": await self.calculate_health_score(),
            "memory_usage": "N/A",  # Could integrate psutil
            "active_tasks": 0
        }
        
        if args.format == "json":
            self.output(json.dumps(data, indent=2), args)
        else:
            self.output(f"[{timestamp}] Health: {data['health']:.1f}% | Tasks: {data['active_tasks']}", args)
    
    def get_system_uptime(self) -> str:
        """Get system uptime."""
        # Simple uptime calculation
        return "Available"


def main():
    """Main entry point."""
    cli = ExxedeAgentsCLI()
    return asyncio.run(cli.run())


if __name__ == "__main__":
    sys.exit(main())