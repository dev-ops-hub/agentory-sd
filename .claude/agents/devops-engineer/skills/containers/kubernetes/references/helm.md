# Helm

## Chart Structure

```
mychart/
  Chart.yaml
  values.yaml           # defaults
  values-staging.yaml   # staging overrides
  values-prod.yaml       # prod overrides
  templates/
    deployment.yaml
    service.yaml
    ingress.yaml
    _helpers.tpl         # named template snippets
```

```bash
helm upgrade --install app ./mychart -f values.yaml -f values-prod.yaml --namespace prod
```

Layer environment-specific values files over a shared base rather than maintaining fully separate per-environment chart copies — divergence between environments then shows up as a small values diff, not a hunt through duplicated templates.

## Templating

```yaml
# templates/deployment.yaml
replicas: {{ .Values.replicaCount | default 2 }}
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
{{- if .Values.resources }}
resources:
{{ toYaml .Values.resources | indent 2 }}
{{- end }}
```

Use `{{- ... -}}` whitespace control to avoid producing malformed YAML from template conditionals — a common source of "Helm renders invalid YAML" bugs is a stray blank line left by an unconditioned `{{ if }}` block.

## Validating Before Install

```bash
helm template ./mychart -f values-prod.yaml | kubectl apply --dry-run=client -f -
helm lint ./mychart
```

`helm template` renders the manifests without touching the cluster — review the actual rendered YAML, not just the template source, since template logic bugs only show up in the output.

## Dependencies

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "13.x.x"
    repository: "https://charts.bitnami.com/bitnami"
```

Pin dependency chart versions the same way application dependencies are pinned — an unconstrained version range on a dependency chart can silently change behavior on the next `helm dependency update`.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Separate full chart copies per environment | One chart, layered values files |
| Installing without `helm template`/`lint` first | Render and inspect before applying to a shared cluster |
| Unconstrained dependency chart version | Pin to a specific version or narrow range |
