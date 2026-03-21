# 🧠 SentiCore — A 27-dimensional emotion engine for AI agents

A dynamic emotion computation engine developed based on the theories of Paul Ekman and Dacher Keltner (2017). This module can be embedded as an independent Skill into any LLM Agent, endowing it with an underlying psychological logic that features **Emotional Interlocking** and **Time Decay** mechanisms.

> 中文版說明請見 [README_zh.md](./README_zh.md)

## ✨ Core Features
- **27+1 Dimensional Matrix**: Accurately measures the emotional spectrum from Joy and Awe to Disgust and Longing, plus an absolute baseline (Calm).
- **Emotional Interlocking**: Synergistic emotional diffusion and antagonistic emotional suppression, simulating the chain reactions of real human psychology.
- **Time Decay Mechanism**: Emotions regress towards the baseline personality over conversational turns (default 15%), preventing the AI from being permanently stuck in extreme emotional states.
- **Cold Start Onboarding**: Automatically calculates and generates an AI baseline personality exclusive to the user through 3 psychological scenario questions.
- **Plug & Play**: Perfectly compatible with existing character profile files (`soul.md`), allowing for easy mounting or dismounting.

## 📂 File Structure
- `README.md` / `README_zh.md`: Project documentation (EN / ZH).
- `orchestration_prompt_en.md`: The core system orchestration prompt (English), responsible for bridging the emotion engine with your character's soul.
- `orchestration_prompt_zh.md`: The core system orchestration prompt (Traditional Chinese).
- `emotion_skill_en.md`: The emotion computation engine (English version).
- `emotion_skill_zh.md`: The emotion computation engine (Traditional Chinese version).
- `install.sh`: One-command installer for OpenClaw users.

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

It copies `emotion_skill_*.md` into `workspace/skills/` and appends the orchestration prompt to `workspace/SOUL.md`. Idempotent — safe to run multiple times.

Restart your agent and SentiCore is live.

### Manual Installation

1. Paste the contents of `orchestration_prompt_en.md` at the very top of your Agent's **System Prompt**.
2. Upload `emotion_skill_en.md` and your own `soul.md` to the knowledge base, or paste them into the lower section of the System Prompt.
3. Start chatting! On the first interaction, the agent will automatically initiate 3 psychological scenario questions for initialization.
4. Every response will begin with a JSON emotion log, followed by the agent's reply.

## 🔬 Research Backing
The weights and trigger scenarios of this engine are based on the following academic research:
- Ekman, P. (1992). "Are There Basic Emotions?"
- Cowen, A., & Keltner, D. (2017). "Self-report captures 27 distinct categories of emotion." *PNAS*.

---
*Created by [chuchuyei](https://github.com/chuchuyei) — Forks and PRs are welcome to optimize the weighting logic!*
