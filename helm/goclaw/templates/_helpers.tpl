{{/*
Expand the name of the chart.
*/}}
{{- define "goclaw.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "goclaw.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "goclaw.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "goclaw.labels" -}}
helm.sh/chart: {{ include "goclaw.chart" . }}
{{ include "goclaw.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "goclaw.selectorLabels" -}}
app.kubernetes.io/name: {{ include "goclaw.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "goclaw.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "goclaw.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
UI fullname
*/}}
{{- define "goclaw.ui.fullname" -}}
{{- printf "%s-ui" (include "goclaw.fullname" .) }}
{{- end }}

{{/*
UI labels
*/}}
{{- define "goclaw.ui.labels" -}}
helm.sh/chart: {{ include "goclaw.chart" . }}
{{ include "goclaw.ui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
UI selector labels
*/}}
{{- define "goclaw.ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "goclaw.name" . }}-ui
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: ui
{{- end }}

{{/*
Chrome fullname
*/}}
{{- define "goclaw.chrome.fullname" -}}
{{- printf "%s-chrome" (include "goclaw.fullname" .) }}
{{- end }}

{{/*
Chrome labels
*/}}
{{- define "goclaw.chrome.labels" -}}
helm.sh/chart: {{ include "goclaw.chart" . }}
{{ include "goclaw.chrome.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Chrome selector labels
*/}}
{{- define "goclaw.chrome.selectorLabels" -}}
app.kubernetes.io/name: {{ include "goclaw.name" . }}-chrome
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: chrome
{{- end }}

{{/*
pgvector subchart service name — follows Helm subchart naming: <release>-pgvector
*/}}
{{- define "goclaw.pgvector.fullname" -}}
{{- printf "%s-pgvector" .Release.Name }}
{{- end }}

{{/*
pgvector auth secret name.
We create this Secret ourselves (with lookup-based password persistence)
and tell the subchart to use it via existingSecret.
Must match pgvector.postgresql.existingSecret.name in values.yaml.
*/}}
{{- define "goclaw.pgvector.secretName" -}}
{{- printf "%s-pgvector-auth" (include "goclaw.fullname" .) }}
{{- end }}

{{/*
Jaeger fullname
*/}}
{{- define "goclaw.jaeger.fullname" -}}
{{- printf "%s-jaeger" (include "goclaw.fullname" .) }}
{{- end }}

{{/*
Name of the Secret that holds GOCLAW_POSTGRES_DSN (externalDatabase only).
pgvector DSN is assembled via env-var expansion — no dedicated DSN secret needed.
*/}}
{{- define "goclaw.postgresSecretName" -}}
{{- if .Values.externalDatabase.enabled }}
  {{- if .Values.externalDatabase.existingSecret }}
    {{- .Values.externalDatabase.existingSecret }}
  {{- else }}
    {{- printf "%s-postgres" (include "goclaw.fullname" .) }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Shell fragment that exports GOCLAW_POSTGRES_DSN from individual PG* env vars.
Use inside "sh -c" command to guarantee password expansion at runtime.
*/}}
{{- define "goclaw.pgvectorDsnExport" -}}
{{- $host := include "goclaw.pgvector.fullname" . }}
{{- $port := .Values.pgvector.service.port | default 5432 }}
{{- $user := .Values.pgvector.postgresql.username | default "goclaw" }}
{{- $db := .Values.pgvector.postgresql.database | default "goclaw" }}
export GOCLAW_POSTGRES_DSN="postgres://{{ $user }}:${POSTGRES_PASSWORD}@{{ $host }}:{{ $port }}/{{ $db }}?sslmode=disable"
{{- end }}

{{/*
Redis DSN - constructs the connection string
*/}}
{{- define "goclaw.redisDsn" -}}
{{- if .Values.redis.enabled }}
{{- $host := printf "%s-redis-master" .Release.Name }}
{{- printf "redis://:%s@%s:6379/0" "$(REDIS_PASSWORD)" $host }}
{{- end }}
{{- end }}

{{/*
Redis password secret name
*/}}
{{- define "goclaw.redisSecretName" -}}
{{- if .Values.redis.auth.existingSecret }}
{{- .Values.redis.auth.existingSecret }}
{{- else }}
{{- printf "%s-redis" .Release.Name }}
{{- end }}
{{- end }}

{{/*
Gateway token secret name
*/}}
{{- define "goclaw.gatewayTokenSecretName" -}}
{{- if .Values.gateway.existingTokenSecret }}
{{- .Values.gateway.existingTokenSecret }}
{{- else }}
{{- printf "%s-gateway" (include "goclaw.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Encryption key secret name
*/}}
{{- define "goclaw.encryptionKeySecretName" -}}
{{- if .Values.gateway.existingEncryptionKeySecret }}
{{- .Values.gateway.existingEncryptionKeySecret }}
{{- else }}
{{- printf "%s-gateway" (include "goclaw.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Tailscale secret name
*/}}
{{- define "goclaw.tailscaleSecretName" -}}
{{- if .Values.tailscale.existingSecret }}
{{- .Values.tailscale.existingSecret }}
{{- else }}
{{- printf "%s-tailscale" (include "goclaw.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Image for gateway
*/}}
{{- define "goclaw.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}
