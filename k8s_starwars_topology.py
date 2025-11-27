#!/usr/bin/env python3
"""
Kubernetes Service Topology Visualizer - Star Wars Theme
Generates a graphviz diagram of service interactions in a Kubernetes cluster
with a Galactic Empire aesthetic.
"""

import subprocess
import json
import graphviz
import re
import sys
import os
from datetime import datetime
import tempfile

# ANSI Color codes for Star Wars theme
COLORS = {
    'white': '\033[97m',
    'orange': '\033[38;5;208m',  # Orange for alerts
    'gray': '\033[90m',
    'light_gray': '\033[37m',
    'reset': '\033[0m'
}

def print_star_wars_header():
    """Print the Star Wars themed header"""
    print("┌──────────────────────────────────────────────────────┐")
    print("│          GALACTIC EMPIRE CLUSTER TOPOLOGY            │")
    print("│              INTELLIGENCE BRIEFING                    │")
    print("└──────────────────────────────────────────────────────┘")
    print(f"{COLORS['orange']}SECURITY CLEARANCE: COMMAND LEVEL OMEGA{COLORS['reset']}")
    print(f"{COLORS['light_gray']}ANALYZING KUBERNETES BATTLE NETWORK...{COLORS['reset']}")
    print("────────────────────────────────────────────────────────────")

