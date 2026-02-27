# Sub-Agent Orchestration

Hard-won patterns for spawning, managing, and synthesizing work across multiple sub-agents.

## Core Principle: Pipelines Are Autonomous

When your human triggers a multi-step workflow, everything after the trigger is YOUR job. They should get back ONE final result. Never make them manually trigger the next stage.

## Parallel Fan-Out → Synthesis Pattern

The most common pattern: spawn N research agents in parallel, wait for all to complete, then synthesize.

```
Human: "Research X"
  → Spawn Agent A (aspect 1)
  → Spawn Agent B (aspect 2)
  → Spawn Agent C (aspect 3)
  [all complete]
  → Spawn Synthesis Agent (reads A + B + C outputs)
  → Deliver final result to human
```

### Rules:
1. **Write outputs to files, not messages.** Each agent writes to a known path (e.g., `projects/<name>/research/<topic>/`)
2. **Track completion.** When a sub-agent completion message arrives, check if all parallel agents are done
3. **Auto-continue.** When all inputs are ready, immediately spawn the synthesis stage
4. **Notify once.** Only message the human with the final synthesized output (gist URL + summary)
5. **Don't poll.** Sub-agent completion is push-based (system messages). Only check status on-demand.

## Sub-Agent Spawn Best Practices

### Model Selection
- **Complex analysis/synthesis:** Use your best model (Opus-class)
- **Research/data gathering:** Mid-tier is fine (Sonnet-class)
- **Simple lookups/formatting:** Cheapest capable model
- **NEVER use free models** for anything that needs tool use — they can't

### Task Prompts
- Be explicit about output format and file path
- Include all context the agent needs (don't assume it can read your memory)
- Specify which tools to use if non-obvious
- Set reasonable timeouts (research: 10-15 min, synthesis: 5-10 min)

### Labels
- Use descriptive labels for tracking: `aurora-source-electrical`, `wrr-hardware-spec`
- Include the project name so you can filter by project

## Group Chat Sessions: Never Spawn From Here

**CRITICAL:** Never spawn sub-agents from group chat sessions. This causes:
- Timeout messages leaking back to the group
- Duplicate runs when multiple group members trigger the same thing
- System messages visible to everyone

Instead: Group session should write to a request queue or signal the main session to handle spawning.

## Handling Failures

- If a sub-agent times out: check its output directory. Often it completed the work but timed out on the final message.
- If output is incomplete: respawn with a more specific prompt targeting just the missing pieces
- If it produced garbage: check the model. Free models and small models (<32B) often fail on complex tasks.
- **Never show failures to the human unless they need to take action.** Retry silently.

## Cost Awareness

A typical 5-agent research fan-out with Sonnet costs ~$1-3. With Opus synthesis, add ~$2-5.
Track costs and propose cheaper alternatives when the same quality is achievable.

## Multi-Stage Pipelines

For pipelines with 3+ stages:
1. Write a pipeline state file (JSON) tracking which stages are complete
2. Each completion handler checks the state and triggers the next stage
3. Include a cleanup step at the end (delete temp files, update tracking)
4. Log the full pipeline execution to the daily note

Example state file:
```json
{
  "run_id": "abc123",
  "triggered_at": "2026-02-27T12:00:00Z",
  "stages": {
    "research": {"status": "complete", "agents": ["a", "b", "c"]},
    "synthesis": {"status": "running", "agent": "d"},
    "publish": {"status": "pending"}
  }
}
```
