# Specifica Modifiche Modulo Terraform GitLab Kubernetes Agent

## Obiettivo
Modificare il modulo per gestire il comportamento del GitLab agent in modo diverso a seconda che si operi a livello di root group o meno, semplificando la configurazione con un toggle unico e introducendo comportamenti automatici intelligenti.

## Requisiti Funzionali

### 1. Toggle Unico per Root Group
- **Rimuovere** le variabili separate:
  - `gitlab_agent_grant_access_to_entire_root_namespace`
  - `gitlab_agent_create_variables_in_root_namespace`
- **Introdurre** una nuova variabile booleana unica (es. `operate_at_root_group_level` o `is_root_group_scope`)

### 2. Comportamento se in Root Group
Quando `operate_at_root_group_level == true`:
- File di configurazione automaticamente gestito
- Variabili CI/CD create sul root group
- Comportamento identico all'attuale implementazione

### 3. Comportamento se NON in Root Group
Quando `operate_at_root_group_level == false`:

#### 3.1 Nessun gruppo o progetto specificato
Se `length(concat(groups_enabled, projects_enabled)) == 0`:
- Recuperare automaticamente il parent DIRETTO del progetto specificato in `gitlab_project_path_with_namespace`
- Trattare questo parent come l'UNICO elemento di `groups_enabled`
- **Nota**: Il parent potrebbe essere un root group - verificare e gestire questo caso

#### 3.2 Gruppi o progetti specificati
Se sono specificati gruppi o progetti:
- Creare file di configurazione solo per quei gruppi/progetti specifici
- Creare variabili CI/CD in quei gruppi/progetti specifici (non nel root)

---

## Piano di Implementazione

### 1. Modifiche alle Variabili (variables.tf)

#### Variabili da Rimuovere
- `gitlab_agent_grant_access_to_entire_root_namespace`
- `gitlab_agent_create_variables_in_root_namespace`

#### Variabili da Aggiungere
```terraform
variable "operate_at_root_group_level" {
  description = "Operate at root group level. If true, grants access to entire root namespace and creates variables in root group. If false, behavior depends on groups_enabled and projects_enabled."
  type        = bool
  default     = true
}

variable "groups_enabled" {
  description = "List of group IDs or paths where the GitLab Agent should be enabled. Only used when operate_at_root_group_level is false. If empty and projects_enabled is also empty, the parent group of the agent project will be used automatically."
  type        = list(string)
  default     = []
}

variable "projects_enabled" {
  description = "List of project IDs or paths where the GitLab Agent should be enabled. Only used when operate_at_root_group_level is false. If empty and groups_enabled is also empty, the parent group of the agent project will be used automatically."
  type        = list(string)
  default     = []
}
```

#### Validazioni da Aggiungere
- Verificare coerenza tra `operate_at_root_group_level` e uso di `gitlab_agent_custom_config_file_content`
- Validare che gruppi/progetti specificati esistano (dove possibile)

### 2. Modifiche ai Locals (main.tf)

#### Nuovi Locals da Aggiungere

```terraform
# Determina il parent group del progetto
parent_group_path = join("/", slice(split("/", var.gitlab_project_path_with_namespace), 0, length(split("/", var.gitlab_project_path_with_namespace)) - 1))

# Determina se siamo in modalità auto-parent
auto_detect_parent = !var.operate_at_root_group_level && length(concat(var.groups_enabled, var.projects_enabled)) == 0

# Lista finale di gruppi da abilitare
groups_to_enable = var.operate_at_root_group_level ? [local.project_root_namespace] : (
  local.auto_detect_parent ? [local.parent_group_path] : var.groups_enabled
)

# Lista finale di progetti da abilitare
projects_to_enable = var.operate_at_root_group_level ? [] : (
  local.auto_detect_parent ? [] : var.projects_enabled
)
```

#### Local da Modificare

```terraform
# final_configuration_file_content
# Deve essere modificato per gestire:
# - Root group: comportamento attuale (template con root_namespace)
# - Non-root con gruppi/progetti: generare config dinamico con yamlencode() o nuovo template
# - Considerare se mantenerlo vuoto quando custom_config è specificato
```

### 3. Data Source Aggiuntivi

