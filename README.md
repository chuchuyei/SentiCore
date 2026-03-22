# 🧠 SentiCore — A 27-dimensional emotion engine for AI agents

A dynamic emotion computation engine developed based on the theories of Paul Ekman and Dacher Keltner (2017). This module can be embedded as an independent Skill into any LLM Agent, endowing it with an underlying psychological logic that features **Emotional Interlocking** and **Time Decay** mechanisms.

> 中文版說明請見 [README_zh.md](./README_zh.md)

## ✨ Core Features
- **27+1 Dimensional Matrix**: Accurately measures the emotional spectrum from Joy and Awe to Disgust and Longing, plus an absolute baseline (Calm).
- **Emotional Interlocking**: Synergistic emotional diffusion and antagonistic emotional suppression, simulating the chain reactions of real human psychology.
- **Time Decay Mechanism**: Emotions regress towards the baseline personality over conversational turns (default 3%), preventing the AI from being permanently stuck in extreme emotional states.
- **Smart Dual-Track Onboarding**: AIs with an existing persona (`soul.md`) silently auto-generate their own baseline; blank-slate AIs use an interactive 3-question questionnaire. A JSON fallback is always printed to ensure reproducibility.
- **Plug & Play**: Perfectly compatible with existing character profile files (`soul.md`), allowing for easy mounting or dismounting.

## 📂 File Structure
- `README.md` / `README_zh.md`: Project documentation (EN / ZH).
- `orchestration_prompt_en.md`: The core system orchestration prompt (English), responsible for bridging the emotion engine with your character's soul.
- `orchestration_prompt_zh.md`: The core system orchestration prompt (Traditional Chinese).
- `emotion_skill_en.md`: The emotion computation engine (English version).
- `emotion_skill_zh.md`: The emotion computation engine (Traditional Chinese version).
- `install.sh`: One-command installer for OpenClaw users.
- `remove.sh`: Clean uninstaller for OpenClaw users.
- `tools/update_emotion_state.json`: Function Calling schema for persisting emotion state across conversations.
- `templates/sample_soul.md`: A ready-to-use soul character template to get started immediately.

## 🚀 How to Use

### For OpenClaw Users (Recommended)

```bash
git clone https://github.com/chuchuyei/SentiCore.git
cd SentiCore
bash install.sh                    # auto-detect; interactive menu if multiple agents
bash install.sh --agent coo        # install to a specific agent
bash install.sh --lang en          # English version (default: zh)
bash install.sh --agent coo --lang en
```

The script auto-detects all `~/.openclaw*/workspace` directories:
- **Single agent**: installs immediately, no prompts.
- **Multiple agents**: shows an interactive menu to pick one or all.
- **`--agent NAME`**: skips the menu, installs directly to the specified agent.

It copies `emotion_skill_*.md` into `workspace/skills/` and registers the full orchestration prompt + tool schema in `workspace/TOOLS.md`. Idempotent — safe to run multiple times. `SOUL.md` is never modified.

Restart your agent and SentiCore is live.

### Manual Installation

1. Paste the contents of `orchestration_prompt_en.md` at the very top of your Agent's **System Prompt**.
2. Upload `emotion_skill_en.md` and your own `soul.md` to the knowledge base, or paste them into the lower section of the System Prompt.
3. **First-session initialization** — SentiCore auto-selects the right mode:
   - **If your agent has a `soul.md`** (Mode A): It will silently derive its own baseline from the persona and print a JSON block at the end of the first response. Save that JSON as `emotion_state.json` in your agent's memory directory if the tool call didn't persist it automatically.
   - **If your agent has no persona** (Mode B): It will ask you 3 scenario questions to define its baseline.
   - **Manual override**: Send `"Please initialize my emotion baseline with: {...}"` with a JSON object in your very first message.
4. Every response will begin with a JSON emotion log, followed by the agent's reply.

## ⚙️ Tuning the Decay Speed (Lambda)

The persistence layer uses exponential decay to fade emotions toward baseline over time:

```
E(t) = Baseline + (E_prev - Baseline) × e^(−λ × hours_elapsed)
```

Adjust `DECAY_LAMBDA` in `emotion_skill_*.md` to match your agent's personality:

| λ value | Half-life | Best for |
|---------|-----------|----------|
| `0.05` | ~14 hours | Companion agents, long-term memory, slow emotional recovery |
| `0.10` | ~7 hours | Balanced general use |
| `0.1625` | ~4 hours | Work/task agents, fast emotional reset |
| `0.35` | ~2 hours | Very reactive agents, near-stateless between sessions |

The default is `0.05`. To change it, edit the installed skill file at `~/.openclaw-{agent}/workspace/skills/emotion_skill_*.md` and update the `DECAY_LAMBDA` constant.

## 🔬 Research Backing
The weights and trigger scenarios of this engine are based on the following academic research:
- Ekman, P. (1992). "Are There Basic Emotions?"
- Cowen, A., & Keltner, D. (2017). "Self-report captures 27 distinct categories of emotion." *PNAS*.

---
*Created by [chuchuyei](https://github.com/chuchuyei) — Forks and PRs are welcome to optimize the weighting logic!*

## ⚖️ License & Commercial Use

This project operates under a **Dual Licensing** model:

1. **Open Source (GNU AGPLv3)**: Free for personal developers, students, and open-source projects. Under the [AGPLv3](LICENSE), if you use SentiCore to provide a network service (e.g., SaaS, API, or chatbot backend) to the public, your **entire application source code must be open-sourced** under the same AGPLv3 license.
2. **Commercial License**: If you wish to use SentiCore in a closed-source commercial product, a paid service, or cannot comply with the copyleft requirements of AGPLv3, please contact the author to purchase a commercial license.
