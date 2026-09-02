# Azure Load Balancer vs Application Gateway

The TechSprint implementation uses an **Internal Azure Load Balancer**.

## Azure Load Balancer

Azure Load Balancer operates primarily at Layer 4 and distributes TCP/UDP traffic between backend instances.

Advantages for TechSprint:

- simple architecture
- internal/private frontend
- health probes
- lower complexity
- suitable for distributing HTTP traffic between two Moodle nodes

## Azure Application Gateway

Application Gateway operates at Layer 7 and provides additional HTTP/HTTPS functionality such as:

- URL-based routing
- host-based routing
- TLS termination
- Web Application Firewall
- HTTP-aware routing

## Decision

Application Gateway would be appropriate for a production Moodle deployment requiring advanced HTTP routing, TLS termination or WAF protection.

For the TechSprint testing environment these features are not required. An Internal Azure Load Balancer provides the required traffic distribution and health checking with a simpler architecture.
