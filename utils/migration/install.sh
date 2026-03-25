#!/bin/bash

# Exxede Agent System Installer
# This script sets up the agent system globally for easy access

set -e

AGENTS_DIR="$HOME/Desktop/agents"
BIN_DIR="$HOME/.local/bin"
SHELL_CONFIG=""

# Detect shell configuration file
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    echo "Unsupported shell. Please manually add aliases to your shell configuration."
    exit 1
fi

echo "🚀 Installing Exxede Agent System..."

# Create local bin directory if it doesn't exist
mkdir -p "$BIN_DIR"

# Create symlink for agent installer
if [ -f "$AGENTS_DIR/agent-installer.py" ]; then
    ln -sf "$AGENTS_DIR/agent-installer.py" "$BIN_DIR/exxede-agents"
    chmod +x "$BIN_DIR/exxede-agents"
    echo "✅ Created exxede-agents command"
else
    echo "❌ Agent installer not found at $AGENTS_DIR/agent-installer.py"
    exit 1
fi

# Add to PATH if not already present
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Exxede Agent System" >> "$SHELL_CONFIG"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_CONFIG"
    echo "✅ Added $BIN_DIR to PATH in $SHELL_CONFIG"
fi

# Add useful aliases
echo "" >> "$SHELL_CONFIG"
echo "# Exxede Agent Aliases" >> "$SHELL_CONFIG"
echo "alias agents='exxede-agents'" >> "$SHELL_CONFIG"
echo "alias init-agents='exxede-agents --init'" >> "$SHELL_CONFIG"
echo "alias list-agents='exxede-agents --list'" >> "$SHELL_CONFIG"
echo "alias update-agents='exxede-agents --update'" >> "$SHELL_CONFIG"
echo "alias show-installed='exxede-agents --installed'" >> "$SHELL_CONFIG"

# Create project initialization function
cat >> "$SHELL_CONFIG" << 'EOF'

# Exxede Project Initialization Function
init-exxede-project() {
    local project_name="${1:-$(basename $(pwd))}"
    
    echo "🏗️  Initializing Exxede project: $project_name"
    
    # Initialize git if not already present
    if [ ! -d ".git" ]; then
        git init
        echo "✅ Initialized git repository"
    fi
    
    # Create basic project structure
    mkdir -p docs
    
    # Create CLAUDE.md if it doesn't exist
    if [ ! -f "CLAUDE.md" ]; then
        cat > CLAUDE.md << EOL
# $project_name

This project uses the Exxede Agent System for AI-powered development assistance.

## Available Agents
The following agents are installed and configured for this project:

EOL
        echo "✅ Created CLAUDE.md"
    fi
    
    # Install agents based on project type
    exxede-agents --init
    
    # Update CLAUDE.md with installed agents
    if [ -f ".exxede-agents.yaml" ]; then
        echo "" >> CLAUDE.md
        echo "## Installed Agents" >> CLAUDE.md
        echo "Agents are located in the \`.agents/\` directory:" >> CLAUDE.md
        echo "" >> CLAUDE.md
        for agent_file in .agents/*.md; do
            if [ -f "$agent_file" ]; then
                agent_name=$(basename "$agent_file" .md)
                formatted_name=$(echo "$agent_name" | sed 's/-/ /g' | sed 's/\b\w/\u&/g')
                echo "- **$formatted_name**: \`.agents/$agent_name.md\`" >> CLAUDE.md
            fi
        done
        echo "" >> CLAUDE.md
        echo "Use \`exxede-agents --help\` for management commands." >> CLAUDE.md
        echo "✅ Updated CLAUDE.md with agent information"
    fi
    
    echo "🎉 Project initialized successfully!"
    echo "📋 Next steps:"
    echo "   1. Review installed agents in .agents/ directory"
    echo "   2. Customize CLAUDE.md with project-specific context"
    echo "   3. Start using agents by copying their content or referencing them"
}
EOF

echo "✅ Added project initialization function"

# Create global agent configuration
cat > "$HOME/.exxede-agent-config.yaml" << EOF
# Exxede Agent System Global Configuration
version: "1.0"
default_agents:
  - strategic-business-analyst
  - dominican-market-specialist

# Default enhancement settings
enhancements:
  enabled: true
  include_project_context: true
  include_training_data: true

# Exxede business context
business_context:
  companies:
    - name: "Exxede Investments"
      focus: "Investment and business development"
    - name: "ReppingDR"
      focus: "Cultural merchandise and Dominican pride"
    - name: "Prolici"
      focus: "Business services and consulting"
    - name: "Exxede.dev"
      focus: "Technology development and digital solutions"
  
  markets:
    primary: "Dominican Republic"
    secondary: ["Caribbean", "Latin America", "US Hispanic Market"]
    headquarters: "Punta Cana, Dominican Republic"
  
  preferences:
    languages: ["English", "Spanish"]
    cultural_focus: "Caribbean and Latin American markets"
    business_approach: "Relationship-focused, long-term value creation"
EOF

echo "✅ Created global configuration"

# Install Python dependencies if available
if command -v pip3 &> /dev/null; then
    echo "📦 Installing Python dependencies..."
    pip3 install --user pyyaml > /dev/null 2>&1 || echo "⚠️  Could not install pyyaml. Manual installation may be required."
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "📋 Available commands after restarting your shell:"
echo "   exxede-agents          - Main agent management command"
echo "   agents                 - Short alias for exxede-agents"
echo "   init-agents            - Initialize agents in current project"
echo "   list-agents            - List all available agents"
echo "   update-agents          - Update installed agents"
echo "   show-installed         - Show agents installed in current project"
echo "   init-exxede-project    - Complete project initialization"
echo ""
echo "💡 Usage examples:"
echo "   cd my-new-project"
echo "   init-exxede-project"
echo "   agents --list"
echo "   agents --init"
echo ""
echo "🔄 Please restart your terminal or run: source $SHELL_CONFIG"