#### Per il Parent Group (quando auto-detect)
```terraform
data "gitlab_group" "parent_group" {
  count     = local.auto_detect_parent ? 1 : 0
  full_path = local.parent_group_path
}
```

#### Per i Gruppi Specificati
```terraform
data "gitlab_group" "enabled_groups" {
  for_each  = !var.operate_at_root_group_level ? toset(var.groups_enabled) : toset([])
  full_path = each.value
}
```

#### Per i Progetti Specificati
```terraform
data "gitlab_project" "enabled_projects" {
  for_each            = !var.operate_at_root_group_level ? toset(var.projects_enabled) : toset([])
  path_with_namespace = each.value
}
```

### 4. Modifiche alle Risorse (main.tf)

#### Risorsa gitlab_repository_file.this
- Mantenere la logica attuale per root group
- Per non-root-group: generare il file solo se ci sono gruppi/progetti da abilitare
- Modificare il contenuto in base ai gruppi/progetti target

#### Risorsa gitlab_group_variable.this
**Sostituire con logica condizionale:**

```terraform
# Variabili per root group (comportamento attuale)
resource "gitlab_group_variable" "root_namespace" {
  for_each = var.operate_at_root_group_level ? local.gitlab_agent_kubernetes_context_variables : {}
  # ... resto della configurazione
}

# Variabili per gruppi specifici (non-root-group)
resource "gitlab_group_variable" "enabled_groups" {
  for_each = !var.operate_at_root_group_level && length(local.groups_to_enable) > 0 ? {
    for pair in setproduct(keys(local.gitlab_agent_kubernetes_context_variables), local.groups_to_enable) :
    "${pair[1]}_${pair[0]}" => {
      group = pair[1]
      key   = pair[0]
      value = local.gitlab_agent_kubernetes_context_variables[pair[0]]
    }
  } : {}
  # ... resto della configurazione
}

# Variabili per progetti specifici (non-root-group)
resource "gitlab_project_variable" "enabled_projects" {
  for_each = !var.operate_at_root_group_level && length(local.projects_to_enable) > 0 ? {
    for pair in setproduct(keys(local.gitlab_agent_kubernetes_context_variables), local.projects_to_enable) :
    "${pair[1]}_${pair[0]}" => {
      project = pair[1]
      key     = pair[0]
      value   = local.gitlab_agent_kubernetes_context_variables[pair[0]]
    }
  } : {}
  # ... resto della configurazione
}
```

### 5. Template o Generazione Dinamica Config

#### Opzione A: Nuovo Template
Creare `files/config-custom.yaml.tftpl` per gestire gruppi/progetti specifici:
```yaml
ci_access:
%{~ if length(groups) > 0 }
  groups:
%{~ for group in groups }
    - id: ${group}
%{~ endfor }
%{~ endif }
%{~ if length(projects) > 0 }
  projects:
%{~ for project in projects }
    - id: ${project}
%{~ endfor }
%{~ endif }
```

#### Opzione B: Generazione Dinamica
Usare `yamlencode()` per generare dinamicamente il contenuto:
```terraform
local.final_configuration_file_content = var.operate_at_root_group_level ? 
  templatefile("${path.module}/files/config.yaml.tftpl", {...}) :
  yamlencode({
    ci_access = {
      groups   = [for g in local.groups_to_enable : { id = g }]
      projects = [for p in local.projects_to_enable : { id = p }]
    }
  })
```

### 6. Modifiche agli Outputs (outputs.tf)

#### Output da Modificare
```terraform
output "gitlab_root_namespace_id" {
  description = "The ID of the root namespace of the Gitlab Agents project. Only available when operate_at_root_group_level is true."
  value       = var.operate_at_root_group_level ? data.gitlab_group.root_namespace.group_id : null
}
```

#### Output da Aggiungere
```terraform
output "gitlab_enabled_groups" {
  description = "List of groups where the GitLab Agent has been enabled with variables."
  value       = local.groups_to_enable
}

output "gitlab_enabled_projects" {
  description = "List of projects where the GitLab Agent has been enabled with variables."
  value       = local.projects_to_enable
}

output "gitlab_parent_group_auto_detected" {
  description = "Whether the parent group was automatically detected."
  value       = local.auto_detect_parent
}
```

---

## Punti Critici e Considerazioni

