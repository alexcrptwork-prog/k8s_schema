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

# GitLab Keycloak Configuration Search Script

This script is designed to search through GitLab repositories for Keycloak configuration files and save the findings in JSON format.

## Script Functionality

The script `search_keycloak_repos.sh` does the following:

1. Uses the GitLab API to fetch all accessible projects
2. Searches through each project's files for potential Keycloak configurations
3. Looks for files with extensions like `.yml`, `.yaml`, `.json`, `.js`, `.ts`, `.java`, `.properties`, `.xml`, `.env`, `.conf`, `.config`
4. Also searches files with names containing `config`, `application`, `settings`, `auth`, `security`, `keycloak`, `oauth`, `sso`
5. Checks file contents for Keycloak-related keywords like `keycloak`, `auth-server-url`, `realm`, `client.id`, `oidc`, `sso`, `oauth`, `openid`, etc.
6. Outputs results in JSON format with:
   - Project name
   - Repository URL
   - File names containing Keycloak configurations
   - URLs to the files in GitLab

## Issue Encountered

When running the script, we encountered an HTTP 445 response code from the GitLab API, which is a non-standard HTTP status code. This indicates there's an access issue with the provided token or GitLab instance configuration.

Possible reasons:
- The token `glpat-iHuevLsAqjBtOKv3Kh7WNW86MQp1OmF4CA.01.0y1ah4wbu` may be invalid or expired
- The GitLab instance at `https://gl.webmonitorx.ru` may have special access restrictions
- Network connectivity issues
- The token may not have sufficient permissions to access the projects

## Usage

To use this script with a working GitLab token:

```bash
chmod +x search_keycloak_repos.sh
./search_keycloak_repos.sh
```

The results will be saved in `keycloak_repos.json`.

## Expected Output Format

```json
[
  {
    "project_name": "project-name",
    "repository_url": "https://gl.webmonitorx.ru/project-name",
    "keycloak_files": ["path/to/config.yml", "path/to/application.properties"],
    "file_urls": ["https://gl.webmonitorx.ru/project-name/-/blob/main/path/to/config.yml", "https://gl.webmonitorx.ru/project-name/-/blob/main/path/to/application.properties"]
  }
]
```

## Troubleshooting

If you encounter access issues:
1. Verify the GitLab token is valid and has appropriate permissions
2. Check that the GitLab URL is correct
3. Ensure the network connection allows access to the GitLab instance
4. Verify that the projects are accessible with the provided token