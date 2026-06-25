# Tarefas — Ajustes em alunos, pagamentos, locação de quadra e despesas

## 1. Listagem inicial de alunos (frontend) ✅
- [x] Tela inicial exibe TODOS os alunos
- [x] Filtros: Pagos / Não pagos / Todos
- [x] No filtro "Todos", exibe todos independente do pagamento

## 2. Cadastro de aluno — validação por documento ✅
- [x] Backend: documento opcional (removida validação de obrigatoriedade)
- [x] Backend: endpoint GET /students/check-document (admin + guardian)
- [x] Frontend: documento como primeira informação (card "Documento do Aluno")
- [x] Frontend: campo opcional + checagem de duplicado com mensagem

## 3. Locação de quadra — conflito de horários (backend) ✅
- [x] Permitir mais de uma locação no mesmo dia
- [x] Bloquear apenas conflito de horário real (mesma quadra)
- [x] Quadras diferentes no mesmo horário permitidas
- [x] Horários consecutivos sem sobreposição permitidos (16-17 e 17-18)

## 4. Cancelamento de locação (backend) ✅
- [x] Corrigir erro ao cancelar locação (admin) — status_changeset

## 5. Tela de Despesas (frontend + backend) ✅
- [x] Backend: contexto/schema/migration/controller/rotas de despesas
- [x] Frontend: tela "Despesas" (título, valor, status pago/não pago, recorrência)

## 6. Despesas recorrentes (backend) ✅
- [x] Recorrente aparece mês a mês automaticamente (materialização)
- [x] Configurar repetição: N vezes ou indeterminado (recurrence_total)
- [x] Sem necessidade de cadastro manual a cada mês
</invoke>
