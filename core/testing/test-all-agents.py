#!/usr/bin/env python3
"""
Test All Agent Activations
Comprehensive testing of all agent nickname activations
"""

import sys
from pathlib import Path

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Import from hyphenated filename
import importlib.util
spec = importlib.util.spec_from_file_location("nickname_agent_activator", Path(__file__).parent.parent / "orchestrator" / "nickname-agent-activator.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
NicknameAgentActivator = module.NicknameAgentActivator

def test_all_agents():
    """Test activation for all agents."""
    project_dir = str(Path(__file__).parent.parent.parent)
    activator = NicknameAgentActivator(project_dir)
    
    # Test cases for each agent
    test_cases = [
        ("*arq Design a scalable microservices architecture", "ARQ"),
        ("*zen Refactor this code for better performance", "ZEN"),
        ("*vex Create an intuitive user interface", "VEX"),
        ("*sage Analyze the competitive landscape", "SAGE"),
        ("*nova Research emerging AI technologies", "NOVA"),
        ("*echo Develop a content strategy", "ECHO"),
        ("*orc Coordinate the deployment pipeline", "ORC")
    ]
    
    print("🧪 Testing All Agent Activations\n" + "="*50)
    
    for test_input, expected_agent in test_cases:
        print(f"\n🔍 Testing: {test_input}")
        
        result = activator.activate_agent(test_input)
        
        if result and "error" not in result:
            actual_agent = result['agent']['agent_id']
            model = result['model_selection']['model']
            cost = result['model_selection']['estimated_cost']
            complexity = result['task']['complexity']
            
            if actual_agent == expected_agent:
                print(f"✅ SUCCESS: {expected_agent} activated")
                print(f"   📋 Model: {model}")
                print(f"   💰 Cost: ${cost:.4f}")
                print(f"   ⚡ Complexity: {complexity}")
            else:
                print(f"❌ FAILED: Expected {expected_agent}, got {actual_agent}")
        else:
            error = result.get("error", "Unknown error") if result else "No result returned"
            print(f"❌ ERROR: {error}")
    
    print(f"\n{'='*50}")
    print("🎯 Agent Activation Test Complete!")
    
    # Test available agents
    available = activator.get_available_agents()
    available_count = sum(1 for agent in available if agent['available'])
    
    print(f"📊 Available Agents: {available_count}/{len(available)}")
    
    for agent in available:
        status = "✅" if agent['available'] else "❌"
        print(f"   {status} {agent['nickname']} - {agent['title']}")

if __name__ == "__main__":
    test_all_agents()