{{- define "etcd.name" -}}
{{- .Chart.Name -}}
{{- end }}

{{- define "etcd.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}
