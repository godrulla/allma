#!/bin/bash

# Elite Global Agent System Installer
# World-class AI agents with cutting-edge expertise and memorable personalities

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

echo "🌟 Installing Elite Global Agent System..."
echo "   World-class AI agents with cutting-edge expertise"

# Create local bin directory if it doesn't exist
mkdir -p "$BIN_DIR"

# Create symlink for elite agent installer
if [ -f "$AGENTS_DIR/elite-agent-installer.py" ]; then
    ln -sf "$AGENTS_DIR/elite-agent-installer.py" "$BIN_DIR/elite-agents"
    chmod +x "$BIN_DIR/elite-agents"
    echo "✅ Created elite-agents command"
else
    echo "❌ Elite agent installer not found at $AGENTS_DIR/elite-agent-installer.py"
    exit 1
fi

# Add to PATH if not already present
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Elite Global Agent System" >> "$SHELL_CONFIG"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_CONFIG"
    echo "✅ Added $BIN_DIR to PATH in $SHELL_CONFIG"
fi

# Add elite agent aliases and functions
echo "" >> "$SHELL_CONFIG"
echo "# Elite Agent System Aliases" >> "$SHELL_CONFIG"
echo "alias agents='elite-agents'" >> "$SHELL_CONFIG"
echo "alias init-elite='elite-agents --init'" >> "$SHELL_CONFIG"
echo "alias list-elite='elite-agents --list'" >> "$SHELL_CONFIG"
echo "alias show-elite='elite-agents --show'" >> "$SHELL_CONFIG"

# Add individual agent nickname aliases
echo "" >> "$SHELL_CONFIG"
echo "# Elite Agent Nicknames" >> "$SHELL_CONFIG"
echo "alias '*arq'='echo \"🏗️ ARQ - The Visionary Architect: Building tomorrow'\''s systems with today'\''s vision\"'" >> "$SHELL_CONFIG"
echo "alias '*orc'='echo \"🎼 ORC - The Master Orchestrator: Conducting symphonies of complex workflows\"'" >> "$SHELL_CONFIG"
echo "alias '*zen'='echo \"🧘 ZEN - The Code Zen Master: Writing code that transcends mere functionality\"'" >> "$SHELL_CONFIG"
echo "alias '*vex'='echo \"🎨 VEX - The Creative Visionary: Designing experiences that move souls\"'" >> "$SHELL_CONFIG"
echo "alias '*sage'='echo \"🔮 SAGE - The Strategic Oracle: Seeing patterns others miss, predicting what others can'\''t\"'" >> "$SHELL_CONFIG"
echo "alias '*nova'='echo \"🚀 NOVA - The Innovation Catalyst: Turning impossible ideas into inevitable realities\"'" >> "$SHELL_CONFIG"
echo "alias '*echo'='echo \"🎤 ECHO - The Voice of the People: Amplifying authentic human connections through technology\"'" >> "$SHELL_CONFIG"

# Create elite project initialization function
cat >> "$SHELL_CONFIG" << 'EOF'

# Elite Project Initialization Function
init-elite-project() {
    local project_name="${1:-$(basename $(pwd))}"
    
    echo "🌟 Initializing Elite Project: $project_name"
    echo "   World-class AI agents with cutting-edge expertise"
    
    # Initialize git if not already present
    if [ ! -d ".git" ]; then
        git init
        echo "✅ Initialized git repository"
    fi
    
    # Create elite project structure
    mkdir -p docs .agents
    
    # Create CLAUDE.md if it doesn't exist
    if [ ! -f "CLAUDE.md" ]; then
        cat > CLAUDE.md << EOL
# $project_name

This project uses the Elite Global Agent System - world-class AI agents with cutting-edge expertise.

## Elite Agents Available

These agents combine cutting-edge expertise with memorable personalities and deeper purpose:

EOL
        echo "✅ Created CLAUDE.md"
    fi
    
    # Install elite agents based on project detection
    elite-agents --init
    
    # Update CLAUDE.md with installed elite agents
    if [ -f ".elite-agents.yaml" ]; then
        echo "" >> CLAUDE.md
        echo "## Installed Elite Agents" >> CLAUDE.md
        echo "Your world-class AI team is ready in the \`.agents/\` directory:" >> CLAUDE.md
        echo "" >> CLAUDE.md
        
        # Add agent details if available
        if [ -f ".agents/ARQ.md" ]; then
            echo "- **ARQ (*arq)** - The Visionary Architect: \`.agents/ARQ.md\`" >> CLAUDE.md
        fi
        if [ -f ".agents/ORC.md" ]; then
            echo "- **ORC (*orc)** - The Master Orchestrator: \`.agents/ORC.md\`" >> CLAUDE.md
        fi
        if [ -f ".agents/ZEN.md" ]; then
            echo "- **ZEN (*zen)** - The Code Zen Master: \`.agents/ZEN.md\`" >> CLAUDE.md
        fi
        if [ -f ".agents/VEX.md" ]; then
            echo "- **VEX (*vex)** - The Creative Visionary: \`.agents/VEX.md\`" >> CLAUDE.md
        fi
        if [ -f ".agents/SAGE.md" ]; then
            echo "- **SAGE (*sage)** - The Strategic Oracle: \`.agents/SAGE.md\`" >> CLAUDE.md
        fi
        if [ -f ".agents/NOVA.md" ]; then
            echo "- **NOVA (*nova)** - The Innovation Catalyst: \`.agents/NOVA.md\`" >> CLAUDE.md
        fi
        if [ -f ".agents/ECHO.md" ]; then
            echo "- **ECHO (*echo)** - The Voice of the People: \`.agents/ECHO.md\`" >> CLAUDE.md
        fi
        
        echo "" >> CLAUDE.md
        echo "## Quick Access" >> CLAUDE.md
        echo "Use agent nicknames for instant invocation:" >> CLAUDE.md
        echo "\`\`\`bash" >> CLAUDE.md
        echo "*arq   # Architecture and system design" >> CLAUDE.md
        echo "*zen   # Clean code and elegant programming" >> CLAUDE.md
        echo "*vex   # Creative design and user experience" >> CLAUDE.md
        echo "*sage  # Strategic analysis and market intelligence" >> CLAUDE.md
        echo "\`\`\`" >> CLAUDE.md
        echo "" >> CLAUDE.md
        echo "Each agent brings world-class expertise with memorable personality and deeper purpose." >> CLAUDE.md
        echo "Use \`elite-agents --help\` for management commands." >> CLAUDE.md
        echo "✅ Updated CLAUDE.md with elite agent information"
    fi
    
    echo ""
    echo "🎉 Elite project initialized successfully!"
    echo "📋 Your world-class AI team is ready:"
    echo "   • Use agent nicknames (*arq, *zen, *vex, etc.) for instant access"
    echo "   • Each agent has cutting-edge expertise and memorable personality"
    echo "   • Agents adapt to your project context and requirements"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Review your elite agents in .agents/ directory"
    echo "   2. Customize CLAUDE.md with project-specific context"  
    echo "   3. Start using agents with their memorable nicknames"
}

