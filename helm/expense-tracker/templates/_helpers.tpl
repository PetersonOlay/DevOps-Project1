{{/* Name/label helpers for the backend resources (suffixed with config.appEnv). */}}
{{- define "expense-tracker.name" -}}
{{- .Chart.Name -}}-{{- .Values.config.appEnv -}}
{{- end -}}

{{- define "expense-tracker.labels" -}}
app.kubernetes.io/name: {{ include "expense-tracker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app: {{ include "expense-tracker.name" . }}
{{- end -}}

{{- define "expense-tracker.selectorLabels" -}}
app: {{ include "expense-tracker.name" . }}
{{- end -}}

{{/* Same, but for backend-specific resources (Deployment, Service, ConfigMap,
     HPA, migration Job, SecretStore, ExternalSecret) — kept separate from
     "expense-tracker.name" above, which the shared Ingress still uses for its
     own identity so renaming backend resources never touches the Ingress
     (and therefore never orphans its ALB). */}}
{{- define "expense-tracker.backend.name" -}}
{{- .Chart.Name -}}-{{- .Values.config.appEnv -}}-backend
{{- end -}}

{{- define "expense-tracker.backend.labels" -}}
app.kubernetes.io/name: {{ include "expense-tracker.backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app: {{ include "expense-tracker.backend.name" . }}
{{- end -}}

{{- define "expense-tracker.backend.selectorLabels" -}}
app: {{ include "expense-tracker.backend.name" . }}
{{- end -}}

{{/* Same, but for the frontend resources — kept separate so their selector
     labels never collide with the backend's. */}}
{{- define "expense-tracker.frontend.name" -}}
{{- .Chart.Name -}}-{{- .Values.config.appEnv -}}-frontend
{{- end -}}

{{- define "expense-tracker.frontend.labels" -}}
app.kubernetes.io/name: {{ include "expense-tracker.frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app: {{ include "expense-tracker.frontend.name" . }}
{{- end -}}

{{- define "expense-tracker.frontend.selectorLabels" -}}
app: {{ include "expense-tracker.frontend.name" . }}
{{- end -}}
