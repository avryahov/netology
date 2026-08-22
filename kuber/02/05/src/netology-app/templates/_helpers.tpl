{{- define "netology-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- define "netology-app.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "netology-app.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
