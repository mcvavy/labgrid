{{/*
Expand the name of the chart.
*/}}
{{- define "tdai-memory.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "tdai-memory.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "tdai-memory.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "tdai-memory.labels" -}}
helm.sh/chart: {{ include "tdai-memory.chart" . }}
{{ include "tdai-memory.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "tdai-memory.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tdai-memory.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "tdai-memory.core.fullname" -}}
{{- printf "%s-core" (include "tdai-memory.fullname" .) }}
{{- end }}

{{- define "tdai-memory.hub.fullname" -}}
{{- printf "%s-hub" (include "tdai-memory.fullname" .) }}
{{- end }}

{{- define "tdai-memory.core.labels" -}}
{{ include "tdai-memory.labels" . }}
app.kubernetes.io/component: core
{{- end }}

{{- define "tdai-memory.hub.labels" -}}
{{ include "tdai-memory.labels" . }}
app.kubernetes.io/component: hub
{{- end }}

{{- define "tdai-memory.core.selectorLabels" -}}
{{ include "tdai-memory.selectorLabels" . }}
app.kubernetes.io/component: core
{{- end }}

{{- define "tdai-memory.hub.selectorLabels" -}}
{{ include "tdai-memory.selectorLabels" . }}
app.kubernetes.io/component: hub
{{- end }}

{{- define "tdai-memory.secrets.name" -}}
{{- default (printf "%s-credentials" (include "tdai-memory.fullname" .)) .Values.externalSecrets.targetSecretName }}
{{- end }}

{{- define "tdai-memory.backup.fullname" -}}
{{- printf "%s-backup" (include "tdai-memory.fullname" .) }}
{{- end }}

{{- define "tdai-memory.backup.secretName" -}}
{{- default (printf "%s-backup-credentials" (include "tdai-memory.fullname" .)) .Values.backup.externalSecret.targetSecretName }}
{{- end }}

{{- define "tdai-memory.backup.labels" -}}
{{ include "tdai-memory.labels" . }}
app.kubernetes.io/component: backup
{{- end }}
