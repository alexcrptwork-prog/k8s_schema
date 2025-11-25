# Kubernetes Service Topology Visualizer (Star Wars Theme)

This repository contains tools to visualize Kubernetes service topologies with a Star Wars theme. The tools analyze your cluster and generate visual diagrams showing service interactions, unhealthy pods, and Keycloak dependencies.

## Tools

### 1. Graphviz-based Visualizer (`k8s_starwars_topology.py`)

Generates a PNG diagram using Graphviz with orthogonal layout.

**Features:**
- Star Wars themed terminal output
- Service interaction visualization
- Keycloak-related services highlighted
- Unhealthy pods marked with status reasons
- Orthogonal (right-angle) connection lines
- Port and protocol information on connections

**Requirements:**
- Python 3.x
- `graphviz` Python package
- System `graphviz` package (with `dot` command)
- `kubectl` configured to access a Kubernetes cluster

**Installation:**
```bash
# Install Python package
pip install graphviz

# Install system graphviz (Ubuntu/Debian)
sudo apt-get install graphviz

# Install system graphviz (macOS)
brew install graphviz
```

**Usage:**
```bash
python k8s_starwars_topology.py
```

### 2. Draw.io Visualizer (`k8s_starwars_topology_drawio.py`)

Generates a draw.io XML file that can be opened in draw.io(diagrams.net) with all the same features.

**Features:**
- Same Star Wars themed analysis as the Graphviz version
- Generates `.drawio` XML file
- Compatible with draw.io(diagrams.net) editor
- Editable and customizable diagrams
- All styling preserved (Keycloak highlighting, unhealthy pod indicators)

**Requirements:**
- Python 3.x
- `kubectl` configured to access a Kubernetes cluster

**Usage:**
```bash
python k8s_starwars_topology_drawio.py
```

## Output Files

Both tools generate:
- Diagram file (PNG for Graphviz version, XML for draw.io version) with timestamp
- `GALACTIC_LOG_YYYYMMDD_HHMMSS.txt` with detailed scan information

## Visualization Elements

- **Services**: Rectangles with service name and namespace
- **Keycloak/Auth services**: Dark orange background with orange border
- **Unhealthy pods**: Red ellipses with status and reason
- **Connections**: Arrows showing source → destination port and protocol (HTTP/HTTPS)
- **Orthogonal layout**: Clean, non-crossing connections

## Customization

Both scripts can be customized by modifying:
- Color scheme
- Layout algorithms
- Service detection patterns
- Output formats

## Security Notice

This tool uses `kubectl` to access your Kubernetes cluster. Ensure you have appropriate permissions and that the tool is used in accordance with your organization's security policies.