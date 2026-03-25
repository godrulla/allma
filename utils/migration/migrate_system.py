#!/usr/bin/env python3
"""
Exxede Agent System Migration Utility
Migrates from old scattered structure to new organized system.

Author: Armando Diaz Silverio, CEO of Exxede Investments
"""

import os
import sys
import json
import yaml
import shutil
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any, Tuple

class SystemMigrator:
    """Migrates Exxede Agent System to new organizational structure."""
    
    def __init__(self, source_dir: str, target_dir: str = None):
        self.source_dir = Path(source_dir)
        self.target_dir = Path(target_dir or source_dir)
        self.backup_dir = self.target_dir.parent / f"{self.target_dir.name}_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        # Elite agent patterns
        self.elite_patterns = {
            "ARQ": ["architect", "architecture", "system", "scalability"],
            "APEX": ["mobile", "pwa", "performance", "touch"],
            "ZEN": ["code", "clean", "refactor", "algorithm"],
            "VEX": ["design", "ui", "ux", "creative"],
            "SAGE": ["strategy", "market", "analysis", "intelligence"],
            "NOVA": ["innovation", "breakthrough", "research"],
            "ECHO": ["content", "community", "voice", "communication"],
            "ORC": ["orchestration", "workflow", "coordination"]
        }
        
        # Migration results
        self.results = {
            "backed_up": [],
            "migrated_agents": [],
            "migrated_scripts": [],
            "created_configs": [],
            "errors": [],
            "warnings": []
        }
    
    def create_backup(self) -> bool:
        """Create full backup of current system."""
        try:
            if self.source_dir.exists():
                shutil.copytree(self.source_dir, self.backup_dir)
                self.results["backed_up"].append(str(self.backup_dir))
                print(f"✅ Backup created: {self.backup_dir}")
                return True
            else:
                self.results["errors"].append(f"Source directory does not exist: {self.source_dir}")
                return False
        except Exception as e:
            self.results["errors"].append(f"Backup failed: {str(e)}")
            return False
    
    def create_directory_structure(self) -> bool:
        """Create new organized directory structure."""
        try:
            directories = [
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
            
            for dir_path in directories:
                full_path = self.target_dir / dir_path
                full_path.mkdir(parents=True, exist_ok=True)
            
            print("✅ Directory structure created")
            return True
            
        except Exception as e:
            self.results["errors"].append(f"Directory creation failed: {str(e)}")
            return False
    
    def detect_agent_category(self, agent_file: Path) -> str:
        """Detect agent category based on filename and content."""
        filename = agent_file.stem.upper()
        
        # Check if it's an elite agent
        if filename in self.elite_patterns:
            return "elite"
        
        # Check content patterns for elite agents
        try:
            with open(agent_file, 'r', encoding='utf-8') as f:
                content = f.read().lower()
                
            for elite_code, patterns in self.elite_patterns.items():
                if filename == elite_code or any(pattern in content for pattern in patterns):
                    return "elite"
        except Exception:
            pass
        
        # Check for specialized agent patterns
        if any(keyword in filename.lower() for keyword in [
            "agent", "specialist", "expert", "manager", "automation"
        ]):
            return "specialized"
        
        return "legacy"
    
    def extract_agent_metadata(self, agent_file: Path) -> Dict[str, Any]:
        """Extract metadata from agent file."""
        metadata = {
            "agent_id": agent_file.stem.upper(),
            "full_name": agent_file.stem.replace("-", " ").title(),
            "nickname": f"*{agent_file.stem.lower()}",
            "purpose": "Agent purpose to be defined",
            "version": "3.0",
            "created": datetime.now().isoformat(),
            "updated": datetime.now().isoformat(),
            "expertise": [],
            "personality": "professional, helpful",
            "use_cases": []
        }
        
        try:
            with open(agent_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extract title from first header
            title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
            if title_match:
                metadata["full_name"] = title_match.group(1).strip()
            
            # Extract purpose from description patterns
            purpose_patterns = [
                r'Purpose[:\s]+(.+?)(?:\n|$)',
                r'Description[:\s]+(.+?)(?:\n|$)',
                r'## Purpose\s*\n(.+?)(?:\n##|\n\n|$)',
                r'> (.+?)(?:\n|$)'  # Quoted descriptions
            ]
            
            for pattern in purpose_patterns:
                match = re.search(pattern, content, re.IGNORECASE | re.DOTALL)
                if match:
                    purpose = match.group(1).strip()
                    if len(purpose) > 10:  # Ensure it's meaningful
                        metadata["purpose"] = purpose[:200]  # Truncate if too long
                        break
            
            # Extract expertise from content keywords
            expertise_keywords = re.findall(r'\b(\w+(?:-\w+)*)\b', content.lower())
            common_expertise = [
                "architecture", "scalability", "performance", "security",
                "design", "user-experience", "interface", "creative",
                "strategy", "analysis", "planning", "forecasting",
                "development", "coding", "algorithms", "refactoring",
                "innovation", "research", "breakthrough", "emerging",
                "content", "communication", "community", "marketing",
                "orchestration", "workflow", "coordination", "automation"
            ]
            
            found_expertise = []
            for keyword in common_expertise:
                if keyword in expertise_keywords and len(found_expertise) < 6:
                    found_expertise.append(keyword)
            
            metadata["expertise"] = found_expertise or ["general-expertise"]
            
        except Exception as e:
            self.results["warnings"].append(f"Could not extract metadata from {agent_file.name}: {str(e)}")
        
        return metadata
    
    def migrate_agents(self) -> bool:
        """Migrate agent files to appropriate categories."""
        try:
            agent_files = list(self.source_dir.glob("*.md"))
            
            # Filter out documentation files
            doc_patterns = ["readme", "usage", "system", "guide", "demo", "activation"]
            agent_files = [f for f in agent_files if not any(pattern in f.stem.lower() for pattern in doc_patterns)]
            
            for agent_file in agent_files:
                category = self.detect_agent_category(agent_file)
                target_path = self.target_dir / "agents" / category / agent_file.name
                
                try:
                    # Copy agent file
                    shutil.copy2(agent_file, target_path)
                    
                    # Extract and save metadata
                    metadata = self.extract_agent_metadata(agent_file)
                    metadata_file = target_path.with_suffix('.metadata.yaml')
                    
                    with open(metadata_file, 'w') as f:
                        yaml.dump(metadata, f, default_flow_style=False, sort_keys=False)
                    
                    self.results["migrated_agents"].append({
                        "file": agent_file.name,
                        "category": category,
                        "target": str(target_path)
                    })
                    
                    print(f"✅ Migrated {agent_file.name} to {category}")
                    
                except Exception as e:
                    self.results["errors"].append(f"Failed to migrate {agent_file.name}: {str(e)}")
            
            return True
            
        except Exception as e:
            self.results["errors"].append(f"Agent migration failed: {str(e)}")
            return False
    
    def migrate_scripts(self) -> bool:
        """Migrate Python scripts to organized structure."""
        try:
            script_mappings = {
                "core/installer": [
                    "agent-installer.py",
                    "elite-agent-installer.py", 
                    "create-elite-project.py"
                ],
                "core/orchestrator": [
                    "multi-model-orchestrator.py",
                    "auto-context-injector.py",
                    "nickname-agent-activator.py",
                    "claude-code-integration.py",
                    "claude-init-integration.py"
                ],
                "core/testing": [
                    "test-all-agents.py"
                ],
                "utils/migration": [
                    "install.sh",
                    "elite-install.sh"
                ]
            }
            
            for target_dir, scripts in script_mappings.items():
                for script in scripts:
                    source_file = self.source_dir / script
                    if source_file.exists():
                        target_path = self.target_dir / target_dir / script
                        target_path.parent.mkdir(parents=True, exist_ok=True)
                        
                        try:
                            shutil.copy2(source_file, target_path)
                            self.results["migrated_scripts"].append({
                                "file": script,
                                "target": str(target_path)
                            })
                            print(f"✅ Migrated {script}")
                        except Exception as e:
                            self.results["errors"].append(f"Failed to migrate {script}: {str(e)}")
            
            return True
            
        except Exception as e:
            self.results["errors"].append(f"Script migration failed: {str(e)}")
            return False
    
    def migrate_training_data(self) -> bool:
        """Migrate training data to config directory."""
        try:
            training_source = self.source_dir / "training"
            if training_source.exists():
                training_target = self.target_dir / "config" / "training"
                
                for training_file in training_source.glob("*.yaml"):
                    target_path = training_target / training_file.name
                    shutil.copy2(training_file, target_path)
                    print(f"✅ Migrated training: {training_file.name}")
            
            return True
            
        except Exception as e:
            self.results["errors"].append(f"Training data migration failed: {str(e)}")
            return False
    
    def migrate_documentation(self) -> bool:
        """Migrate documentation files."""
        try:
            doc_files = [
                "README.md", "USAGE-GUIDE.md", "SYSTEM-GUIDE.md",
                "ELITE-AGENTS-README.md", "ACTIVATION-SYSTEM-README.md",
                "DEMO.md", "CLAUDE.md"
            ]
            
            for doc_file in doc_files:
                source_file = self.source_dir / doc_file
                if source_file.exists():
                    target_path = self.target_dir / "docs" / "guides" / doc_file
                    shutil.copy2(source_file, target_path)
                    print(f"✅ Migrated doc: {doc_file}")
            
            return True
            
        except Exception as e:
            self.results["errors"].append(f"Documentation migration failed: {str(e)}")
            return False
    
    def create_system_config(self) -> bool:
        """Create system configuration files."""
        try:
            # Main system config
            system_config = {
                "system": {
                    "version": "3.0",
                    "name": "Exxede Agent System",
                    "reorganized": datetime.now().isoformat(),
                    "migration_completed": True
                },
                "structure": {
                    "elite_agents": len(list((self.target_dir / "agents" / "elite").glob("*.md"))),
                    "specialized_agents": len(list((self.target_dir / "agents" / "specialized").glob("*.md"))),
                    "legacy_agents": len(list((self.target_dir / "agents" / "legacy").glob("*.md")))
                },
                "migration": {
                    "date": datetime.now().isoformat(),
                    "backup_location": str(self.backup_dir),
                    "migrated_agents": len(self.results["migrated_agents"]),
                    "migrated_scripts": len(self.results["migrated_scripts"])
                }
            }
            
            config_file = self.target_dir / "config" / "system.yaml"
            with open(config_file, 'w') as f:
                yaml.dump(system_config, f, default_flow_style=False, sort_keys=False)
            
            self.results["created_configs"].append(str(config_file))
            print("✅ Created system configuration")
            
            return True
            
        except Exception as e:
            self.results["errors"].append(f"System config creation failed: {str(e)}")
            return False
    
    def update_script_imports(self) -> bool:
        """Update import paths in migrated scripts."""
        try:
            # Update Python scripts to work with new structure
            scripts_to_update = [
                self.target_dir / "core" / "orchestrator" / "auto-context-injector.py",
                self.target_dir / "core" / "testing" / "test-all-agents.py"
            ]
            
            for script_path in scripts_to_update:
                if script_path.exists():
                    with open(script_path, 'r') as f:
                        content = f.read()
                    
                    # Update relative imports to work with new structure
                    content = content.replace(
                        'from multi_model_orchestrator import',
                        'sys.path.insert(0, str(Path(__file__).parent)); from multi_model_orchestrator import'
                    )
                    
                    with open(script_path, 'w') as f:
                        f.write(content)
            
            print("✅ Updated script imports")
            return True
            
        except Exception as e:
            self.results["warnings"].append(f"Script import updates failed: {str(e)}")
            return True  # Not critical
    
    def run_migration(self) -> Dict[str, Any]:
        """Run complete migration process."""
        print("🚀 Starting Exxede Agent System Migration")
        print("=" * 50)
        
        steps = [
            ("Creating backup", self.create_backup),
            ("Creating directory structure", self.create_directory_structure),
            ("Migrating agents", self.migrate_agents),
            ("Migrating scripts", self.migrate_scripts),
            ("Migrating training data", self.migrate_training_data),
            ("Migrating documentation", self.migrate_documentation),
            ("Creating system config", self.create_system_config),
            ("Updating script imports", self.update_script_imports)
        ]
        
        success_count = 0
        for step_name, step_func in steps:
            print(f"\n🔄 {step_name}...")
            if step_func():
                success_count += 1
            else:
                print(f"❌ {step_name} failed")
        
        print("\n" + "=" * 50)
        print("📊 Migration Results:")
        print(f"✅ Successful steps: {success_count}/{len(steps)}")
        print(f"📁 Backup location: {self.backup_dir}")
        print(f"🤖 Migrated agents: {len(self.results['migrated_agents'])}")
        print(f"🐍 Migrated scripts: {len(self.results['migrated_scripts'])}")
        
        if self.results["errors"]:
            print(f"❌ Errors: {len(self.results['errors'])}")
            for error in self.results["errors"]:
                print(f"   - {error}")
        
        if self.results["warnings"]:
            print(f"⚠️  Warnings: {len(self.results['warnings'])}")
        
        self.results["migration_success"] = success_count == len(steps)
        self.results["completion_time"] = datetime.now().isoformat()
        
        return self.results


def main():
    """Main migration script."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Migrate Exxede Agent System to new structure")
    parser.add_argument("source", help="Source directory to migrate from")
    parser.add_argument("--target", help="Target directory (default: same as source)")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be migrated")
    
    args = parser.parse_args()
    
    if args.dry_run:
        print("🔍 DRY RUN - No changes will be made")
        # TODO: Implement dry run analysis
        return
    
    migrator = SystemMigrator(args.source, args.target)
    results = migrator.run_migration()
    
    # Save migration report
    report_file = Path(args.target or args.source) / "migration_report.json"
    with open(report_file, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    print(f"\n📄 Migration report saved: {report_file}")
    
    if results["migration_success"]:
        print("🎉 Migration completed successfully!")
        sys.exit(0)
    else:
        print("⚠️  Migration completed with errors - check the report")
        sys.exit(1)


if __name__ == "__main__":
    main()