def run_kubectl_command(cmd):
    """Execute kubectl command and return JSON output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"{COLORS['orange']}> IMPERIAL ALERT: kubectl command failed: {cmd}{COLORS['reset']}")
        print(f"Error: {e.stderr}")
        return None
    except json.JSONDecodeError:
        print(f"{COLORS['orange']}> IMPERIAL ALERT: Could not parse JSON from command: {cmd}{COLORS['reset']}")
        return None

def extract_urls_from_config(config):
    """Extract service URLs from pod/container configuration"""
    urls = []
    config_str = json.dumps(config) if isinstance(config, dict) else str(config)
    
    # Pattern to match service URLs
    url_pattern = r'http[s]?://[a-zA-Z0-9\-.]+\.svc\.cluster\.local[:\d]*'
    matches = re.findall(url_pattern, config_str)
    
    for match in matches:
        urls.append(match)
    
    return urls

def get_pod_info():
    """Get information about all pods in all namespaces"""
    print(f"{COLORS['light_gray']}SCANNING FOR REBEL SERVICE DEPENDENCIES...{COLORS['reset']}")
    
    pods_data = run_kubectl_command("kubectl get pods --all-namespaces -o json")
    if not pods_data:
        return [], []
    
    pods = []
    unhealthy_pods = []
    
    for item in pods_data.get('items', []):
        metadata = item.get('metadata', {})
        spec = item.get('spec', {})
        status = item.get('status', {})
        
        pod_name = metadata.get('name', 'unknown')
        namespace = metadata.get('namespace', 'default')
        pod_phase = status.get('phase', 'Unknown')
        
        # Check container states
        container_statuses = status.get('containerStatuses', [])
        unhealthy = False
        status_reason = ""
        
        for container_status in container_statuses:
            if not container_status.get('ready', False):
                unhealthy = True
                if 'waiting' in container_status:
                    reason = container_status['waiting'].get('reason', 'Unknown')
                    status_reason = f"{reason}: {container_status['waiting'].get('message', '')}"
                elif 'terminated' in container_status:
                    reason = container_status['terminated'].get('reason', 'Terminated')
                    status_reason = f"{reason}: {container_status['terminated'].get('message', '')}"
        
        if pod_phase != 'Running' or unhealthy:
            unhealthy_pods.append({
                'name': pod_name,
                'namespace': namespace,
                'phase': pod_phase,
                'status_reason': status_reason
            })
        else:
            pods.append({
                'name': pod_name,
                'namespace': namespace,
                'owner': get_pod_owner(item),
                'containers': spec.get('containers', []),
                'status': status
            })
    
    return pods, unhealthy_pods

def get_pod_owner(pod_item):
    """Get the owner (Deployment, StatefulSet, etc.) of a pod"""
    owner_references = pod_item.get('metadata', {}).get('ownerReferences', [])
    if owner_references:
        return owner_references[0].get('name', 'Unknown')
    return 'Unknown'

def get_services():
    """Get information about all services in all namespaces"""
    services_data = run_kubectl_command("kubectl get services --all-namespaces -o json")
    if not services_data:
        return {}
    
    services = {}
    for item in services_data.get('items', []):
        metadata = item.get('metadata', {})
        spec = item.get('spec', {})
        
        service_name = metadata.get('name', 'unknown')
        namespace = metadata.get('namespace', 'default')
        service_type = spec.get('type', 'ClusterIP')
        
        ports = []
        for port in spec.get('ports', []):
            ports.append({
                'port': port.get('port', 0),
                'target_port': port.get('targetPort', 0),
                'protocol': port.get('protocol', 'TCP')
            })
        
        services[f"{service_name}.{namespace}"] = {
            'name': service_name,
            'namespace': namespace,
            'type': service_type,
            'ports': ports,
            'selector': spec.get('selector', {})
        }
    
    return services

def get_configmaps_and_secrets():
    """Get ConfigMaps and Secrets to extract URLs from them"""
    configmaps = run_kubectl_command("kubectl get configmaps --all-namespaces -o json")
    secrets = run_kubectl_command("kubectl get secrets --all-namespaces -o json")
    
    all_urls = []
    
    # Extract from ConfigMaps
    if configmaps:
        for item in configmaps.get('items', []):
            data = item.get('data', {})
            for key, value in data.items():
                all_urls.extend(extract_urls_from_config(value))
    
    # Extract from Secrets
    if secrets:
        for item in secrets.get('items', []):
            data = item.get('data', {})
            for key, value in data.items():
                # Decode base64 values
                try:
                    import base64
                    decoded = base64.b64decode(value).decode('utf-8')
                    all_urls.extend(extract_urls_from_config(decoded))
                except:
                    pass
    
    return all_urls

def analyze_pod_interactions(pods, services):
    """Analyze interactions between pods and services"""
    interactions = []
    keycloak_related = []
    
    for pod in pods:
        pod_name = pod['name']
        namespace = pod['namespace']
        
        # Check container environment variables and command arguments for URLs
        for container in pod['containers']:
            # Check environment variables
            env_vars = container.get('env', [])
            for env in env_vars:
                value = env.get('value', '')
                urls = extract_urls_from_config(value)
                for url in urls:
                    service_match = extract_service_from_url(url)
                    if service_match:
                        dest_service, dest_namespace, dest_port = service_match
                        full_service_name = f"{dest_service}.{dest_namespace}"
                        
                        if full_service_name in services:
                            # Find the source port from container ports
                            source_port = None
                            for port in container.get('ports', []):
                                if 'containerPort' in port:
                                    source_port = port['containerPort']
                                    break
                            
                            if source_port is None:
                                # Use default port if no container port is specified
                                source_port = 8080  # Default
                    
                            # Determine protocol
                            protocol = 'HTTPS' if 'https' in url.lower() else 'HTTP'
                            
                            interaction = {
                                'source': f"{pod_name}.{namespace}",
                                'source_port': source_port,
                                'destination': full_service_name,
                                'destination_port': dest_port,
                                'protocol': protocol
                            }
                            interactions.append(interaction)
                            
                            # Check if this is keycloak related
                            if 'keycloak' in dest_service.lower() or 'auth' in dest_service.lower():
                                keycloak_related.append(full_service_name)
    
    return interactions, keycloak_related

def extract_service_from_url(url):
    """Extract service name, namespace, and port from URL"""
    # Pattern: http://service.namespace.svc.cluster.local:port
    pattern = r'https?://([a-zA-Z0-9\-.]+)\.([a-zA-Z0-9\-.]+)\.svc\.cluster\.local(?::(\d+))?'
    match = re.search(pattern, url)
    
    if match:
        service_name = match.group(1)
        namespace = match.group(2)
        port = int(match.group(3)) if match.group(3) else 80  # Default to 80 for HTTP, 443 for HTTPS
        
        return service_name, namespace, port
    
    return None

def generate_topology_graph(interactions, services, unhealthy_pods, keycloak_related):
    """Generate the topology graph using graphviz"""
    print(f"{COLORS['light_gray']}GENERATING STRATEGIC TOPOLOGY MAP (ORTHOGONAL LAYOUT)...{COLORS['reset']}")
    
    dot = graphviz.Digraph(comment='Kubernetes Service Topology - Galactic Empire')
    dot.attr(rankdir='TB', splines='ortho', bgcolor='#121212', fontname='Consolas')
    dot.attr('node', shape='box', fontname='Consolas', fontsize='10')
    dot.attr('edge', fontname='Consolas', fontsize='8')
    
    # Add services to the graph
    for service_name, service_info in services.items():
        service, namespace = service_name.split('.', 1)
        
        # Check if this service is keycloak related
        if service_name in keycloak_related:
            dot.node(service_name, 
                    label=f"{service}\\n({namespace})",
                    style='filled', 
                    fillcolor='#4A1500', 
                    color='#FF8C00', 
                    fontcolor='white',
                    shape='box')
        else:
            dot.node(service_name, 
                    label=f"{service}\\n({namespace})",
                    style='filled', 
                    fillcolor='#2D2D2D', 
                    fontcolor='white',
                    shape='box')
    
    # Add unhealthy pods as separate nodes
    for pod in unhealthy_pods:
        pod_node_name = f"unhealthy_{pod['name']}.{pod['namespace']}"
        dot.node(pod_node_name,
                label=f"UNHEALTHY: {pod['name']}\\n({pod['namespace']})\\nStatus: {pod['phase']}\\n{pod['status_reason'][:50]}...",
                style='filled', 
                fillcolor='#8B0000', 
                fontcolor='white',
                shape='ellipse')
    
    # Add interactions (edges) between services
    for interaction in interactions:
        source = interaction['source']
        dest = interaction['destination']
        source_port = interaction['source_port']
        dest_port = interaction['destination_port']
        protocol = interaction['protocol']
        
        # Add edge with port and protocol info
        dot.edge(source, dest,
                label=f"{source_port} → {dest_port}\\n({protocol})",
                color='white',
                fontcolor='white')
    
    return dot

def save_log(log_content):
    """Save the log to a file with timestamp"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_filename = f"GALACTIC_LOG_{timestamp}.txt"
    
    with open(log_filename, 'w') as f:
        f.write(log_content)
    
    return log_filename