# Elite Agent Quick Help Function
elite-help() {
    echo "🌟 Elite Global Agent System - Quick Reference"
    echo ""
    echo "Available Elite Agents:"
    echo "  *arq  🏗️  ARQ - Visionary Architect (system design, architecture)"
    echo "  *orc  🎼  ORC - Master Orchestrator (workflow coordination)"
    echo "  *zen  🧘  ZEN - Code Zen Master (clean code, elegant programming)"
    echo "  *vex  🎨  VEX - Creative Visionary (design, user experience)"
    echo "  *sage 🔮  SAGE - Strategic Oracle (market analysis, strategy)"
    echo "  *nova 🚀  NOVA - Innovation Catalyst (breakthrough thinking)"
    echo "  *echo 🎤  ECHO - Voice of the People (community, content)"
    echo ""
    echo "Commands:"
    echo "  elite-agents --list      # List all available agents"
    echo "  elite-agents --init      # Install recommended agents"
    echo "  elite-agents --installed # Show installed agents"
    echo "  init-elite-project       # Initialize new project with agents"
    echo ""
    echo "Each agent brings world-class expertise with memorable personality! 🚀"
}

# Add help alias
alias elite-help='elite-help'
EOF

# Create global elite configuration
cat > "$HOME/.elite-agent-config.yaml" << EOF
# Elite Global Agent System Configuration
version: "2.0"
system_type: "Global Elite Agents"

# Default elite agents for new projects
default_agents:
  - SAGE  # Strategic intelligence for all projects
  - ARQ   # System architecture expertise

# Elite agent enhancement settings
enhancements:
  enabled: true
  project_context_injection: true
  personality_adaptation: true
  cutting_edge_updates: true

# Elite agent philosophy
philosophy: "World-class expertise with memorable personalities and deeper purpose"

# Success standards
standards:
  expertise_level: "Global Elite"
  personality_depth: "Memorable and authentic"
  purpose_driven: "Beyond task completion"
  cultural_intelligence: "Globally aware, locally relevant"
  
# Installation metadata
installed_at: "$(date -Iseconds)"
installer_version: "2.0"
EOF

echo "✅ Created global elite configuration"

echo ""
echo "🎉 Elite Global Agent System installation complete!"
echo ""
echo "🌟 Your World-Class AI Team:"
echo "   ARQ  🏗️  - Visionary system architect" 
echo "   ORC  🎼  - Master workflow orchestrator"
echo "   ZEN  🧘  - Code zen master"
echo "   VEX  🎨  - Creative design visionary"
echo "   SAGE 🔮  - Strategic oracle"
echo "   NOVA 🚀  - Innovation catalyst"
echo "   ECHO 🎤  - Voice of the people"
echo ""
echo "📋 Available commands after restarting your shell:"
echo "   elite-agents             # Main agent management"
echo "   init-elite-project       # Initialize new project"  
echo "   elite-help               # Quick reference guide"
echo "   *arq, *zen, *vex, etc.   # Agent nickname reminders"
echo ""
echo "💡 Quick start:"
echo "   cd my-new-project"
echo "   init-elite-project"
echo "   elite-agents --list"
echo ""
echo "🔄 Please restart your terminal or run: source $SHELL_CONFIG"
echo ""
echo "Ready to work with world-class AI agents? Your elite team awaits! 🚀✨"