#!/usr/bin/env python3
"""
Claude /init Integration for Elite Agent System
Automatically detects and loads appropriate agents when starting a project
"""

import os
import sys
import json
import subprocess
from pathlib import Path

# Add agents directory to path
agents_dir = Path.home() / "Desktop" / "agents"
if agents_dir.exists():
    sys.path.insert(0, str(agents_dir))
else:
    print(f"Warning: Agents directory not found at {agents_dir}")
    sys.exit(1)

def detect_and_load_agents():
    """Main function called by Claude's /init command"""
    
    print("🚀 Claude Elite Agent Initialization")
    print("=" * 50)
    
    # Run the elite agent installer in detection mode
    try:
        # Import the existing elite agent installer
        import importlib.util
        spec = importlib.util.spec_from_file_location("elite_agent_installer", 
                                                      agents_dir / "elite-agent-installer.py")
        elite_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(elite_module)
        EliteAgentInstaller = elite_module.EliteAgentInstaller
        
        installer = EliteAgentInstaller()
        
        # Detect project type
        project_types = installer.detect_project_type()
        project_name = Path.cwd().name
        
        print(f"📁 Project: {project_name}")
        print(f"📍 Location: {Path.cwd()}")
        
        if project_types:
            print(f"🔍 Detected Types: {', '.join(project_types)}")
        else:
            print("🔍 Type: General Development")
        
        # Get recommended agents
        recommended = installer.get_recommended_agents(project_types)
        
        # Check for mobile development patterns
        has_mobile = False
        package_json = Path.cwd() / "package.json"
        if package_json.exists():
            with open(package_json) as f:
                content = f.read()
                if any(framework in content for framework in ["react-native", "capacitor", "ionic", "expo"]):
                    has_mobile = True
                    if "APEX" not in recommended:
                        recommended.append("APEX")
        
        # Always include master orchestrator for complex projects
        if len(recommended) > 3 and "ORC" not in recommended:
            recommended.insert(0, "ORC")
        
        print(f"\n🤖 Recommended Elite Agents:")
        for agent_code in recommended:
            if agent_code in installer.elite_agents:
                agent = installer.elite_agents[agent_code]
                if not agent.get("coming_soon", False):
                    print(f"  • {agent_code} ({agent['nickname']}) - {agent['full_name']}")
                    print(f"    Purpose: {agent['purpose']}")
        
        # Check if agents are already installed
        installed = installer.list_installed_agents()
        if installed:
            print(f"\n✅ Already Installed: {', '.join([a['code'] for a in installed])}")
        
        # Auto-install recommended agents if not present
        agents_to_install = []
        installed_codes = [a['code'] for a in installed]
        
        for agent in recommended:
            if agent not in installed_codes and agent in installer.elite_agents:
                if not installer.elite_agents[agent].get("coming_soon", False):
                    agents_to_install.append(agent)
        
        if agents_to_install:
            print(f"\n📦 Installing: {', '.join(agents_to_install)}")
            results = installer.install_agents(agents_to_install, enhanced=True)
            
            if results["installed"]:
                print(f"✅ Successfully installed: {', '.join(results['installed'])}")
        
        # Provide activation guide
        print("\n📝 Quick Activation Commands:")
        print("Use these nicknames to invoke specialized agents:")
        
        all_agents = set(installed_codes + agents_to_install)
        for agent_code in sorted(all_agents):
            if agent_code in installer.elite_agents:
                agent = installer.elite_agents[agent_code]
                print(f"  {agent['nickname']} - {agent['purpose']}")
        
        # Special instructions for detected patterns
        if has_mobile:
            print("\n📱 Mobile Development Mode Active!")
            print("  Use *apex for mobile optimization and PWA features")
        
        if len(all_agents) > 3:
            print("\n🎼 Complex Project Detected!")
            print("  Use *orc to coordinate multiple agents and workflows")
        
        print("\n🎯 Ready for development! Agents are loaded and waiting.")
        
    except Exception as e:
        print(f"⚠️ Error during initialization: {e}")
        print("You can manually install agents with:")
        print("  python3 ~/Desktop/agents/elite-agent-installer.py --init")
    
    return 0

if __name__ == "__main__":
    sys.exit(detect_and_load_agents())