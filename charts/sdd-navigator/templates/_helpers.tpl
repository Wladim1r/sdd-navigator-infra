{{/*
@req SCI-HELM-006
Umbrella chart helpers — shared labels for ingress and top-level resources
*/}}
{{- define "sdd-navigator.name" -}}
{{- .Chart.Name }}
{{- end }}

{{- define "sdd-navigator.fullname" -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "sdd-navigator.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{ include "sdd-navigator.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "sdd-navigator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sdd-navigator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
