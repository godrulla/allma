#!/usr/bin/env python3
"""
Exxede Agent System Validator
Comprehensive testing and validation framework for the reorganized system.

Author: Armando Diaz Silverio, CEO of Exxede Investments
"""

import os
import sys
import json
import yaml
import importlib.util
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any, Tuple

class SystemValidator:
    """Validates integrity and functionality of the Exxede Agent System."""
    
    def __init__(self, system_dir: str = None):
        self.system_dir = Path(system_dir or Path(__file__).parent.parent.parent)
        self.agents_dir = self.system_dir / "agents"
        self.config_dir = self.system_dir / "config"
        self.core_dir = self.system_dir / "core"
        self.utils_dir = self.system_dir / "utils"
        
        self.validation_results = {
            "structure": {"passed": [], "failed": [], "warnings": []},
            "agents": {"passed": [], "failed": [], "warnings": []},
            "scripts": {"passed": [], "failed": [], "warnings": []},
            "configuration": {"passed": [], "failed": [], "warnings": []},
            "integration": {"passed": [], "failed": [], "warnings": []},
            "overall": {"valid": False, "score": 0, "issues": []}
        }
    
    def validate_directory_structure(self) -> bool:
        """Validate the directory structure."""
        required_dirs = [
            "agents/elite",
            "agents/specialized", 
            "agents/legacy",
            "core/installer",
            "core/orchestrator",
            "core/testing",
            "config/schemas",
            "config/templates",
            "config/training",
            "utils/migration",
            "utils/validation",
            "docs/guides",
            "docs/examples"
        ]
        
        all_valid = True
        
        for dir_path in required_dirs:
            full_path = self.system_dir / dir_path
            if full_path.exists() and full_path.is_dir():
                self.validation_results["structure"]["passed"].append(dir_path)
            else:
                self.validation_results["structure"]["failed"].append(f"Missing directory: {dir_path}")
                all_valid = False
        
        # Check for unexpected files in root
        root_files = [f for f in self.system_dir.iterdir() if f.is_file()]
        expected_root_files = ["exxede-agents.py", "README.md", ".gitignore"]
        
        unexpected_files = [f.name for f in root_files if f.name not in expected_root_files and not f.name.startswith('.')]
        if unexpected_files:
            self.validation_results["structure"]["warnings"].append(f"Unexpected root files: {', '.join(unexpected_files)}")
        
        return all_valid
    
    def validate_elite_agents(self) -> bool:
        """Validate elite agents."""
        expected_elite_agents = ["ARQ", "APEX", "ZEN", "VEX", "SAGE", "NOVA", "ECHO", "ORC"]
        all_valid = True
        
        for agent_code in expected_elite_agents:
            agent_file = self.agents_dir / "elite" / f"{agent_code}.md"
            
            if agent_file.exists():
                # Validate agent file content
                try:
                    with open(agent_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Check for minimum content requirements
                    if len(content) > 100:  # Basic content check
                        self.validation_results["agents"]["passed"].append(f"Elite agent {agent_code}")
                    else:
                        self.validation_results["agents"]["warnings"].append(f"Elite agent {agent_code} has minimal content")
                        
                except Exception as e:
                    self.validation_results["agents"]["failed"].append(f"Elite agent {agent_code} read error: {str(e)}")
                    all_valid = False
            else:
                self.validation_results["agents"]["failed"].append(f"Missing elite agent: {agent_code}")
                all_valid = False
        
        return all_valid
    
    def validate_specialized_agents(self) -> bool:
        """Validate specialized agents."""
        specialized_dir = self.agents_dir / "specialized"
        if not specialized_dir.exists():
            self.validation_results["agents"]["failed"].append("Specialized agents directory missing")
            return False
        
        agent_files = list(specialized_dir.glob("*.md"))
        
        if len(agent_files) < 5:
            self.validation_results["agents"]["warnings"].append(f"Only {len(agent_files)} specialized agents found")
        
        for agent_file in agent_files:
            try:
                with open(agent_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if len(content) > 50:
                    self.validation_results["agents"]["passed"].append(f"Specialized agent {agent_file.stem}")
                else:
                    self.validation_results["agents"]["warnings"].append(f"Specialized agent {agent_file.stem} has minimal content")
                    
            except Exception as e:
                self.validation_results["agents"]["failed"].append(f"Specialized agent {agent_file.stem} error: {str(e)}")
        
        return True
    
    def validate_core_scripts(self) -> bool:
        """Validate core Python scripts."""
        required_scripts = {
            "core/installer/agent-installer.py": "AgentInstaller",
            "core/installer/elite-agent-installer.py": "EliteAgentInstaller", 
            "core/orchestrator/multi-model-orchestrator.py": "MultiModelOrchestrator",
            "core/testing/test-all-agents.py": "test_all_agents"
        }
        
        all_valid = True
        
        for script_path, expected_class in required_scripts.items():
            full_path = self.system_dir / script_path
            
            if full_path.exists():
                try:
                    # Try to load the module
                    spec = importlib.util.spec_from_file_location(
                        f"test_module_{full_path.stem}", full_path
                    )
                    module = importlib.util.module_from_spec(spec)
                    
                    # Basic syntax check by compilation
                    with open(full_path, 'r') as f:
                        compile(f.read(), str(full_path), 'exec')
                    
                    self.validation_results["scripts"]["passed"].append(script_path)
                    
                except SyntaxError as e:
                    self.validation_results["scripts"]["failed"].append(f"{script_path} syntax error: {str(e)}")
                    all_valid = False
                except Exception as e:
                    self.validation_results["scripts"]["warnings"].append(f"{script_path} import issue: {str(e)}")
            else:
                self.validation_results["scripts"]["failed"].append(f"Missing script: {script_path}")
                all_valid = False
        
        return all_valid
    
    def validate_unified_interface(self) -> bool:
        """Validate the unified exxede-agents.py interface."""
        interface_file = self.system_dir / "exxede-agents.py"
        
        if not interface_file.exists():
            self.validation_results["scripts"]["failed"].append("Missing unified interface: exxede-agents.py")
            return False
        
        try:
            with open(interface_file, 'r') as f:
                content = f.read()
            
            # Check for required methods
            required_methods = [
                "list_agents", "install_agents", "create_project", 
                "orchestrate_session", "activate_agent", "test_agents"
            ]
            
            missing_methods = []
            for method in required_methods:
                if f"def {method}" not in content:
                    missing_methods.append(method)
            
            if missing_methods:
                self.validation_results["scripts"]["failed"].append(f"Unified interface missing methods: {', '.join(missing_methods)}")
                return False
            
            # Basic syntax check
            compile(content, str(interface_file), 'exec')
            self.validation_results["scripts"]["passed"].append("Unified interface validation")
            return True
            
        except Exception as e:
            self.validation_results["scripts"]["failed"].append(f"Unified interface error: {str(e)}")
            return False
    
    def validate_configuration_files(self) -> bool:
        """Validate configuration files."""
        config_files = {
            "config/schemas/agent_metadata.yaml": "Agent metadata schema",
            "config/system.yaml": "System configuration"
        }
        
        all_valid = True
        
        for config_path, description in config_files.items():
            full_path = self.system_dir / config_path
            
            if full_path.exists():
                try:
                    with open(full_path, 'r') as f:
                        yaml.safe_load(f)
                    self.validation_results["configuration"]["passed"].append(description)
                except yaml.YAMLError as e:
                    self.validation_results["configuration"]["failed"].append(f"{description} YAML error: {str(e)}")
                    all_valid = False
            else:
                self.validation_results["configuration"]["warnings"].append(f"Missing config: {description}")
        
        return all_valid
    
    def validate_training_data(self) -> bool:
        """Validate training data files."""
        training_dir = self.config_dir / "training"
        
        if not training_dir.exists():
            self.validation_results["configuration"]["warnings"].append("Training data directory missing")
            return True  # Not critical
        
        training_files = list(training_dir.glob("*.yaml"))
        
        for training_file in training_files:
            try:
                with open(training_file, 'r') as f:
                    data = yaml.safe_load(f)
                
                # Check for required training data structure
                required_keys = ["specializations", "context_prompts", "best_practices"]
                missing_keys = [key for key in required_keys if key not in data]
                
                if missing_keys:
                    self.validation_results["configuration"]["warnings"].append(
                        f"Training file {training_file.name} missing keys: {', '.join(missing_keys)}"
                    )
                else:
                    self.validation_results["configuration"]["passed"].append(f"Training data {training_file.name}")
                    
            except Exception as e:
                self.validation_results["configuration"]["failed"].append(f"Training data {training_file.name} error: {str(e)}")
        
        return True
    
    def test_integration_functionality(self) -> bool:
        """Test integration between components."""
        all_valid = True
        
        # Test unified interface functionality
        try:
            sys.path.insert(0, str(self.system_dir))
            spec = importlib.util.spec_from_file_location(
                "exxede_agents", self.system_dir / "exxede-agents.py"
            )
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            
            # Test basic functionality
            system = module.ExxedeAgentSystem()
            
            # Test agent listing
            agents = system.list_agents()
            if isinstance(agents, dict) and "elite" in agents:
                self.validation_results["integration"]["passed"].append("Agent listing functionality")
            else:
                self.validation_results["integration"]["failed"].append("Agent listing failed")
                all_valid = False
            
            # Test system status
            status = system.get_system_status()
            if isinstance(status, dict) and "system" in status:
                self.validation_results["integration"]["passed"].append("System status functionality")
            else:
                self.validation_results["integration"]["failed"].append("System status failed")
                all_valid = False
                
        except Exception as e:
            self.validation_results["integration"]["failed"].append(f"Integration test error: {str(e)}")
            all_valid = False
        
        return all_valid
    
    def calculate_overall_score(self) -> float:
        """Calculate overall system health score."""
        total_passed = sum(len(cat["passed"]) for cat in self.validation_results.values() if isinstance(cat, dict) and "passed" in cat)
        total_failed = sum(len(cat["failed"]) for cat in self.validation_results.values() if isinstance(cat, dict) and "failed" in cat)
        total_warnings = sum(len(cat["warnings"]) for cat in self.validation_results.values() if isinstance(cat, dict) and "warnings" in cat)
        
        total_tests = total_passed + total_failed + total_warnings
        
        if total_tests == 0:
            return 0.0
        
        # Score calculation: full points for passed, half points for warnings, no points for failed
        score = (total_passed + (total_warnings * 0.5)) / total_tests
        return round(score * 100, 1)
    
    def run_full_validation(self) -> Dict[str, Any]:
        """Run complete system validation."""
        print("🔍 Exxede Agent System Validation")
        print("=" * 50)
        
        validation_steps = [
            ("Directory Structure", self.validate_directory_structure),
            ("Elite Agents", self.validate_elite_agents),
            ("Specialized Agents", self.validate_specialized_agents),
            ("Core Scripts", self.validate_core_scripts),
            ("Unified Interface", self.validate_unified_interface),
            ("Configuration Files", self.validate_configuration_files),
            ("Training Data", self.validate_training_data),
            ("Integration Tests", self.test_integration_functionality)
        ]
        
        step_results = {}
        
        for step_name, step_func in validation_steps:
            print(f"\n🔄 Validating {step_name}...")
            step_results[step_name] = step_func()
            
            if step_results[step_name]:
                print(f"✅ {step_name} validation passed")
            else:
                print(f"❌ {step_name} validation failed")
        
        # Calculate overall results
        overall_score = self.calculate_overall_score()
        overall_valid = overall_score >= 80.0  # 80% threshold for "valid"
        
        self.validation_results["overall"] = {
            "valid": overall_valid,
            "score": overall_score,
            "timestamp": datetime.now().isoformat(),
            "step_results": step_results
        }
        
        # Print summary
        print("\n" + "=" * 50)
        print("📊 Validation Summary:")
        print(f"Overall Score: {overall_score}%")
        print(f"System Status: {'✅ VALID' if overall_valid else '❌ ISSUES FOUND'}")
        
        for category, results in self.validation_results.items():
            if isinstance(results, dict) and "passed" in results:
                passed = len(results["passed"])
                failed = len(results["failed"])
                warnings = len(results["warnings"])
                
                if passed > 0 or failed > 0 or warnings > 0:
                    print(f"\n{category.title()}:")
                    if passed > 0:
                        print(f"  ✅ Passed: {passed}")
                    if warnings > 0:
                        print(f"  ⚠️  Warnings: {warnings}")
                    if failed > 0:
                        print(f"  ❌ Failed: {failed}")
        
        # Show specific issues
        all_issues = []
        for category, results in self.validation_results.items():
            if isinstance(results, dict) and "failed" in results:
                all_issues.extend(results["failed"])
        
        if all_issues:
            print(f"\n🚨 Critical Issues ({len(all_issues)}):")
            for issue in all_issues[:10]:  # Show first 10 issues
                print(f"  - {issue}")
            
            if len(all_issues) > 10:
                print(f"  ... and {len(all_issues) - 10} more issues")
        
        return self.validation_results
    
    def save_validation_report(self, output_file: str = None) -> str:
        """Save validation report to file."""
        if not output_file:
            output_file = self.system_dir / f"validation_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        with open(output_file, 'w') as f:
            json.dump(self.validation_results, f, indent=2, default=str)
        
        return str(output_file)


def main():
    """Main validation script."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Validate Exxede Agent System")
    parser.add_argument("--system-dir", help="System directory to validate")
    parser.add_argument("--output", help="Output file for validation report")
    parser.add_argument("--quiet", action="store_true", help="Minimal output")
    
    args = parser.parse_args()
    
    validator = SystemValidator(args.system_dir)
    
    if not args.quiet:
        results = validator.run_full_validation()
    else:
        # Quiet mode - just check critical components
        results = {
            "structure": validator.validate_directory_structure(),
            "elite_agents": validator.validate_elite_agents(),
            "core_scripts": validator.validate_core_scripts(),
            "overall": {"score": validator.calculate_overall_score()}
        }
    
    # Save report
    report_file = validator.save_validation_report(args.output)
    
    if not args.quiet:
        print(f"\n📄 Validation report saved: {report_file}")
    
    # Exit with appropriate code
    if results["overall"]["score"] >= 80.0:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()