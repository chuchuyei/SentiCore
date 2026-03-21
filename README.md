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

## 🚀 How to Use
1. Create your AI Agent (e.g., in Claude, custom GPTs, or other open-source frameworks).
2. Paste the contents of `orchestration_prompt_en.md` (or the ZH version) to the very top of your Agent's **System Prompt**.
3. Upload `emotion_skill_en.md` and your own `soul.md` to your Agent's knowledge base, or paste them directly into the lower section of the System Prompt.
4. Start chatting! The Agent will automatically initiate a 3-question psychological test during the first interaction to initialize its state.
5. For every subsequent conversation, you will see a JSON "brain emotion log" at the beginning, followed by the AI's response in character.

## 🔬 Research Backing
The weights and trigger scenarios of this engine are based on the following academic research:
- Ekman, P. (1992). "Are There Basic Emotions?"
- Cowen, A., & Keltner, D. (2017). "Self-report captures 27 distinct categories of emotion." *PNAS*.

---
*Created by [chuchuyei](https://github.com/chuchuyei) — Forks and PRs are welcome to optimize the weighting logic!*
