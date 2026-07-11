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
