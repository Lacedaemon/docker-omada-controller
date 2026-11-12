{{/*
Expand the name of the chart.
*/}}
{{- define "omada-controller.name" -}}
{{- default (.Chart.Name | trimSuffix "-helm") .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "omada-controller.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default (.Chart.Name | trimSuffix "-helm") .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Fully qualified app name with a suffix appended (e.g. the "-device" Service).
The base fullname is truncated at 56 chars so the suffix still fits inside the
63 char limit for Kubernetes names.
Call it with a dict carrying the base fullname and the suffix:
  include "omada-controller.fullnameWithSuffix" (dict "fullname" (include "omada-controller.fullname" .) "suffix" "-device")
*/}}
{{- define "omada-controller.fullnameWithSuffix" -}}
{{- printf "%s%s" (.fullname | trunc 56 | trimSuffix "-") .suffix | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "omada-controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "omada-controller.labels" -}}
helm.sh/chart: {{ include "omada-controller.chart" . }}
{{ include "omada-controller.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "omada-controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "omada-controller.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "omada-controller.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "omada-controller.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Split decision (single source of truth, used by service.yaml and NOTES.txt):
render the split Web GUI + "-device" Services ONLY when the user opts in, i.e.
the effective web and device Service types differ (an empty per-Service type
falls back to the top-level service.type), or any per-Service labels/annotations
are set. Otherwise the chart renders the single merged Service, byte-identical
in ports/labels/selector to the 1.7.x behavior. Evaluates to "true"/"false".
*/}}
{{- define "omada-controller.servicesSplit" -}}
{{- $webType := .Values.service.web.type | default .Values.service.type -}}
{{- $deviceType := .Values.service.device.type | default .Values.service.type -}}
{{- $extraPerService := or (not (empty .Values.service.web.labels)) (not (empty .Values.service.web.annotations)) (not (empty .Values.service.device.labels)) (not (empty .Values.service.device.annotations)) -}}
{{- if ne $webType $deviceType -}}
true
{{- else if $extraPerService -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{/*
Web GUI port block: management portal + captive portal HTTP/HTTPS ports.
Guards copied VERBATIM from the 1.7.x service.yaml so the merged and split
render paths can never drift. Invoke with root context: include "omada-controller.serviceWebPorts" .
*/}}
{{- define "omada-controller.serviceWebPorts" }}
  - name: manage-https
    port: {{ .Values.config.ports.manageHttps }}
    targetPort: manage-https
  - name: manage-http
    port: {{ .Values.config.ports.manageHttp }}
    targetPort: manage-http
  - name: portal-https
    port: {{ .Values.config.ports.portalHttps }}
    targetPort: portal-https
  {{- if ne (int .Values.config.ports.portalHttp) (int .Values.config.ports.manageHttp) }}
  - name: portal-http
    port: {{ .Values.config.ports.portalHttp }}
    targetPort: portal-http
  {{- end }}
{{- end -}}

{{/*
Device port block: every port Omada devices talk to the controller on.
Guards copied VERBATIM from the 1.7.x service.yaml. Invoke with root context:
include "omada-controller.serviceDevicePorts" .
*/}}
{{- define "omada-controller.serviceDevicePorts" }}
  {{- if and .Values.config.ports.upgradeHttps (ne (int .Values.config.ports.upgradeHttps) (int .Values.config.ports.manageHttps)) }}
  - name: upgrade-https
    port: {{ .Values.config.ports.upgradeHttps }}
    targetPort: upgrade-https
  {{- end }}
  {{- if and (ne (int .Values.config.ports.upgradeEsHttps) (int .Values.config.ports.manageHttps)) (ne (int .Values.config.ports.upgradeEsHttps) (int .Values.config.ports.upgradeHttps)) }}
  - name: upgrade-eshttps
    port: {{ .Values.config.ports.upgradeEsHttps }}
    targetPort: upgrade-eshttps
  {{- end }}
  - name: app-discovery
    port: {{ .Values.config.ports.appDiscovery }}
    targetPort: app-discovery
    protocol: UDP
  - name: adopt-v1
    port: {{ .Values.config.ports.adoptV1 }}
    targetPort: adopt-v1
  - name: upgrade-v1
    port: {{ .Values.config.ports.upgradeV1 }}
    targetPort: upgrade-v1
  - name: manager-v1
    port: {{ .Values.config.ports.managerV1 }}
    targetPort: manager-v1
  - name: manager-v2
    port: {{ .Values.config.ports.managerV2 }}
    targetPort: manager-v2
  - name: udp-discovery
    port: {{ .Values.config.ports.discovery }}
    targetPort: udp-discovery
    protocol: UDP
  - name: udp-management
    port: {{ .Values.config.ports.udpManagement }}
    targetPort: udp-management
    protocol: UDP
  - name: transfer-v2
    port: {{ .Values.config.ports.transferV2 }}
    targetPort: transfer-v2
  - name: rtty
    port: {{ .Values.config.ports.rtty }}
    targetPort: rtty
  - name: device-monitor
    port: {{ .Values.config.ports.deviceMonitor }}
    targetPort: device-monitor
{{- end -}}
