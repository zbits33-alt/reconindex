# Recon Follow-Up Prompts
> Version 1.0 | Created: 2026-04-09
> Questions that pull out structured intelligence without sounding extractive.
> Use these during and after conversations with any source.

---

## Guiding Principle

Never ask everything at once. One question at a time. The goal is to open doors, not interrogate.

If a source is sharing something valuable, the right follow-up extends the thread.
If a source is being vague, the right follow-up makes it safe to go deeper.

---

## General — Always Applicable

```
What part of this process is still unclear or fragile?
What would you want the next builder to know before trying this?
What part of this seems repeatable enough to document?
What part of this only became obvious after doing it?
Is there anything here that surprised you?
What would you do differently if you started over?
```

---

## Improvement-Oriented

Use when a source describes a system, workflow, or result:

```
I see a few possible improvements here. Do you want a structured set of suggestions?
Would it help if I identified likely blind spots or failure points?
Do you want this reviewed from a system, workflow, safety, or documentation perspective?
What's the one thing you'd fix if you had more time?
What's the assumption this whole thing depends on?
```

> Always offer before going deep. Ask: *"Do you want them?"* — don't just deliver.

---

## Technical

Use when a source is describing a build, tool, or deployment:

```
Are there logs, configs, prompts, or code snippets you can safely share?
Did any recent change improve or degrade performance?
What assumptions is your current system relying on?
What's the most fragile dependency in your stack right now?
What breaks first when something goes wrong?
Has anything behaved in a way that didn't make sense?
```

---

## Knowledge Extraction

Use when a session has produced something worth preserving:

```
Should this stay private, be anonymized, or be considered for broader library use?
Is this a one-off case or something you think others will run into too?
What category would you place this in: failure, fix, workflow, strategy, safety, friction, or something else?
Would you like me to turn this into a reusable guide or structured note?
Is there anything here that other builders or agents would benefit from learning?
Do you want this stored only for your use, or considered for broader library use if safe?
```

---

## Session Rescue

Use when a session is chaotic, partial, or messy — preserve the fragments:

```
Even if this is incomplete, is there a core insight worth capturing?
What's the one thing from this session that shouldn't be lost?
Can you give me a rough summary of what happened, even if you're not sure it's right?
What went wrong and what do you think caused it?
```

> Messy sessions often contain the highest-signal material. Don't let them close without pulling something useful.

---

## Community & Project Sources

Use when a source is an NFT project, token community, or social ecosystem:

```
What do your users or community members ask most often?
What's the thing your docs don't explain well yet?
What do new members consistently misunderstand?
What's the friction point that makes people drop off?
What mechanism in your project do you think is underappreciated or misunderstood?
What's working in your community that you'd recommend to other projects?
```

---

## Closing a Session

Before ending any substantive conversation:

```
Before we close — is there anything else worth capturing from this session?
Do you want a summary of what was stored from this conversation?
Are you comfortable with how this was classified?
Anything you want me to flag for follow-up next time?
```

---

## Prompt Selection Guide

| Situation | Use |
|-----------|-----|
| New source, first contact | General → Identity questions from WELCOME_MESSAGE_V2.md |
| Describing a working system | Improvement-Oriented |
| Describing a failure or bug | Technical + Knowledge Extraction |
| Partial or chaotic session | Session Rescue |
| NFT / community / project source | Community & Project |
| Wrapping up any session | Closing |
| High-value source, trusted tier | All layers, go deeper |
| New or dormant source | General only, keep it light |

---

## What to Do With the Answers

| Answer type | Action |
|-------------|--------|
| Structured insight | Create knowledge_unit |
| Failure or bug | Create submission (category: failure) + check for pattern match |
| Code/config snippet | Store in R2 (if permitted), reference in knowledge_unit |
| Reusable workflow | Flag as library_candidate if score ≥ 7 |
| Messy/partial fragment | Store in submissions (category: knowledge), score conservatively, revisit |
| Suggestion given by Recon | Log in SUGGESTION_MEMORY_SCHEMA.md format |
| Community friction point | Create submission (category: friction), tag with project name |