def main():
    print_star_wars_header()
    
    # Initialize log content
    log_content = f"GALACTIC EMPIRE CLUSTER TOPOLOGY LOG\n"
    log_content += f"Generated on: {datetime.now()}\n"
    log_content += "="*50 + "\n"
    
    try:
        # Get pods and services
        pods, unhealthy_pods = get_pod_info()
        services = get_services()
        
        log_content += f"Found {len(pods)} healthy pods and {len(unhealthy_pods)} unhealthy pods\n"
        log_content += f"Found {len(services)} services\n"
        
        # Analyze interactions
        interactions, keycloak_related = analyze_pod_interactions(pods, services)
        
        log_content += f"Found {len(interactions)} service interactions\n"
        log_content += f"Found {len(keycloak_related)} keycloak-related services\n"
        
        # Generate the graph
        dot = generate_topology_graph(interactions, services, unhealthy_pods, keycloak_related)
        
        # Save the graph
        output_filename = "k8s_starwars_topology"
        dot.render(output_filename, format='png', cleanup=True)
        
        # Save log
        log_filename = save_log(log_content)
        
        print(f"{COLORS['white']}✅ STRATEGIC MAP COMPLETE: {output_filename}.png{COLORS['reset']}")
        
        if keycloak_related:
            print(f"{COLORS['orange']}⚠️  REBEL ACTIVITY DETECTED: {len(keycloak_related)} UNIT(S) LINKED TO AUTHENTICATION HUB (KEYCLOAK){COLORS['reset']}")
        
        if unhealthy_pods:
            print(f"{COLORS['orange']}⚠️  IMPERIAL ALERT: {len(unhealthy_pods)} UNHEALTHY POD(S) DETECTED{COLORS['reset']}")
        
        print("────────────────────────────────────────────────────────────")
        print(f"{COLORS['light_gray']}TOPOLOGY BRIEFING CONCLUDED{COLORS['reset']}")
        print(f"{COLORS['light_gray']}AWAITING FURTHER ORDERS FROM COMMAND...{COLORS['reset']}")
        
    except KeyboardInterrupt:
        print(f"\n{COLORS['orange']}> MISSION ABORTED BY COMMAND{COLORS['reset']}")
        sys.exit(1)
    except Exception as e:
        print(f"{COLORS['orange']}> IMPERIAL SYSTEM ERROR: {str(e)}{COLORS['reset']}")
        sys.exit(1)

if __name__ == "__main__":
    main()