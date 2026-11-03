{{- define "course-policies.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ .Chart.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "course-policies.studentNamespaces" -}}
{{- range .Values.students }}
- {{ .namespace }}
{{- end }}
{{- end }}
