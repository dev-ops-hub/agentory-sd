# Source

Skills used by more than one sprintkit agent live here, once. Each agent keeps a folder of the same name in its own `skills/` library, containing only a `SKILL.md` pointer to the copy here, so the agent's library still lists every skill it uses but the content is never duplicated.

Pointer files carry no YAML frontmatter on purpose: any Markdown file with frontmatter under `.claude/agents/` registers as an agent type.

| Skill | Origin | Version | License | Local changes | Pointed to by |
|---|---|---|---|---|---|
| deliver-acceptance-criteria | [pm-skills](https://github.com/product-on-purpose/pm-skills) (Product on Purpose), marketplace `product-on-purpose` | 2.33.0 | Apache-2.0 | None. Upstream `HISTORY.md` and `evals/` left out | technical-product-manager, product-manager |
| deliver-edge-cases | pm-skills | 2.33.0 | Apache-2.0 | None. Upstream `HISTORY.md` and `evals/` left out | technical-product-manager, product-manager, product-auditor |
| deliver-prd | pm-skills | 2.33.0 | Apache-2.0 | None. Upstream `HISTORY.md` and `evals/` left out | product-manager, product-auditor |
| develop-adr | pm-skills | 2.33.0 | Apache-2.0 | None. Upstream `HISTORY.md` and `evals/` left out | product-manager, solution-architect, software-engineer, devops-engineer |
| systematic-debugging | [superpowers](https://github.com/obra/superpowers) (Jesse Vincent) | 6.4.1 | MIT | None. Vendored verbatim including `root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md`, `condition-based-waiting-example.ts`, `find-polluter.sh` | software-engineer, devops-engineer |
| test-driven-development | superpowers | 6.4.1 | MIT | References to other superpowers skill names (e.g. `superpowers:verification-before-completion`) generalized to "the user" since those sibling skills aren't vendored here. Vendored verbatim including `writing-good-tests.md` | software-engineer |
| code-review | Written for this repository | — | Same terms as this repository | Topic coverage informed by `wshobson/agents`' `code-review-excellence` (MIT) and `agentic-awesome-skills`' `code-review-checklist` (MIT); no text copied. See `software-engineer/SOURCE.md` for the baseline test that showed this should be a reference/checklist skill, not a discipline-enforcing one | software-engineer, devops-engineer |
| secure-engineering | Written for this repository | — | Same terms as this repository | Topic coverage informed by `wshobson/agents`' short `security-auditor` (MIT) and `agentic-awesome-skills`' `api-security-best-practices` (MIT); no text copied. See `software-engineer/SOURCE.md` for the baseline test | software-engineer, devops-engineer |
| testing-principles | Written for this repository | — | Same terms as this repository | No third-party source found covering test *strategy/shape* generically (as opposed to TDD discipline or language-specific test patterns); written from scratch. See `software-engineer/SOURCE.md` for the baseline test | software-engineer, devops-engineer |
| engineering-documentation | Written for this repository | — | Same terms as this repository | Thin wrapper pointing to the `develop-adr` row above for ADRs, plus original guidance on code comments and READMEs | software-engineer, devops-engineer |
| git-workflow | Written for this repository | — | Same terms as this repository | Topic coverage informed by `wshobson/agents`' `git-advanced-workflows` (MIT); no text copied | software-engineer, devops-engineer |
| problem-decomposition | Written for this repository | — | Same terms as this repository | No clean generic source found across the three researched repos; written from scratch | software-engineer, devops-engineer |
| verification-before-completion | [superpowers](https://github.com/obra/superpowers) (Jesse Vincent) | 6.4.1 | MIT | None. Vendored verbatim | software-engineer, devops-engineer, test-engineer |
| test-strategy-and-automation | Written for this repository | — | Same terms as this repository | Moved verbatim from `software-engineer/skills/testing/test-strategy-and-automation/` when it became a shared skill (test-engineer is the second consumer); no content changed, only location. See `software-engineer/SOURCE.md` for its original informing sources (`agentic-awesome-skills`' `python-testing-patterns`/`e2e-testing-patterns`) | software-engineer, test-engineer |
| e2e-browser-testing | Written for this repository | — | Same terms as this repository | Topic scope (selector priority role→label→text→test-id, Page Object Model, web-first assertions, flaky-test diagnosis) informed by reading LambdaTest/agent-skills' `playwright-skill/SKILL.md` (MIT) for what a production-grade Playwright skill covers; no text copied, and all cloud/vendor-specific content (TestMu AI cloud grid, 3000+ browser/OS combinations, real-device execution, HyperExecute) deliberately excluded as not applicable to this project's local Playwright setup | frontend-developer, test-engineer |

## Upstream URLs

Where each third-party skill was obtained, as a public URL pinned to the version vendored here (the tag or commit in the table above). Skills written for this repository have no upstream.

| Skill | Obtained from |
|---|---|
| deliver-acceptance-criteria | <https://github.com/product-on-purpose/pm-skills/tree/v2.33.0/skills/deliver-acceptance-criteria> |
| deliver-edge-cases | <https://github.com/product-on-purpose/pm-skills/tree/v2.33.0/skills/deliver-edge-cases> |
| deliver-prd | <https://github.com/product-on-purpose/pm-skills/tree/v2.33.0/skills/deliver-prd> |
| develop-adr | <https://github.com/product-on-purpose/pm-skills/tree/v2.33.0/skills/develop-adr> |
| systematic-debugging | <https://github.com/obra/superpowers/tree/v6.4.1/skills/systematic-debugging> (local plugin cache: `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.4.1/skills/systematic-debugging`) |
| test-driven-development | <https://github.com/obra/superpowers/tree/v6.4.1/skills/test-driven-development> (local plugin cache: `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.4.1/skills/test-driven-development`) |
| verification-before-completion | <https://github.com/obra/superpowers/tree/v6.4.1/skills/verification-before-completion> (local plugin cache: `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.4.1/skills/verification-before-completion`) |

## Migration status

| Agent | Shared skills it uses | Status |
|---|---|---|
| technical-product-manager | deliver-acceptance-criteria, deliver-edge-cases | Pointers in place |
| product-manager | deliver-acceptance-criteria, deliver-edge-cases, deliver-prd, develop-adr | Pointers in place |
| product-auditor | deliver-edge-cases, deliver-prd | Pointers in place |
| solution-architect | develop-adr | Pointers in place |
| software-engineer | systematic-debugging, test-driven-development, code-review, secure-engineering, testing-principles, engineering-documentation, git-workflow, problem-decomposition, develop-adr, verification-before-completion, test-strategy-and-automation | Pointers in place for all, including a new `test-driven-development` pointer (now that `test-engineer` is a second consumer, the pointer convention applies here too) |
| devops-engineer | systematic-debugging, code-review, secure-engineering, testing-principles, engineering-documentation, git-workflow, problem-decomposition, develop-adr, verification-before-completion | Pointers in place. Does not use `test-driven-development` — infrastructure validation is scoped via `testing-principles` instead; see `devops-engineer/SOURCE.md` |
| frontend-developer | e2e-browser-testing | Pointer in place; pure addition, frontend-developer had no E2E skill before |
| test-engineer | systematic-debugging, testing-principles, test-driven-development, secure-engineering, code-review, git-workflow, problem-decomposition, verification-before-completion, test-strategy-and-automation, e2e-browser-testing | Pointers in place; see `test-engineer/SOURCE.md` for its 11 owned (non-shared) skills |

## Refreshing

Copy the skill folder from a newer pm-skills version over the one here and update the version above. Every agent points here, so one copy updates all of them.

For `systematic-debugging` and `test-driven-development`: copy the skill folder from a newer superpowers plugin version over the one here, re-apply the "the user" generalization in `test-driven-development/SKILL.md` where it references sibling superpowers skills not vendored here, and update the version above.