### 1. Parsing del Parent Path
- **Attenzione**: Il parsing del path deve gestire correttamente:
  - Progetti nel root group: `root-group/project` → parent = `root-group`
  - Progetti in sottogruppi: `root/subgroup1/subgroup2/project` → parent = `root/subgroup1/subgroup2`
- **Validazione**: Verificare che il parent esista prima di procedere

### 2. Parent che È un Root Group
- Se il parent risulta essere un root group, il comportamento dovrebbe essere coerente
- Valutare se forzare `operate_at_root_group_level = true` in questo caso o gestirlo normalmente

### 3. Backward Compatibility
**Opzioni:**
- **Breaking change**: Rimuovere completamente le vecchie variabili (richiede major version bump)
- **Deprecazione**: Mantenere le vecchie variabili con warning, mappandole alle nuove
- **Migrazione automatica**: Creare locals che traducono vecchia configurazione → nuova

**Raccomandazione**: Considerare un major version bump con breaking change per semplificare il codice.

### 4. Generazione Config.yaml
**Preferenza**: Usare `yamlencode()` per maggiore flessibilità e manutenibilità rispetto ai template, a meno che non si voglia mantenere il supporto per `gitlab_agent_append_to_config_file`.

### 5. Validazione Gruppi/Progetti
- Usare data source per validare l'esistenza di gruppi/progetti specificati
- Gestire errori in modo chiaro se path non esistono

### 6. User Access
- Attualmente `gitlab_agent_grant_user_access_to_root_namespace` si applica solo al root namespace
- Valutare se estendere questa funzionalità anche a gruppi/progetti specifici

---

## Ordine di Implementazione Consigliato

1. **Aggiungere nuove variabili** (`operate_at_root_group_level`, `groups_enabled`, `projects_enabled`)
2. **Aggiungere locals** per logica condizionale e parsing parent
3. **Aggiungere data sources** per gruppi/progetti
4. **Modificare generazione config file** con logica condizionale
5. **Sostituire risorse variabili** con nuova logica multi-target
6. **Aggiornare outputs**
7. **Aggiungere validazioni**
8. **Testing completo** di tutti gli scenari
9. **Deprecare vecchie variabili** (se si sceglie quel percorso)
10. **Aggiornare documentazione** (README.md)

---

## Scenari di Test

### Scenario 1: Root Group (comportamento attuale)
```terraform
operate_at_root_group_level = true
# groups_enabled e projects_enabled ignorati
```
**Aspettativa**: File su root namespace, variabili su root group

### Scenario 2: Auto-detect Parent
```terraform
operate_at_root_group_level = false
groups_enabled = []
projects_enabled = []
gitlab_project_path_with_namespace = "root-group/subgroup/project"
```
**Aspettativa**: Parent = "root-group/subgroup", file e variabili su quel gruppo

### Scenario 3: Gruppi Specifici
```terraform
operate_at_root_group_level = false
groups_enabled = ["group1", "group2/subgroup"]
projects_enabled = []
```
**Aspettativa**: File con access a group1 e group2/subgroup, variabili in entrambi

### Scenario 4: Progetti Specifici
```terraform
operate_at_root_group_level = false
groups_enabled = []
projects_enabled = ["org/project1", "org/project2"]
```
**Aspettativa**: File con access a project1 e project2, variabili in entrambi

### Scenario 5: Mix Gruppi e Progetti
```terraform
operate_at_root_group_level = false
groups_enabled = ["group1"]
projects_enabled = ["org/project1"]
```
**Aspettativa**: File con access a group1 e project1, variabili in entrambi

### Scenario 6: Parent È Root Group
```terraform
operate_at_root_group_level = false
groups_enabled = []
projects_enabled = []
gitlab_project_path_with_namespace = "root-group/project"
```
**Aspettativa**: Parent = "root-group" (che è root), comportamento da definire

---

## Note Finali

Questa specifica fornisce una roadmap completa per l'implementazione. Prima di iniziare il coding:

1. Decidere la strategia di backward compatibility
2. Scegliere tra template vs `yamlencode()` per config generation
3. Definire comportamento esatto quando parent è root group
4. Preparare esempi e test cases
5. Pianificare versioning (major bump vs minor/patch)
