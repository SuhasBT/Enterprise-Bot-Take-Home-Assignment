## Q1: Migrating ingress-nginx → Gateway API

- **Assessment phase**
  - Inventory all ~40 existing Ingress objects and their annotations.
  - Identify features that are ingress‑nginx specific (e.g. rewrite rules, TLS annotations, custom load balancing).
  - Map each Ingress to its equivalent Gateway API resources (Gateway + HTTPRoute).

- **Preparation**
  - Deploy a Gateway API controller (e.g. Istio, Envoy Gateway, or Kubernetes SIG implementation) alongside ingress‑nginx in the same cluster.
  - Create Gateway + HTTPRoute manifests in staging, validate routing behaviour against current ingress rules.
  - Automate conversion where possible, but manually review complex cases.

- **Migration order**
  - Start with low‑risk services (internal apps, non‑critical endpoints).
  - Gradually roll out Gateway API routes in parallel with existing ingress‑nginx.
  - Use DNS or service mesh routing to shift traffic incrementally.
  - Monitor latency, error rates, and TLS behaviour during cutover.

- **Expected breakages / risks**
  - Loss of ingress‑nginx specific annotations (rate limiting, custom headers).
  - Differences in TLS configuration and certificate management.
  - Path matching semantics may differ (prefix vs exact).
  - Third‑party integrations relying on ingress‑nginx metrics/logging may break.
  - Operational tooling (dashboards, alerts) must be updated to Gateway API.

- **Fallback**
  - Keep ingress‑nginx running until all critical routes are stable.
  - Maintain rollback plan: revert DNS to ingress‑nginx if Gateway API fails.
