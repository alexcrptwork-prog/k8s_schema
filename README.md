# Kubernetes Service Topology Visualizer - Star Wars Theme

This script analyzes a Kubernetes cluster and generates a visual representation of service interactions with a Star Wars/Galactic Empire theme.

## Features

- Analyzes Kubernetes cluster services, pods, and their interactions
- Identifies service dependencies and communication paths
- Highlights Keycloak-related services
- Marks unhealthy pods
- Generates a visual topology diagram with orthogonal layout
- Creates a log file with scan details
- Star Wars-themed interface with appropriate color scheme

## Requirements

- Python 3.6+
- `kubectl` configured to access a Kubernetes cluster
- `graphviz` system package (for the `dot` command)
- Python `graphviz` package

## Installation

```bash
# Install system dependencies
sudo apt-get install graphviz

# Install Python dependencies
pip install graphviz
```

## Usage

```bash
python3 k8s_starwars_topology.py
```

## Output

- `k8s_starwars_topology.png` - The visual topology diagram
- `GALACTIC_LOG_YYYYMMDD_HHMMSS.txt` - Log file with scan details

## Diagram Features

- Services displayed as boxes with namespace
- Keycloak-related services highlighted with orange border and dark orange background
- Unhealthy pods shown as separate red ellipses with status information
- Edges show port mappings and protocol (HTTP/HTTPS)
- Orthogonal layout for clean presentation
- Dark theme with Consolas font

## Example Output

The script will display a Star Wars-themed interface like:

```
┌──────────────────────────────────────────────────────┐
│          GALACTIC EMPIRE CLUSTER TOPOLOGY            │
│              INTELLIGENCE BRIEFING                    │
└──────────────────────────────────────────────────────┘
SECURITY CLEARANCE: COMMAND LEVEL OMEGA
ANALYZING KUBERNETES BATTLE NETWORK...
────────────────────────────────────────────────────────────
SCANNING FOR REBEL SERVICE DEPENDENCIES...
GENERATING STRATEGIC TOPOLOGY MAP (ORTHOGONAL LAYOUT)...
✅ STRATEGIC MAP COMPLETE: k8s_starwars_topology.png
⚠️  REBEL ACTIVITY DETECTED: 2 UNIT(S) LINKED TO AUTHENTICATION HUB (KEYCLOAK)
────────────────────────────────────────────────────────────
TOPOLOGY BRIEFING CONCLUDED
AWAITING FURTHER ORDERS FROM COMMAND...
> Enter to exit...
```